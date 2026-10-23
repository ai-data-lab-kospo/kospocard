# 📇 KOSPOCARD

### AI-Powered Business Card Management App

**Built with Vibe Coding · Shared by AI-DATA Lab in KOSPO**

생성형 AI를 활용해 개발한 오픈소스 안드로이드 명함관리 애플리케이션

---

## 🌱 프로젝트 소개

**KOSPOCARD**는 업무 중 주고받는 명함을 편리하게 등록·관리하고 활용하기 위해 개발한 안드로이드 애플리케이션입니다.

한국남부발전 직원들의 자율 기술공유 커뮤니티인 **AI-DATA Lab in KOSPO**에서 공유하는 첫 번째 오픈소스 프로젝트로, 생성형 AI를 활용한 **바이브 코딩(Vibe Coding)** 방식으로 개발되었습니다.

누구나 소스코드를 자유롭게 활용하고 개선할 수 있도록 MIT 라이선스로 공개합니다.

> **AI First! KOSPO!**
>
> 현장의 아이디어를 AI와 함께 실제 도구로 구현합니다.

## ✨ 주요 기능

| 기능 | 설명 |
|---|---|
| 📷 명함 등록 | 카메라 촬영 또는 갤러리에서 명함 이미지 불러오기 |
| 🤖 명함 정보 인식 | ML Kit 기반 문자 인식을 활용한 이름, 회사·소속, 직위, 연락처 등 입력 지원 |
| 🔎 명함 검색·관리 | 저장된 명함 조회, 검색, 수정 및 삭제 |
| 🔗 정보 공유 | QR코드 및 텍스트 방식으로 명함 정보 공유 |
| 📱 연락처 연동 | 인식한 명함 정보를 스마트폰 연락처에 등록 |
| 💾 데이터 백업 | 명함 관리 자료 백업 기능 |

※ 문자 인식 결과는 이미지 품질과 명함 형식에 따라 달라질 수 있으므로 저장 전에 확인해 주세요.

## 💡 개발 배경: 바이브 코딩

바이브 코딩은 구현하고 싶은 기능을 자연어로 설명하고, 생성형 AI가 제안한 코드를 검토·수정하면서 소프트웨어를 개발하는 방식입니다.

KOSPOCARD는 일상적인 업무 불편에서 출발하여 필요한 기능을 직접 기획하고, 생성형 AI를 활용해 실제 애플리케이션으로 구현한 사례입니다.

이를 통해 생성형 AI가 문서 작성과 정보 검색을 넘어 **직원이 직접 업무지원 도구를 개발하는 수단**으로 활용될 수 있음을 보여주고자 합니다.

## 🖼️ 앱 화면

앱 화면 이미지와 사용 안내 자료는 공개 범위 검토 후 추가할 예정입니다.

## 🛠️ 개발 환경 및 소스코드

KOSPOCARD는 Flutter 기반으로 개발된 Android 애플리케이션입니다.

| 구분 | 기술 |
|---|---|
| 개발 프레임워크 | Flutter |
| 개발 언어 | Dart, Kotlin |
| 지원 플랫폼 | Android |
| 최소 Android 버전 | Android 8.0 (API 26) |
| 문자 인식 | Google ML Kit Korean Text Recognition |
| 빌드 도구 | Gradle |

### 프로젝트 구성

```text
kospocard/
├── android/          # Android 프로젝트 및 빌드 설정
├── assets/           # 앱 이미지 및 리소스
├── lib/              # Flutter 애플리케이션 소스코드
├── pubspec.yaml      # 패키지 및 의존성 설정
├── pubspec.lock      # 의존성 버전 정보
├── LICENSE           # MIT 라이선스
└── README.md         # 프로젝트 안내
```

### 소스코드 이용

본 저장소의 소스코드는 MIT 라이선스 조건에 따라 누구나 다운로드, 수정, 재배포 및 상업적으로 활용할 수 있습니다.

개발 및 빌드에는 프로젝트와 호환되는 Flutter SDK와 Android 개발 환경이 필요하며, 실제 빌드 전 의존성 및 환경 설정을 확인해 주세요.

## ## 📦 배포 및 이용 안내

KOSPOCARD는 소스코드와 Android 시험용 APK를 GitHub를 통해 공개합니다.

- **소스코드:** MIT 라이선스로 공개
- **Android APK:** [시험용 APK 다운로드 (GitHub Releases)](https://github.com/ai-data-lab-kospo/kospocard/releases)
- **지원 환경:** Android 8.0 이상
- **사내 이용:** 회사의 모바일기기 관리체계(MDM)를 통한 별도 배포

### ⚠️ 시험용 APK 이용 안내

GitHub에서 제공하는 APK는 초기 기능 검증에 사용된 **디버그 빌드(Debug Build)**이며, 정식 배포 버전이 아닙니다.

기능 확인 및 테스트 목적으로 제공되며, 안정성 및 보안 설정이 정식 배포 버전과 다를 수 있습니다.

실제 개인정보 대신 테스트용 명함 데이터를 사용하시기 바랍니다.

본 프로젝트는 오픈소스 기술공유를 목적으로 제공되며, 지속적인 기술지원 및 업데이트를 보장하지 않습니다.

## 📄 라이선스

KOSPOCARD는 **MIT License**에 따라 공개됩니다.

누구나 무료로 사용, 수정, 복제, 재배포 및 상업적으로 활용할 수 있으며, 재배포 시 원 저작권 표시와 라이선스 고지를 유지해야 합니다.

자세한 사항은 [LICENSE](LICENSE) 파일을 참고하시기 바랍니다.

※ 본 라이선스는 공개된 소스코드에 대한 이용 조건이며, 한국남부발전의 기관 명칭, 로고 및 상표에 대한 별도의 사용 권한을 부여하지 않습니다.

## 🤝 AI-DATA Lab in KOSPO

**AI-DATA Lab in KOSPO**는 한국남부발전 직원들이 자율적으로 참여하는 AI·데이터 기술공유 커뮤니티입니다.

생성형 AI를 활용한 업무지원 도구와 개발 경험을 공유하고, 작은 아이디어를 실제 업무개선으로 연결하는 것을 지향합니다.

- GitHub Organization: [ai-data-lab-kospo](https://github.com/ai-data-lab-kospo)
- 첫 번째 오픈소스 프로젝트: **KOSPOCARD**

*본 공간은 직원 자율 기술공유 커뮤니티이며, 한국남부발전의 공식 기술지원 채널을 의미하지 않습니다.*

---

## 🌍 English Overview

**KOSPOCARD** is an open-source Android business card management application developed with Flutter using generative AI and a **vibe coding** approach.

It supports business card capture, Korean text recognition, contact information management, searching, editing, sharing, and data backup.

The source code is available under the **MIT License**, allowing free use, modification, redistribution, and commercial use subject to the license terms.

The project is shared through **AI-DATA Lab in KOSPO**, a voluntary employee-led AI and data knowledge-sharing community.

**Distribution:** Source code and a debug test APK are available through this repository and its [GitHub Releases](https://github.com/ai-data-lab-kospo/kospocard/releases) page. The APK is provided for testing and evaluation purposes only and is not an official production release. Internal deployment is handled separately through the company's MDM system.

---

**From everyday ideas to practical AI-powered tools.** 🚀
