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

// Safely forces alignment between Kotlin compilation and Java targets under Gradle 9+.
// This configures tasks dynamically as they are registered without breaking configuration lifecycle locks.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            // Evaluates and matches your baseline plugin configurations
            val targetJava = project.tasks.withType<JavaCompile>().findByName("compileReleaseJavaWithJavac")?.targetCompatibility
                ?: project.tasks.withType<JavaCompile>().findByName("compileDebugJavaWithJavac")?.targetCompatibility
                ?: "17"

            val resolvedTarget = when (targetJava) {
                "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            jvmTarget.set(resolvedTarget)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
