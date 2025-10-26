allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Usa el directorio de build del root y crea subcarpetas por módulo
subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
