import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Equivalente a: rootProject.buildDir = "../build"
layout.buildDirectory.set(file("../build"))

// Usa el directorio de build del root y crea subcarpetas por módulo
subprojects {
    layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(name)
    )
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
