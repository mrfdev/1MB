plugins {
    java
}

group = "com.mrfloris"
version = "1.0.0"

repositories {
    mavenCentral()
    maven {
        name = "papermc"
        url = uri("https://repo.papermc.io/repository/maven-public/")
    }
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:1.21.10-R0.1-SNAPSHOT")
    // CMI is only accessed via Bukkit's PluginManager and console commands,
    // so we don't need a compile-time dependency here.
}

// Use whatever JDK your Gradle is running with (e.g., Java 25 on your system).
// If you WANT to force a specific version, uncomment and adjust:
// java {
//     toolchain {
//         languageVersion.set(JavaLanguageVersion.of(25))
//     }
// }

tasks.withType<Jar> {
    archiveBaseName.set("CmiSlowChat")
}
