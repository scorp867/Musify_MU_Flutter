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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroid: (Project) -> Unit = { proj ->
        val androidExt = proj.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val m = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                m.invoke(androidExt, 37)
            } catch (_: Throwable) {
                try {
                    val m = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    m.invoke(androidExt, 37)
                } catch (_: Throwable) {
                    try {
                        val m = androidExt.javaClass.getMethod("setCompileSdk", Integer::class.java)
                        m.invoke(androidExt, 37)
                    } catch (_: Throwable) {}
                }
            }
            try {
                val getCompileOptions = androidExt.javaClass.getMethod("getCompileOptions")
                val compileOptions = getCompileOptions.invoke(androidExt)
                if (compileOptions != null) {
                    val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    setSource.invoke(compileOptions, JavaVersion.VERSION_17)
                    setTarget.invoke(compileOptions, JavaVersion.VERSION_17)
                }
            } catch (_: Throwable) {
                // Ignore if method not present
            }
        }
    }

    if (state.executed) {
        configureAndroid(this)
    } else {
        afterEvaluate {
            configureAndroid(this)
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
