plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.elearningfrontv2"
    
    // 💡 CORRECTION 1: Monter le compileSdk à 36 (ou la version requise par le package)
    // C'est nécessaire pour camera_android et résout l'avertissement Gradle.
    // Nous utilisons 36, car le message d'erreur précédent le recommandait.
    // Si flutter.compileSdkVersion est déjà 36 ou plus, vous pouvez laisser la ligne d'origine.
    compileSdk = 36 
    
    // 🛑 MODIFICATION APPLIQUÉE ICI 🛑
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.elearningfrontv2"
        
        // 💡 CORRECTION 2: minSdk est forcé à 21. C'est nécessaire pour le package camera
        // et pour la compatibilité avec de nombreux modèles TFLite.
        minSdk = 21 
        
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
}

flutter {
    source = "../.."
}