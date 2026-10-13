import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models.dart';

class OCREngine {
  static Future<Map<String, dynamic>> analyze(String path) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    List<TextLineModel> lines = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        lines.add(TextLineModel(line));
      }
    }

    String dName = "";
    String dPosition = ""; 
    String dPhone = "";
    String dEmail = "";
    String dKorCo = "";
    String dAddr = "";
    
    List<String> nameOptions = [];
    List<String> positionOptions = []; 
    List<String> phoneOptions = [];
    List<String> emailOptions = [];
    List<String> korCoOptions = [];
    List<String> addrOptions = [];

    const String posKws = r'(대표|이사|부장|과장|팀장|본부장|실장|주임|대리|사원|감사|차장|회장|사장|연구원|교수|Manager|Director|CEO|VP|President|Accountant|Engineer|Consultant|Specialist|Lead|Designer|Staff|Chief|監사|監事|General Manager)';
    const String coKws = r'(주식회사|공사|에너지|산업|금융|화재|연구소|센터|협회|재단|법인|INC|LTD|CORP|CO\.|GROUP|HOLDINGS|TECH|SYSTEMS|GLOBAL|LAB|UNIVERSITY|BANK|SOLUTIONS|POWER|발전|원자력|연료|SCATTER|KOSPO|한국남부발전)';
    
    RegExp emailReg = RegExp(r'[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-\.]+\.[a-zA-Z]{2,5}', caseSensitive: false);
    RegExp telReg = RegExp(r'(\+?\d{1,3}[- .]?)?(\d{2,4}[- .]?){2,4}\d{4}');
    RegExp mobileReg = RegExp(r'(010|011|016|017|018|019|82[- ]?10)[- .]?\d{3,4}[- .]?\d{4}');
    RegExp addrKeywords = RegExp(r'(서울|부산|대구|인천|광주|대전|울산|세종|경기|강원|충북|충남|전북|전남|경북|경남|제주|Road|Rd|Street|St|Ave|Floor|FL|B/D|Building|#|[가-힣]+(시|도|구|군|로|길|동|읍|면))', caseSensitive: false);

    String emailPrefix = "";

    // 2. 1차 패스: 이메일 및 전화번호 추출
    for (var item in lines) {
      String originalText = item.text.trim();
      String noSpaceText = originalText.replaceAll(' ', '');
      
      if (emailReg.hasMatch(noSpaceText)) {
        // 정규식으로 이메일 부분만 먼저 추출 시도
        String? extracted = emailReg.stringMatch(noSpaceText)?.toLowerCase();
        
        if (extracted != null) {
          // [추가 로직] 만약 추출된 결과 앞에 여전히 'e-mail' 등이 붙어있다면 강제로 제거
          String cleanedEmail = extracted
              .replaceFirst(RegExp(r'^(e-mail|email|e-mai|emai|e:|mail:)', caseSensitive: false), '')
              .replaceFirst(RegExp(r'^[:\-\.]+'), ''); // 붙어있는 기호까지 제거

          if (!emailOptions.contains(cleanedEmail)) emailOptions.add(cleanedEmail);
          
          if (dEmail.isEmpty) {
            dEmail = cleanedEmail;
            emailPrefix = dEmail.split('@')[0].replaceAll(RegExp(r'[^a-z]'), '');
            item.isUsed = true;
            continue; 
          }
        }
      }
      
      if (telReg.hasMatch(noSpaceText) && !item.isUsed) {
        int firstDigitIndex = originalText.indexOf(RegExp(r'\d'));
        String cleanedNumber = originalText;
        if (firstDigitIndex != -1) {
          cleanedNumber = originalText.substring(firstDigitIndex).trim();
        }

        if (!phoneOptions.contains(cleanedNumber)) {
          if (mobileReg.hasMatch(noSpaceText)) {
            phoneOptions.insert(0, cleanedNumber);
          } else {
            phoneOptions.add(cleanedNumber);
          }
        }

        if (mobileReg.hasMatch(noSpaceText)) {
          dPhone = cleanedNumber;
          item.isUsed = true;
        } else if (dPhone.isEmpty) {
          dPhone = cleanedNumber;
          item.isUsed = true;
        }
      }
    }

    // 3. 2차 패스: 스코어링 및 직위 추출
    for (var item in lines) {
      if (item.isUsed) continue;
      
      String t = item.text.trim();
      String pureCandidate = t.replaceAll(RegExp(r'\(.*?\)|（.*?）|\[.*?\]'), '')
                             .replaceAll(RegExp(posKws, caseSensitive: false), '')
                             .replaceAll(RegExp(r'[^\w\sㄱ-ㅎ가-힣]'), '').trim();
      
      bool hasCoKw = RegExp(coKws, caseSensitive: false).hasMatch(t);
      bool hasPosKw = RegExp(posKws, caseSensitive: false).hasMatch(t);

      if (hasPosKw) {
        item.posScore = 200 + item.fontSize;
        if (!positionOptions.contains(t)) positionOptions.add(t);
      }

      if (hasPosKw) item.nameScore += 250;
      
      if (RegExp(r'^[A-Z][a-z]+ [A-Z][a-z]+$').hasMatch(pureCandidate) || 
          RegExp(r'^[A-Z\s]{3,25}$').hasMatch(pureCandidate)) {
        item.nameScore += 180;
      }

      if (emailPrefix.isNotEmpty && emailPrefix.length >= 3) {
        if (pureCandidate.toLowerCase().contains(emailPrefix.substring(0, 3)) ||
            emailPrefix.contains(pureCandidate.toLowerCase().replaceAll(' ', ''))) {
          item.nameScore += 300;
        }
      }

      if (pureCandidate.length >= 2 && pureCandidate.length <= 4 && RegExp(r'^[가-힣]+$').hasMatch(pureCandidate)) {
        item.nameScore += 150;
      }

      item.nameScore += (item.fontSize * 2.5);
      if (hasCoKw) item.nameScore -= 500;

      if (hasCoKw) item.coScore += 600;
      item.coScore += (item.fontSize * 2.0);
      if (hasPosKw || t.contains('@')) item.coScore -= 400;

      if (addrKeywords.hasMatch(t)) item.addrScore += 300;
    }

    // 4. 최종 결과 조립
    lines.sort((a, b) => b.addrScore.compareTo(a.addrScore));
    var addrCand = lines.where((e) => e.addrScore > 100).toList();
    addrOptions = addrCand.map((e) => e.text).toList();
    var unusedAddrCand = lines.where((e) => !e.isUsed && e.addrScore > 100).toList();
    if (unusedAddrCand.isNotEmpty) { 
      dAddr = unusedAddrCand.first.text; 
      unusedAddrCand.first.isUsed = true; 
    }

    lines.sort((a, b) => b.posScore.compareTo(a.posScore));
    if (positionOptions.isNotEmpty) dPosition = positionOptions.first;

    lines.sort((a, b) => b.nameScore.compareTo(a.nameScore));
    var nameCands = lines.where((e) => !e.isUsed && e.nameScore > 50).toList();
    for (var cand in nameCands) {
      String cleaned = cand.text.replaceAll(RegExp(r'\(.*?\)|（.*?）|\[.*?\]'), '')
                               .replaceAll(RegExp(posKws, caseSensitive: false), '')
                               .replaceAll(RegExp(r'[^\w\sㄱ-ㅎ가-힣]'), '').trim();
      if (cleaned.isNotEmpty && !nameOptions.contains(cleaned) && cleaned.length <= 25) {
        nameOptions.add(cleaned);
      }
    }
    if (nameOptions.isNotEmpty) dName = nameOptions.first;

    lines.sort((a, b) => b.coScore.compareTo(a.coScore));
    var coCand = lines.where((e) => e.coScore > 100).toList();
    korCoOptions = coCand.map((e) => e.text.replaceAll(RegExp(r'[|ㅣ]$'), '').trim()).toList();
    var unusedCoCand = lines.where((e) => !e.isUsed && e.coScore > 100).toList();
    if (unusedCoCand.isNotEmpty) {
      dKorCo = unusedCoCand.first.text.replaceAll(RegExp(r'[|ㅣ]$'), '').trim();
    } else {
      var backupCo = lines.where((e) => RegExp(coKws, caseSensitive: false).hasMatch(e.text)).toList();
      if (backupCo.isNotEmpty) dKorCo = backupCo.first.text;
    }

    if (dEmail.isEmpty && emailOptions.isNotEmpty) dEmail = emailOptions.first;
    if (dPhone.isEmpty && phoneOptions.isNotEmpty) dPhone = phoneOptions.first;
    if (dAddr.isEmpty && addrOptions.isNotEmpty) dAddr = addrOptions.first;
    if (dKorCo.isEmpty && korCoOptions.isNotEmpty) dKorCo = korCoOptions.first;

    textRecognizer.close();
    
    return {
      "name": dName,
      "position": dPosition,
      "phone": dPhone,
      "email": dEmail,
      "korCo": dKorCo,
      "addr": dAddr,
      "nameOptions": nameOptions,
      "positionOptions": positionOptions,
      "phoneOptions": phoneOptions,
      "emailOptions": emailOptions,
      "korCoOptions": korCoOptions,
      "addrOptions": addrOptions,
    };
  }
}