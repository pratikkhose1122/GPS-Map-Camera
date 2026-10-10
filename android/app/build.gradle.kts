import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load local.properties for API key configuration
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { stream ->
        localProperties.load(stream)
    }
}

// Load key.properties for release signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.geomapcam.geotag"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.geomapcam.geotag"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps API Key — read from local.properties (not committed to git)
        // Add GOOGLE_MAPS_API_KEY=your_key_here to android/local.properties
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            localProperties.getProperty("GOOGLE_MAPS_API_KEY", "")

        // Geocoding API Key — separate key for HTTP requests without Android restrictions
        manifestPlaceholders["GOOGLE_GEOCODING_API_KEY"] =
            localProperties.getProperty("GOOGLE_GEOCODING_API_KEY", "")

        // Static Maps API Key — separate key for Maps Static API requests
        manifestPlaceholders["GOOGLE_STATIC_MAPS_API_KEY"] =
            localProperties.getProperty("GOOGLE_STATIC_MAPS_API_KEY", "")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") as String?
            keyPassword = keystoreProperties.getProperty("keyPassword") as String?
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword") as String?
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // If missing, we intentionally leave signingConfig unset for release.
            // This prevents silent fallback to debug signing and produces an unsigned APK.
            // A taskGraph check ensures it fails properly below.
        }
    }
}

gradle.taskGraph.whenReady {
    val isRelease = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (isRelease && !keystorePropertiesFile.exists()) {
        throw GradleException("Release signing configuration is missing. Create a key.properties file in the android/ directory with keyAlias, keyPassword, storeFile, and storePassword.")
    }
}
flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
}
