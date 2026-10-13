# Flutter 및 기본 구성 유지
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# ML Kit 관련 (R8 컴파일 실패의 주요 원인 해결)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-keepattributes Signature,Annotation*,EnclosingMethod

# 이미지 피커 및 연락처 서비스
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.github.tamir7.contacts.** { *; }
-keep class flutter.plugins.contactsservice.** { *; }

# SQLite 관련
-keep class org.sqlite.** { *; }

# R8 컴파일 에러가 계속될 경우를 대비한 무시 설정
-ignorewarnings
-dontnote

# --- 추가 보강 섹션 ---

# 1. Excel & Archive 관련 (가장 의심되는 부분)
# excel 패키지는 내부적으로 리플렉션을 사용할 수 있으므로 클래스 구조를 유지해야 합니다.
-keep class com.github.n_marshall.excel.** { *; }
-keep class org.apache.commons.compress.** { *; }
-dontwarn org.apache.commons.compress.**

# 2. SQLite (sqflite) 관련
# DB 헬퍼와 모델 클래스들이 난독화되어 매핑이 깨지는 것을 방지합니다.
-keep class com.tekartik.sqflite.** { *; }
-keep class com.tekartik.sqflite_common_ffi.** { *; }

# 3. Path Provider & File Picker
# 외부 저장소 및 파일 경로 접근 관련 클래스 보호
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# 4. 이미지 크롭 (image_cropper) 관련
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# 5. QR 코드 및 공유 관련
-keep class com.google.zxing.** { *; }
-keep class io.flutter.plugins.share.** { *; }

# 6. 네이티브 인터페이스(JNI) 에러 방지
-keepclasseswithmembernames class * {
    native <methods>;
}