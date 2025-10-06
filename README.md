# oe-java

A reference project that shows how to call [Open Enclave](https://openenclave.io/) enclaves from a Java application through a JNI bridge. It bundles a sample enclave, host-side glue, and a Gradle-based app so you can experiment end-to-end with ECALL/OCALL flows from the JVM.

## Quickstart

1. Generate JNI headers with Gradle (required before the C++ build):

   ```bash
   ./gradlew compileJava
   ```

2. Configure CMake and build the native artifacts (enclave + JNI host library):

   ```bash
   cmake --preset default
   cmake --build --preset default
   ```

   This produces `build/lib/liboe_jni.{so|dylib|dll}` and signs the sample enclave into `build/artifacts/enclaves/example/example.signed`.
3. Update `app/src/main/java/org/oejava/example/App.java` so the hard-coded path passed to `ExampleEnclave.create()` points at the signed enclave generated above, then run the Java sample:

   ```bash
   ./gradlew run
   ```

   Gradle sets `java.library.path` to `build/lib`, so the JVM picks up `liboe_jni` automatically. Use the `--simulate` flag when building/running the native host if you do not have SGX hardware available.

## Repository layout

- `app/` – Gradle project with the Java example (`App`) and the JNI stub class (`ExampleEnclave`).
- `enclaves/example/` – The sample enclave (EDL file, trusted implementation, signing config).
- `host/` – JNI bridge (`jni_bridge.cpp`), OCALL implementations, and an optional CLI host (`host.cpp`).
- `cmake/OEEnclave.cmake` – Helper function `add_oe_enclave()` that drives `oeedger8r`, enclave compilation, and signing.
- `scripts/` – Convenience scripts, including `check_sgx.sh` (hardware capability probe) and devcontainer helpers.
- `.devcontainer/` – Docker setup for a reproducible development environment with OE, JDK 21, CMake, and tooling pre-installed.

Generated output lives under `build/` (CMake) and `app/build/` (Gradle).

## Prerequisites

- Open Enclave SDK 0.19.x or newer (provides `oeedger8r`, `oehost`, `oesign`, headers, and libraries).
- CMake ≥ 3.20, Clang/LLVM ≥ 11, and `ninja` or Make (the presets use Unix Makefiles by default).
- JDK 21 (managed automatically if you rely on the Gradle toolchain) and Gradle wrapper (`./gradlew`).
- SGX2-capable hardware + drivers for a hardware-backed run, or use OE's simulation mode.
- Optional: Docker if you prefer the supplied devcontainer (`scripts/devcontainer-*.sh`).

Check SGX support quickly with:

```bash
scripts/check_sgx.sh
```

## Building the native side

- `./gradlew compileJava` emits JNI headers under `build/generated/jni/`. Rerun this whenever you change `ExampleEnclave.java`.
- `cmake --preset default` configures the project with `BUILD_JNI_HOST=ON` and `BUILD_HOST_EXE=OFF`.
- `cmake --build --preset default` compiles the enclave, generates all EDL stubs, builds `liboe_jni`, and signs the enclave. Use `cmake --build --preset default --target sign_all` if you only need to re-sign after editing `.conf` files.
- Enable the tiny CLI host for debugging by configuring with the `test` preset or passing `-DBUILD_HOST_EXE=ON`, then run it against the signed enclave:

  ```bash
  cmake --preset test
  cmake --build --preset test --target oe_cli
  ./build/bin/oe_cli --simulate build/artifacts/enclaves/example/example.signed
  ```

  Omit `--simulate` when running on hardware with SGX enabled.

## Running and testing the Java layer

- After wiring the enclave path, `./gradlew run` launches `org.oejava.example.App`, which creates the enclave, performs the `helloworld` ECALL, and tears it down.
- Unit tests (currently a placeholder) run via:

  ```bash
  ./gradlew test
  ```

- If you run outside Gradle, set `java.library.path` (or `LD_LIBRARY_PATH`/`DYLD_LIBRARY_PATH`) so the JVM can load `liboe_jni`, and make sure the signed enclave is accessible to the host process.

## Devcontainer workflow

1. Edit `.devcontainer.env` (create it if needed) and set `SSH_PUBKEY` to the public key you want inside the container.
2. Bring the container up:

   ```bash
   ./scripts/devcontainer-up.sh
   ```

   The image ships with the Open Enclave SDK, JDK 21, CMake, Neovim, and other tooling. Additional helpers in `scripts/` can attach, stop, or tear down the container.

## Tips & next steps

- When adding new enclaves, create a directory under `enclaves/` and call `add_oe_enclave()` in its `CMakeLists.txt`; the helper aggregates all generated untrusted stubs for the host.
- JNI signatures live in `build/generated/jni`. Keep Gradle and CMake builds in sync so regenerated headers are picked up.
- Use OE's simulation mode (`OE_ENCLAVE_FLAG_SIMULATE`) while iterating on machines without SGX, then rebuild with `debug=false` for production.
- Clean builds with `rm -rf build app/build` or invoke `cmake --build --preset default --target clean` and `./gradlew clean`.
