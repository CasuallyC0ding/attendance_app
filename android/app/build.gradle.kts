plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.attendance_app"
    compileSdk = 35  // Changed from 33 to 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.attendance_app"
        minSdk = 21  // You can keep this as is
        targetSdk = 34  // Changed from 33 to 34
        versionCode = 1
        versionName = "1.0.0"
    }

    defaultConfig {
        applicationId = "com.example.attendance_app"
        minSdk = 21
        targetSdk = 33
        versionCode = 1  // Use explicit value
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

android {
    ndkVersion = "27.0.12077973"
}
