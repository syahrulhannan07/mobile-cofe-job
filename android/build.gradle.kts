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
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            if (project.android.namespace == null) {
                // Menyuntikkan namespace otomatis berdasarkan nama package/plugin secara dinamis
                project.android.namespace = "com.cofejob.${project.name.replaceAll(/[^a-zA-Z0-9_]/, '_')}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
