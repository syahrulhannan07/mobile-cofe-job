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
    
    // 🔥 FIX REDLINE KOTLIN DSL MENGGUNAKAN PENDEKATAN REFLEKSI
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    // Mengambil method getNamespace() dan setNamespace() secara dinamis
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    
                    val currentNamespace = getNamespace.invoke(androidExt)
                    // Jika library lama belum memiliki namespace, kita suntikkan secara otomatis
                    if (currentNamespace == null || currentNamespace.toString().isEmpty()) {
                        var targetNamespace = project.group.toString()
                        
                        // Fallback aman jika nama group bawaan plugin kosong/unspecified
                        if (targetNamespace.isEmpty() || targetNamespace == "unspecified") {
                            targetNamespace = "com.example.${project.name.replace(Regex("[^a-zA-Z0-9]"), ".")}"
                        }
                        
                        setNamespace.invoke(androidExt, targetNamespace)
                        logger.quiet("🚀 [Namespace Fix] Berhasil menyuntikkan namespace '$targetNamespace' ke library: ${project.name}")
                    }
                } catch (e: Exception) {
                    // Mencegah build crash jika ada ketidakcocokan versi Android Gradle Plugin (AGP)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}