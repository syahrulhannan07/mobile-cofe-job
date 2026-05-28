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
            if (androidExtension != null) {
                // 1. Solusi Batasan Namespace
                if (androidExtension.namespace == null) {
                    val cleanName = name.replace(Regex("[^a-zA-Z0-9_]"), "_")
                    androidExtension.namespace = "com.cofejob.$cleanName"
                }

                // 🛠️ PERBAIKAN UTAMA: Paksa compileSdkVersion ke 34 agar mendukung kompilasi Java 17
                androidExtension.compileSdkVersion(34)

                // 2. Solusi JVM Target: Menyelaraskan Android Compile Options ke Java 17
                androidExtension.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }

    // 3. Solusi JVM Target: Menyelaraskan seluruh Java Tasks ke Java 17
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}