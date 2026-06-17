allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 8+: older FlutterFire plugins need BuildConfig + `namespace` on library modules.
gradle.afterProject {
    val sub = this
    if (!sub.plugins.hasPlugin("com.android.library")) return@afterProject
    sub.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
        buildFeatures.buildConfig = true
        if (namespace.orEmpty().isEmpty()) {
            namespace = when (sub.name) {
                "firebase_core" -> "io.flutter.plugins.firebase.core"
                "firebase_auth" -> "io.flutter.plugins.firebase.auth"
                "cloud_firestore" -> "io.flutter.plugins.firebase.firestore"
                else -> return@configure
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
