import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "com.ozcorp.versiculo_de_hoy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ozcorp.versiculo_de_hoy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Requerido para Google Mobile Ads
        targetSdk = flutter.targetSdkVersion
        versionCode = 4
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only configure release signing if key.properties exists and has required values
        val hasKeystore = keystorePropertiesFile.exists()
        val keyAliasProp = keystoreProperties["keyAlias"] as? String
        val keyPasswordProp = keystoreProperties["keyPassword"] as? String
        val storeFileProp = keystoreProperties["storeFile"] as? String
        val storePasswordProp = keystoreProperties["storePassword"] as? String

        if (hasKeystore && keyAliasProp != null && keyPasswordProp != null && storeFileProp != null && storePasswordProp != null) {
            create("release") {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp
            }
        } else {
            println("[Gradle] Release signing not configured: missing key.properties or required fields.")
        }
    }

    buildTypes {
        release {
            // Assign release signing only if it was configured
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
