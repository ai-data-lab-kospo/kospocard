import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum LanguageType { korean, english, mixed }

class BusinessCard {
  final int? id;
  final String imagePath;
  final String name;
  final String position; // 직위 추가
  final String phone;
  final String email;
  final String korCo;
  final String engCo;
  final String addr;
  
  // 모든 필드에 대한 후보군 리스트 (UI 드롭다운용)
  final List<String> nameOptions;
  final List<String> positionOptions; // 직위 후보군 추가
  final List<String> phoneOptions;
  final List<String> emailOptions;
  final List<String> korCoOptions;
  final List<String> addrOptions;

  BusinessCard({
    this.id,
    required this.imagePath,
    required this.name,
    this.position = "",
    required this.phone,
    required this.email,
    required this.korCo,
    required this.engCo,
    required this.addr,
    this.nameOptions = const [],
    this.positionOptions = const [],
    this.phoneOptions = const [],
    this.emailOptions = const [],
    this.korCoOptions = const [],
    this.addrOptions = const [],
  });

  // DB 저장 시 호출: 'id'가 반드시 포함되어야 중복 생성을 막고 수정이 됩니다.
  Map<String, dynamic> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'name': name,
    'position': position,
    'phone': phone,
    'email': email,
    'korCo': korCo,
    'engCo': engCo,
    'addr': addr,
  };

  // DB 로드 시 호출
  factory BusinessCard.fromMap(Map<String, dynamic> map) => BusinessCard(
    id: map['id'],
    imagePath: map['imagePath'] ?? "",
    name: map['name'] ?? "",
    position: map['position'] ?? "",
    phone: map['phone'] ?? "",
    email: map['email'] ?? "",
    korCo: map['korCo'] ?? "",
    engCo: map['engCo'] ?? "",
    addr: map['addr'] ?? "",
  );
}

class TextLineModel {
  final String text;
  final double fontSize;
  final double yPos;
  
  bool isUsed = false;
  double nameScore = 0;
  double coScore = 0;
  double posScore = 0; // 직위 점수 추가
  double addrScore = 0;
  late LanguageType lang;

  TextLineModel(TextLine line)
      : text = line.text,
        fontSize = line.boundingBox.height,
        yPos = line.boundingBox.top {
    // 기존의 언어 판별 로직 유지
    if (RegExp(r'[가-힣]').hasMatch(text) && RegExp(r'[a-zA-Z]').hasMatch(text)) {
      lang = LanguageType.mixed;
    } else if (RegExp(r'[가-힣]').hasMatch(text)) {
      lang = LanguageType.korean;
    } else {
      lang = LanguageType.english;
    }
  }
}