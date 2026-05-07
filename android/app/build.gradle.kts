plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "corman.air.pulse.airpulse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "corman.air.pulse.airpulse"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            // El .so de ngrok se provee en jniLibs; excluirlo del JAR evita duplicados
            excludes += listOf("**/libngrok_java.so")
        }
        resources {
            excludes += listOf("native.properties")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.ngrok:ngrok-java:1.1.1")
    runtimeOnly("com.ngrok:ngrok-java-native:1.1.1:linux-android-aarch_64")
}
