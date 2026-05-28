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
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExtension = property("android") as? com.android.build.gradle.BaseExtension
            if (androidExtension != null && androidExtension.namespace == null) {
                // Mengganti karakter selain huruf, angka, dan underscore dengan '_' khas Kotlin
                val cleanName = name.replace(Regex("[^a-zA-Z0-9_]"), "_")
                androidExtension.namespace = "com.cofejob.$cleanName"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
