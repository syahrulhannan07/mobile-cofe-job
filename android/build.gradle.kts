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
    project.evaluationDependsOn(":app")
    
    // 🔥 FIX UTAMA: Suntikkan Namespace secara otomatis ke pusher_client tanpa memicu Redline Compiler
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    // Mencari method getNamespace dan setNamespace secara dinamis lewat refleksi Java
                    val methods = androidExt.javaClass.methods
                    val getNamespace = methods.firstOrNull { it.name == "getNamespace" }
                    val setNamespace = methods.firstOrNull { it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java }
                    
                    val currentNamespace = getNamespace?.invoke(androidExt)
                    // Jika library jadul tidak punya namespace, buatkan otomatis di sini
                    if (currentNamespace == null || currentNamespace.toString().isEmpty()) {
                        val targetNamespace = "com.fix.pusher.${project.name.replace(Regex("[^a-zA-Z0-9]"), ".")}"
                        setNamespace?.invoke(androidExt, targetNamespace)
                    }
                } catch (e: Exception) {
                    // Menghindari build crash jika ada ketidakcocokan versi AGP internal
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}