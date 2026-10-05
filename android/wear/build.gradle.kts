import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Release upload signing, exactly as the phone module: mentalmetal-fastlane
// materialises android/key.properties from Doppler at build time.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) keystoreProperties.load(FileInputStream(keystorePropertiesFile))

// The version name is the app's (pubspec.yaml); the version code lives in
// its own range above the phone's (wear:* tracks), passed by the lane as
// -PwearVersionCode=N.
val pubspecVersionName: String = run {
    val pubspec = rootProject.file("../pubspec.yaml")
    val line = pubspec.readLines().firstOrNull { it.trim().startsWith("version:") }
    line?.substringAfter("version:")?.trim()?.substringBefore("+") ?: "0.0.0"
}
val wearVersionCode: Int = (project.findProperty("wearVersionCode") as String?)?.toInt() ?: 20001

android {
    namespace = "app.mentalmetal.wharfwod.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "app.mentalmetal.wharfwod"
        minSdk = 30
        targetSdk = 35
        versionCode = wearVersionCode
        versionName = pubspecVersionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.04.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.runtime:runtime")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.wear.compose:compose-material:1.6.0")
    implementation("androidx.wear.compose:compose-foundation:1.6.0")
    implementation("androidx.wear.compose:compose-navigation:1.6.0")
    implementation("androidx.wear:wear:1.3.0")
    implementation("androidx.wear:wear-ongoing:1.0.0")
    implementation("androidx.health:health-services-client:1.1.0")
    implementation("androidx.concurrent:concurrent-futures-ktx:1.2.0")

    implementation("androidx.core:core-ktx:1.17.0")
    // registerForActivityResult: lintVital insists on a Fragment >= 1.3.0 on the classpath.
    implementation("androidx.fragment:fragment-ktx:1.8.8")
    implementation("androidx.activity:activity-compose:1.12.4")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.10.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.10.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.11.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}
