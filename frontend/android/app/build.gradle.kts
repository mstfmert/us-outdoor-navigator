import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── key.properties okuma ────────────────────────────────────────────────────
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    // ── Package Identity ────────────────────────────────────────────────────
    namespace = "com.mert.usoutdoor"
    compileSdk = flutter.compileSdkVersion

    // Pluginlerin gerektirdiği en yüksek NDK versiyonu
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications için core library desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.mert.usoutdoor"
        minSdk = 21  // Android 5.0 minimum
        targetSdk = 34  // Android 14 — Play Store zorunluluğu
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Signing Configs ─────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            // Önce CI/CD env değişkenlerine bak, yoksa key.properties kullan
            val kPath  = System.getenv("KEYSTORE_PATH")  ?: keyProperties["storeFile"]?.toString()
            val kPass  = System.getenv("KEYSTORE_PASS")  ?: keyProperties["storePassword"]?.toString()
            val kAlias = System.getenv("KEY_ALIAS")      ?: keyProperties["keyAlias"]?.toString()
            val kKPass = System.getenv("KEY_PASS")       ?: keyProperties["keyPassword"]?.toString()

            if (!kPass.isNullOrEmpty()) {
                storeFile     = file(kPath ?: "usoutdoor-release.jks")
                storePassword = kPass
                this.keyAlias = kAlias ?: "usoutdoor"
                keyPassword   = kKPass ?: kPass
            } else {
                // Güvenlik bilgisi bulunamazsa debug ile devam et
                val debugConfig = signingConfigs.getByName("debug")
                storeFile      = debugConfig.storeFile
                storePassword  = debugConfig.storePassword
                this.keyAlias  = debugConfig.keyAlias
                keyPassword    = debugConfig.keyPassword
            }
        }
    }

    // ── Build Types ─────────────────────────────────────────────────────────
    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix   = "-debug"
        }
        release {
            signingConfig = signingConfigs.getByName("release")

            // R8 / ProGuard — kod küçültme + kaynak temizleme
            isMinifyEnabled    = true
            isShrinkResources  = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Not: Windows'ta NDK symbol stripping bazen sorun çıkarır
            // debugSymbolLevel = "NONE" — Play Store upload'da sorun çıkarırsa ekle
        }
    }

    // ── ABI Split — Her mimari için ayrı APK (Play Store otomatik seçer) ───
    splits {
        abi {
            isEnable      = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = false
        }
    }

    // ── Lint ────────────────────────────────────────────────────────────────
    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

// ── Bağımlılıklar ───────────────────────────────────────────────────────────
dependencies {
    // Core Library Desugaring — flutter_local_notifications için zorunlu
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
