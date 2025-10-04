cmake_minimum_required(VERSION 3.11)

# --- Toolchain / compiler setup ---
if(LVI_MITIGATION MATCHES ControlFlow)
  find_package(OpenEnclave-LVI-Mitigation CONFIG REQUIRED)
else()
  if(UNIX)
    if(NOT DEFINED ENV{CC} AND NOT DEFINED CMAKE_C_COMPILER)
      find_program(CMAKE_C_COMPILER clang-16 clang-15 clang-14
        clang-13 clang-12 clang-11 clang)
    endif()
    if(NOT DEFINED ENV{CXX} AND NOT DEFINED CMAKE_CXX_COMPILER)
      find_program(CMAKE_CXX_COMPILER clang++-16 clang++-15 clang++-14
        clang++-13 clang++-12 clang++-11 clang++)
    endif()
  endif()
endif()

project("OE Multi-Enclave on Java" LANGUAGES C CXX)

# --- Open Enclave ---
find_package(OpenEnclave CONFIG REQUIRED)
if(NOT DEFINED OE_INCLUDEDIR) # fallback if not present in older systems
  set(OE_INCLUDEDIR "${OpenEnclave_INCLUDE_DIRS}")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# Crypto lib same as sample convention (mbedtls/openssl)
set(OE_CRYPTO_LIB mbedtls
    CACHE STRING "Crypto lib for enclaves (mbedtls|openssl)")

# Global bucket for all generated untrusted stubs (*.u.c from all enclaves)
# NOTE: the host will link against these files
set_property(GLOBAL PROPERTY OE_ALL_UNTRUSTED_STUBS "")
set_property(GLOBAL PROPERTY OE_ALL_UNTRUSTED_INC_DIRS "")

# Options
option(OE_DEBUG_SIGN "Sign enclaves with --debug" ON)
option(BUILD_JNI_HOST "Build shared JNI host library" ON)
option(BUILD_HOST_EXE "Build a small CLI host for tests" OFF)

# Artifacts root
set(ARTIFACTS_DIR "${CMAKE_BINARY_DIR}/artifacts")

# Helper functions
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(OEEnclave)  # provides add_oe_enclave()

# --- Enclaves (add as many as you need) ---
add_subdirectory(enclaves/foo)
add_subdirectory(enclaves/bar)

# --- Host (consumes all untrusted stubs from all enclaves) ---
add_subdirectory(host)

# Optional convenience: a single target to sign everything
# (already done within add_oe_enclave)
add_custom_target(sign_all DEPENDS ${OE_ALL_SIGNED_TARGETS})

