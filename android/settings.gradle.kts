pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Repositories must be declared before includeBuild so the Flutter
    // gradle plugin's `kotlin-dsl` 5.2.0 can resolve from the plugin portal.
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://plugins.gradle.org/m2/") }
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
}

include(":app")
// The Wear OS app (2.3.0): a native Compose for Wear OS module, same package
// name, published as the listing's Wear OS form factor. Built with
// `./gradlew :wear:bundleRelease`, not by flutter build.
include(":wear")
