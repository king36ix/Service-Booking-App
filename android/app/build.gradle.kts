plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase plugin
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.keynetik.waaqti"
    compileSdk = 35 // ✅ Set explicit compileSdk version

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.keynetik.waaqti" // ✅ Assign directly (No `.set()`)
        minSdk = 23  // ✅ Assign directly (No `.set()`)
        targetSdk = 34 // ✅ Assign directly (No `.set()`)
        versionCode = 1 // ✅ Assign directly (No `.set()`)
        versionName = "1.0" // ✅ Assign directly (No `.set()`)
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

dependencies {
    implementation("androidx.multidex:multidex:2.0.1") // Prevent method limit issues
    implementation(platform("com.google.firebase:firebase-bom:32.7.2")) // Firebase BOM
    implementation("com.google.firebase:firebase-auth-ktx:22.3.1") // Firebase Auth
}
