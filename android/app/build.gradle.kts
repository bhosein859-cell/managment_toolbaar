plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


// Release signing is optional for compile validation, never a debug-key fallback.
// All four values must come from a secure external environment/CI secret store.
val signingNames = listOf("TOOLBOX_ANDROID_KEYSTORE", "TOOLBOX_ANDROID_STORE_PASSWORD", "TOOLBOX_ANDROID_KEY_ALIAS", "TOOLBOX_ANDROID_KEY_PASSWORD")
val signingValues = signingNames.associateWith { System.getenv(it).orEmpty() }
val hasReleaseSigning = signingValues.values.any { it.isNotBlank() }
if (hasReleaseSigning) {
    require(signingValues.values.all { it.isNotBlank() }) {
        "Release signing requires all four TOOLBOX_ANDROID_* environment variables."
    }
    val keystore = file(signingValues.getValue("TOOLBOX_ANDROID_KEYSTORE")).canonicalFile
    require(keystore.isFile) { "External release keystore is not a file." }
    require(!keystore.toPath().startsWith(rootProject.projectDir.parentFile.canonicalFile.toPath())) {
        "Release keystore must be outside the repository."
    }
}

android {
    namespace = "com.managementtoolbox.management_toolbox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Keep the published application ID stable; publisher approval is required before first release.
        applicationId = "com.managementtoolbox.management_toolbox"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("externalRelease") {
                storeFile = file(signingValues.getValue("TOOLBOX_ANDROID_KEYSTORE"))
                storePassword = signingValues.getValue("TOOLBOX_ANDROID_STORE_PASSWORD")
                keyAlias = signingValues.getValue("TOOLBOX_ANDROID_KEY_ALIAS")
                keyPassword = signingValues.getValue("TOOLBOX_ANDROID_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            // Without external secrets this is an UNSIGNED compile-test artifact.
            // Never publish it or describe it as an installable signed release.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("externalRelease") else null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
