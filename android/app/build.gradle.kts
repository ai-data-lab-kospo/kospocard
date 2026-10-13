plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kospocard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // 수정: JavaVersion 객체 대신 문자열 "17"을 직접 사용합니다.
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.kospocard"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        // 수정: Kotlin DSL에서는 getByName("release")를 사용하거나 release { } 블록 내에서 속성명을 정확히 맞춰야 합니다.
        getByName("release") {
            // 수정: '=' 를 사용하여 명시적으로 할당합니다.
            signingConfig = signingConfigs.getByName("debug") // 별도의 release 키가 없다면 debug로 설정하거나 주석 처리하세요.
            isMinifyEnabled = true
            
            // 수정: 리스트 형식(listOf)으로 전달해야 합니다.
            setProguardFiles(listOf(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            ))
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}