
# Enclave: example
add_oe_enclave(
  NAME            example
  EDL             "${CMAKE_CURRENT_SOURCE_DIR}/example.edl"
  CONF            "${CMAKE_CURRENT_SOURCE_DIR}/example.conf"
  TRUSTED_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/example_impl.cpp"
)
