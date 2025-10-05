cmake_minimum_required(VERSION 3.20)
project(oe_host LANGUAGES C CXX)

find_package(OpenEnclave CONFIG REQUIRED)

# Consume all untrusted stubs and their generators exported by enclaves
get_property(ALL_U_STUBS     GLOBAL PROPERTY OE_ALL_UNTRUSTED_STUBS)
get_property(ALL_U_INC_DIRS  GLOBAL PROPERTY OE_ALL_UNTRUSTED_INC_DIRS)
get_property(ALL_U_GEN_TGTS  GLOBAL PROPERTY OE_ALL_U_GEN_TARGETS)

# Mark generated sources so configure doesn’t fail if files
# aren’t present yet
if(ALL_U_STUBS)
  set_source_files_properties(${ALL_U_STUBS} PROPERTIES GENERATED TRUE)
endif()

# ---- JNI shared library (host/JNI bridge)
if(BUILD_JNI_HOST)
  # detect JNI from java JDK
  find_package(JNI REQUIRED)

  # create shared library + link against host libs
  add_library(oe_jni SHARED
    ${ALL_U_STUBS}
    ${CMAKE_SOURCE_DIR}/host/jni_bridge.cpp
    ${CMAKE_SOURCE_DIR}/host/ocalls_host.cpp
  )

  # Ensure untrusted stubs are generated before we compile oe_jni (Fix A)
  if(ALL_U_GEN_TGTS)
    add_dependencies(oe_jni ${ALL_U_GEN_TGTS})
  endif()

  # Add JNI and your generated stub dirs
  target_include_directories(oe_jni PRIVATE
    ${JNI_INCLUDE_DIRS}
    ${ALL_U_INC_DIRS}
  )

  # Link OE host; JNI libs are usually headers-only on Linux,
  # but harmless to link if provided
  target_link_libraries(oe_jni PRIVATE
    openenclave::oehost
    ${JNI_LIBRARIES}
  )

  target_compile_features(oe_jni PRIVATE c_std_11 cxx_std_17)
  # Drop the shared lib in build/lib for easy pickup
  set_target_properties(oe_jni PROPERTIES
    OUTPUT_NAME "oe_jni"
    # macOS .dylib, Windows .dll
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
  )
endif()

# ---- Optional small CLI for testing
if(BUILD_HOST_EXE)
  add_executable(oe_cli
    ${ALL_U_STUBS}
    ${CMAKE_SOURCE_DIR}/host/host.cpp # test logic (start enclave + make OCALLs)
    ${CMAKE_SOURCE_DIR}/host/ocalls_host.cpp # link host OCALL implementations
  )
  if(ALL_U_GEN_TGTS)
    add_dependencies(oe_cli ${ALL_U_GEN_TGTS})
  endif()
  target_include_directories(oe_cli PRIVATE ${ALL_U_INC_DIRS})
  target_link_libraries(oe_cli PRIVATE openenclave::oehost)
  target_compile_features(oe_cli PRIVATE c_std_11 cxx_std_17)

  # Place executable in a predictable folder
  set_target_properties(oe_cli PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
  )

  # `run` target to run the test host
  add_custom_target(run
    COMMAND "${CMAKE_BINARY_DIR}/bin/oe_cli"
    DEPENDS oe_cli
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Running test host: oe_cli"
  )
endif()
