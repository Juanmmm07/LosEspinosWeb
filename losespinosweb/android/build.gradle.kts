allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {

  plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}

}


dependencies {

  // Import the Firebase BoM

  implementation(platform("com.google.firebase:firebase-bom:34.6.0"))


  // TODO: Add the dependencies for Firebase products you want to use

  // When using the BoM, don't specify versions in Firebase dependencies

  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products

  // https://firebase.google.com/docs/android/setup#available-libraries

}

