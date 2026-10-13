import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';
import 'models.dart';

class BackupService {
  /// 1. 전체 백업 (데이터 + 이미지 -> ZIP)
  static Future<String> saveToExcel() async {
    try {
      final dbHelper = DatabaseHelper();
      final cards = await dbHelper.getCards();
      
      // 엑셀 생성
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['MyCards'];
      excel.delete('Sheet1');

      sheetObject.appendRow([
        TextCellValue('이름'), TextCellValue('직위'), TextCellValue('회사명'),
        TextCellValue('연락처'), TextCellValue('이메일'), TextCellValue('주소'),
        TextCellValue('이미지파일명')
      ]);

      final archive = Archive();
      
      for (var card in cards) {
        String fileName = "";
        if (card.imagePath.isNotEmpty) {
          final imgFile = File(card.imagePath);
          if (await imgFile.exists()) {
            fileName = p.basename(card.imagePath);
            // 이미지 파일을 Archive 객체에 추가
            final bytes = await imgFile.readAsBytes();
            archive.addFile(ArchiveFile('images/$fileName', bytes.length, bytes));
          }
        }

        sheetObject.appendRow([
          TextCellValue(card.name), TextCellValue(card.position), TextCellValue(card.korCo),
          TextCellValue(card.phone), TextCellValue(card.email), TextCellValue(card.addr),
          TextCellValue(fileName)
        ]);
      }

      // 엑셀 파일을 Archive에 추가
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        archive.addFile(ArchiveFile('data.xlsx', excelBytes.length, excelBytes));
      }

      // ZIP 압축
      final zipBytes = ZipEncoder().encode(archive);
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory("Download");
      final zipPath = p.join(downloadPath, "kcard_backup_${DateTime.now().millisecondsSinceEpoch}.zip");
      
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes!);

      return zipPath;
    } catch (e) {
      throw Exception("백업 생성 실패: $e");
    }
  }

  /// 2. 전체 복구 (ZIP -> 이미지 추출 & 앱 저장소 복사 -> DB 등록)
  static Future<Map<String, int>> restoreFromExcel() async {
    int addedCount = 0;
    int skippedCount = 0;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return {"added": 0, "skipped": 0};
      }

      final bytes = File(result.files.single.path!).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final dbHelper = DatabaseHelper();
      final appDocDir = await getApplicationDocumentsDirectory();
      final existingCards = await dbHelper.getCards();

      // 1. 먼저 엑셀 데이터 파일 찾기
      final excelFile = archive.findFile('data.xlsx');
      if (excelFile == null) throw Exception("백업 파일 내에 데이터가 없습니다.");

      final excel = Excel.decodeBytes(excelFile.content as List<int>);
      final sheet = excel.tables['MyCards'];
      if (sheet == null) throw Exception("시트를 찾을 수 없습니다.");

      // 2. 행 반복 처리
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final name = row[0]?.value?.toString() ?? "";
        final pos = row[1]?.value?.toString() ?? "";
        final co = row[2]?.value?.toString() ?? "";
        final phone = row[3]?.value?.toString() ?? "";
        final email = row[4]?.value?.toString() ?? "";
        final addr = row[5]?.value?.toString() ?? "";
        final imgFileName = row[6]?.value?.toString() ?? "";

        if (name.isEmpty) continue;

        // 중복 체크
        bool isDuplicate = existingCards.any((card) => 
          card.name.trim() == name.trim() && card.korCo.trim() == co.trim()
        );

        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        // 3. 이미지 파일 추출 및 저장
        String newImagePath = "";
        if (imgFileName.isNotEmpty) {
          final imgFileInZip = archive.findFile('images/$imgFileName');
          if (imgFileInZip != null) {
            final targetFile = File(p.join(appDocDir.path, imgFileName));
            await targetFile.writeAsBytes(imgFileInZip.content as List<int>);
            newImagePath = targetFile.path;
          }
        }

        // 4. DB 저장
        await dbHelper.insertCard(BusinessCard(
          name: name,
          position: pos,
          korCo: co,
          phone: phone,
          email: email,
          addr: addr,
          imagePath: newImagePath,
          engCo: "",
        ));
        addedCount++;
      }

      return {"added": addedCount, "skipped": skippedCount};
    } catch (e) {
      throw Exception("복구 실패: $e");
    }
  }
}