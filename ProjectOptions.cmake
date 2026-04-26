include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(Drogon_test_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(Drogon_test_setup_options)
  option(Drogon_test_ENABLE_HARDENING "Enable hardening" ON)
  option(Drogon_test_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    Drogon_test_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    Drogon_test_ENABLE_HARDENING
    OFF)

  Drogon_test_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR Drogon_test_PACKAGING_MAINTAINER_MODE)
    option(Drogon_test_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(Drogon_test_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(Drogon_test_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(Drogon_test_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(Drogon_test_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(Drogon_test_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(Drogon_test_ENABLE_PCH "Enable precompiled headers" OFF)
    option(Drogon_test_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(Drogon_test_ENABLE_IPO "Enable IPO/LTO" ON)
    option(Drogon_test_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(Drogon_test_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(Drogon_test_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(Drogon_test_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(Drogon_test_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(Drogon_test_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(Drogon_test_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(Drogon_test_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(Drogon_test_ENABLE_PCH "Enable precompiled headers" OFF)
    option(Drogon_test_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      Drogon_test_ENABLE_IPO
      Drogon_test_WARNINGS_AS_ERRORS
      Drogon_test_ENABLE_SANITIZER_ADDRESS
      Drogon_test_ENABLE_SANITIZER_LEAK
      Drogon_test_ENABLE_SANITIZER_UNDEFINED
      Drogon_test_ENABLE_SANITIZER_THREAD
      Drogon_test_ENABLE_SANITIZER_MEMORY
      Drogon_test_ENABLE_UNITY_BUILD
      Drogon_test_ENABLE_CLANG_TIDY
      Drogon_test_ENABLE_CPPCHECK
      Drogon_test_ENABLE_COVERAGE
      Drogon_test_ENABLE_PCH
      Drogon_test_ENABLE_CACHE)
  endif()

  Drogon_test_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (Drogon_test_ENABLE_SANITIZER_ADDRESS OR Drogon_test_ENABLE_SANITIZER_THREAD OR Drogon_test_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(Drogon_test_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(Drogon_test_global_options)
  if(Drogon_test_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    Drogon_test_enable_ipo()
  endif()

  Drogon_test_supports_sanitizers()

  if(Drogon_test_ENABLE_HARDENING AND Drogon_test_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR Drogon_test_ENABLE_SANITIZER_UNDEFINED
       OR Drogon_test_ENABLE_SANITIZER_ADDRESS
       OR Drogon_test_ENABLE_SANITIZER_THREAD
       OR Drogon_test_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${Drogon_test_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${Drogon_test_ENABLE_SANITIZER_UNDEFINED}")
    Drogon_test_enable_hardening(Drogon_test_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(Drogon_test_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(Drogon_test_warnings INTERFACE)
  add_library(Drogon_test_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  Drogon_test_set_project_warnings(
    Drogon_test_warnings
    ${Drogon_test_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    Drogon_test_enable_sanitizers(
      Drogon_test_options
      ${Drogon_test_ENABLE_SANITIZER_ADDRESS}
      ${Drogon_test_ENABLE_SANITIZER_LEAK}
      ${Drogon_test_ENABLE_SANITIZER_UNDEFINED}
      ${Drogon_test_ENABLE_SANITIZER_THREAD}
      ${Drogon_test_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(Drogon_test_options PROPERTIES UNITY_BUILD ${Drogon_test_ENABLE_UNITY_BUILD})

  if(Drogon_test_ENABLE_PCH)
    target_precompile_headers(
      Drogon_test_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(Drogon_test_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    Drogon_test_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(Drogon_test_ENABLE_CLANG_TIDY)
    Drogon_test_enable_clang_tidy(Drogon_test_options ${Drogon_test_WARNINGS_AS_ERRORS})
  endif()

  if(Drogon_test_ENABLE_CPPCHECK)
    Drogon_test_enable_cppcheck(${Drogon_test_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(Drogon_test_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    Drogon_test_enable_coverage(Drogon_test_options)
  endif()

  if(Drogon_test_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(Drogon_test_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(Drogon_test_ENABLE_HARDENING AND NOT Drogon_test_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR Drogon_test_ENABLE_SANITIZER_UNDEFINED
       OR Drogon_test_ENABLE_SANITIZER_ADDRESS
       OR Drogon_test_ENABLE_SANITIZER_THREAD
       OR Drogon_test_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    Drogon_test_enable_hardening(Drogon_test_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
