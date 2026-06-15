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
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val target = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions?.targetCompatibility?.toString()
        if (target != null) {
            when (target) {
                "1.8" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
                "11" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                "17" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                "21" -> compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
            }
        }
    }
    configurations.all {
        exclude(group = "org.tensorflow", module = "tensorflow-lite-gpu")
        exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
        resolutionStrategy {
            force("org.tensorflow:tensorflow-lite:2.14.0")
        }
    }
}
