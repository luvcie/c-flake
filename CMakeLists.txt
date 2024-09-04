###########
# General #
###########

# CMake References: https://github.com/Lectem/cpp-boilerplate/blob/master/CMakeLists.txt

cmake_minimum_required(VERSION 3.4)

# Prevent building the project in root directory
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "Do not build in-source. Please remove CMakeCache.txt and the CMakeFiles/ directory. Then build out-of-source.")
endif()

# Project specification
project(untitled-c-project
  VERSION 0.1.0
  LANGUAGES C CXX
)

# Language usage specification
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 11)

# Generate compile_commands.json, used by various text editors to improve linting
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(APPLE)
  add_compile_options(-mmacosx-version-min=10.15)
endif()

#######################
# Modules and scripts #
#######################

# Standard CMake modules

include(CTest)                          # Must be called before adding tests but after calling project(). This automatically calls enable_testing() and configures ctest targets when using Make/Ninja
include(CMakeDependentOption)           # This is a really useful scripts that creates options that depends on other options. It can even be used with generator expressions !
include(GNUInstallDirs)                 # This will define the default values for installation directories (all platforms even if named GNU)
include(InstallRequiredSystemLibraries) # Tell CMake that the `install` target needs to install required system libraries (eg: Windows SDK)
include(CMakePackageConfigHelpers)      # Helper to create relocatable packages

###########
# Options #
###########

option(ENABLE_INSTALL "Should ${PROJECT_NAME} be added to the install list? Useful if included using add_subdirectory." ON)
option(ENABLE_TESTING "Should unit tests be compiled?" ON)

# Disable tests for web version
if(CMAKE_SYSTEM_NAME STREQUAL Emscripten AND ENABLE_TESTING)
  message("Note: Unit tests are disabled for web builds.")
  set(ENABLE_TESTING FALSE)
endif()

################
# Dependencies #
################

include("${CMAKE_SOURCE_DIR}/deps/CMakeLists.txt")

###########
# Targets #
###########

# Add library: core logic of application

set(LIBRARY_NAME ${PROJECT_NAME}_lib)
file(GLOB_RECURSE LIBRARY_FILES "${CMAKE_SOURCE_DIR}/src/*.h" "${CMAKE_SOURCE_DIR}/src/*.c")
list(REMOVE_ITEM LIBRARY_FILES "${CMAKE_SOURCE_DIR}/src/main.c")
add_library(${LIBRARY_NAME} STATIC ${LIBRARY_FILES} ${GENERATED_SHADERS})
target_include_directories(${LIBRARY_NAME} PUBLIC "${CMAKE_SOURCE_DIR}/src")
target_include_directories(${LIBRARY_NAME} PRIVATE "${CMAKE_BINARY_DIR}/generated")
set_target_properties(${LIBRARY_NAME} PROPERTIES LINKER_LANGUAGE CXX)

# Add executable: thin wrapper of library

set(EXECUTABLE_NAME ${PROJECT_NAME})
add_executable(${EXECUTABLE_NAME} "${CMAKE_SOURCE_DIR}/src/main.c")
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${EXECUTABLE_NAME})
endif()
target_link_libraries(${EXECUTABLE_NAME} PUBLIC ${LIBRARY_NAME})

# Add executable: unit tests

if(ENABLE_TESTING)
  file(GLOB_RECURSE ALL_TESTS "${CMAKE_SOURCE_DIR}/tests/*.cc")
  add_executable(unit_tests ${ALL_TESTS})
  target_link_libraries(unit_tests PRIVATE gtest gtest_main ${LIBRARY_NAME})
  gtest_discover_tests(unit_tests)
endif()

# Custom: Export compile_commands.json to project root

if(EXISTS "${CMAKE_BINARY_DIR}/compile_commands.json")
  add_custom_target(copy_compile_commands ALL ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_BINARY_DIR}/compile_commands.json"
    "${CMAKE_CURRENT_LIST_DIR}"
  )
endif()

#############
# Packaging #
#############

if(ENABLE_INSTALL)

  set(${PROJECT_NAME}_INSTALL_CMAKEDIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
    CACHE STRING "Path to install ${PROJECT_NAME} Config*.cmake files to.")

  # Use version checking helper provided by CMake so that users can
  # safely use a version number in their find_package calls
  write_basic_package_version_file(
    ${PROJECT_NAME}ConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  install(TARGETS ${EXECUTABLE_NAME}
    EXPORT ${PROJECT_NAME}_Targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install(DIRECTORY src
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN *.h)

  # This time, install all the exported targets under the
  # ${PROJECT_NAME}_Targets name.
  install(EXPORT ${PROJECT_NAME}_Targets
    NAMESPACE ${PROJECT_NAME}::
    FILE ${PROJECT_NAME}Targets.cmake
    DESTINATION ${${PROJECT_NAME}_INSTALL_CMAKEDIR})

  # So far we only installed the exported targets, now install the package config files.
  #
  # If you do not list headers in the PUBLIC_HEADER property, you will need to copy them using
  # `install(FILES)` or `install(DIRECTORY)` too.
  #
  # In that case, you can use CMAKE_INSTALL_INCLUDEDIR as the base destination path.
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    DESTINATION ${${PROJECT_NAME}_INSTALL_CMAKEDIR})
endif()
