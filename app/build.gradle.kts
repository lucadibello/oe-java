import org.gradle.api.tasks.compile.JavaCompile

plugins {
    // Apply the application plugin to add support for building a CLI application in Java.
    application
    java
}

application {
    // Define the main class for the application.
    mainClass = "org.oejava.example.App"
}

// Apply a specific Java toolchain to ease working on different environments.
java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

val jniHeaderOutput = rootProject.layout.buildDirectory.dir("generated/jni")

tasks.named<JavaCompile>("compileJava") {
    options.headerOutputDirectory.set(jniHeaderOutput)
    outputs.dir(jniHeaderOutput)
}

tasks.named("build") {
    dependsOn(tasks.named("compileJava"))
}

tasks.run {
    // Tell the JVM where to find liboe_jni.so
    jvmArgs("-Djava.library.path=${project.rootDir}/build/lib")
}

tasks.named<Test>("test") {
    // Use JUnit Platform for unit tests.
    useJUnitPlatform()
}

repositories {
    mavenCentral() // use maven central to resolve deps
}

dependencies {
    testImplementation(libs.junit.jupiter) // junit juniper as test framework
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
