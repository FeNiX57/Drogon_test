macro(Drogon_test_configure_linker project_name)
  set(Drogon_test_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(Drogon_test_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE Drogon_test_USER_LINKER_OPTION PROPERTY STRINGS ${Drogon_test_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    Drogon_test_USER_LINKER_OPTION_VALUES
    ${Drogon_test_USER_LINKER_OPTION}
    Drogon_test_USER_LINKER_OPTION_INDEX)

  if(${Drogon_test_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${Drogon_test_USER_LINKER_OPTION}', explicitly supported entries are ${Drogon_test_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${Drogon_test_USER_LINKER_OPTION}")
endmacro()
