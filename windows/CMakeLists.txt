# ============================================================================
# Hiddify - Windows CMake Configuration (SOTA 2024)
# ============================================================================
# Project-level configuration with modern CMake best practices.
# Last updated: 2025-12-08
# ============================================================================

cmake_minimum_required(VERSION 3.21)

project(hiddify
    VERSION 1.0.0
    DESCRIPTION "Hiddify - Multi-platform proxy client"
    LANGUAGES CXX
)

# ============================================================================
# Modern CMake Policies
# ============================================================================
# Explicitly opt-in to modern CMake behaviors for better compatibility.
cmake_policy(SET CMP0063 NEW)  # Honor visibility for all target types
cmake_policy(SET CMP0074 NEW)  # find_package uses <PackageName>_ROOT variables
cmake_policy(SET CMP0077 NEW)  # option() honors normal variables
cmake_policy(SET CMP0091 NEW)  # MSVC runtime library flags are selected by CMAKE_MSVC_RUNTIME_LIBRARY

if(MSVC)
    add_compile_options(/permissive)
endif()

# ============================================================================
# Application Configuration
# ============================================================================
# The name of the executable created for the application.
set(BINARY_NAME "Hiddify")

# Application metadata
set(APP_ORGANIZATION "Hiddify")
set(APP_VERSION "${PROJECT_VERSION}")
set(APP_DESCRIPTION "${PROJECT_DESCRIPTION}")

# ============================================================================
# Build Configuration
# ============================================================================
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(IS_MULTICONFIG)
    set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release" CACHE STRING "" FORCE)
else()
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Flutter build mode" FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Profile" "Release")
    endif()
endif()

# Profile build mode settings (same as Release with profiling enabled)
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# ============================================================================
# External Tools Configuration
# ============================================================================
set(NUGET_EXE "${CMAKE_CURRENT_SOURCE_DIR}/../tools/nuget.exe" CACHE FILEPATH "Path to nuget.exe" FORCE)
set(NUGET_TOOL "${NUGET_EXE}" CACHE FILEPATH "Path to nuget.exe" FORCE)
set(NUGET_EXECUTABLE "${NUGET_EXE}" CACHE FILEPATH "Path to nuget.exe" FORCE)

# ============================================================================
# Global Compile Definitions
# ============================================================================
# Unicode support for all projects
add_definitions(-DUNICODE -D_UNICODE)

# Windows target version (Windows 10+)
add_definitions(-D_WIN32_WINNT=0x0A00 -DWINVER=0x0A00)

# Reduce Windows header bloat
add_definitions(-DNOMINMAX)

# ============================================================================
# Standard Settings Function
# ============================================================================
# Compilation settings that should be applied to most targets.
# Be cautious about adding new options here, as plugins use this function.
function(APPLY_STANDARD_SETTINGS TARGET)
    # Modern C++ standard
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    set_target_properties(${TARGET} PROPERTIES
        CXX_EXTENSIONS OFF
        CXX_STANDARD_REQUIRED ON
    )
    
    # MSVC-specific options
    if(MSVC)
        target_include_directories(${TARGET} PRIVATE
            "$(VCToolsInstallDir)atlmfc\\include"
        )
        target_compile_options(${TARGET} PRIVATE
            /W4                    # Warning level 4
            /wd"4100"              # Unreferenced formal parameter
            /wd"4127"              # Conditional expression is constant
            /wd"4244"              # Conversion, possible loss of data

            /EHsc                  # Exception handling
            /utf-8                 # Source and execution charset
            /Zc:__cplusplus        # Correct __cplusplus macro
            /Zc:inline             # Remove unreferenced COMDAT
            /Zc:preprocessor       # Use conforming preprocessor
        )
        
        # Release optimizations
        target_compile_options(${TARGET} PRIVATE
            "$<$<CONFIG:Release>:/O2>"     # Full optimization
            "$<$<CONFIG:Release>:/Oi>"     # Enable intrinsic functions
            "$<$<CONFIG:Release>:/Ot>"     # Favor fast code
            "$<$<CONFIG:Release>:/GL>"     # Whole program optimization
            "$<$<CONFIG:Release>:/Gy>"     # Function-level linking
            "$<$<CONFIG:Profile>:/O2>"
            "$<$<CONFIG:Profile>:/Oi>"
        )
        
        # Link-time optimizations for Release
        target_link_options(${TARGET} PRIVATE
            "$<$<CONFIG:Release>:/LTCG>"   # Link-time code generation
            "$<$<CONFIG:Release>:/OPT:REF>" # Remove unreferenced functions
            "$<$<CONFIG:Release>:/OPT:ICF>" # Identical COMDAT folding
        )
        
        # Compile definitions
        target_compile_definitions(${TARGET} PRIVATE
            "_HAS_EXCEPTIONS=0"
            "$<$<CONFIG:Debug>:_DEBUG>"
            "$<$<CONFIG:Release>:NDEBUG>"
            "$<$<CONFIG:Profile>:NDEBUG>"
        )
    endif()
endfunction()

# ============================================================================
# Flutter Integration
# ============================================================================
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# ============================================================================
# Application Build
# ============================================================================
add_subdirectory("runner")

# ============================================================================
# Plugin Integration
# ============================================================================
include(flutter/generated_plugins.cmake)

# ============================================================================
# Installation Configuration
# ============================================================================
# Support files are copied next to the executable for in-place execution.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "Install prefix" FORCE)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

# ============================================================================
# Install Targets
# ============================================================================
# Main executable
install(TARGETS ${BINARY_NAME}
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
    COMPONENT Runtime
)

# Flutter ICU data
install(FILES "${FLUTTER_ICU_DATA_FILE}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime
)

# Flutter library
install(FILES "${FLUTTER_LIBRARY}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime
)

# ============================================================================
# Core Libraries Installation
# ============================================================================
# libcore DLL (Xray core)
set(LIBCORE_DLL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../libcore/bin/libcore.dll")
if(EXISTS "${LIBCORE_DLL_PATH}")
    install(FILES "${LIBCORE_DLL_PATH}"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime
    )
    message(STATUS "Found libcore.dll: ${LIBCORE_DLL_PATH}")
else()
    message(STATUS "libcore.dll not found (will be added during build)")
endif()

# Hiddify CLI
set(HIDDIFY_CLI_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../libcore/bin/HiddifyCli.exe")
if(EXISTS "${HIDDIFY_CLI_PATH}")
    install(PROGRAMS "${HIDDIFY_CLI_PATH}"
        DESTINATION "${CMAKE_INSTALL_PREFIX}"
        COMPONENT Runtime
    )
    message(STATUS "Found HiddifyCli.exe: ${HIDDIFY_CLI_PATH}")
else()
    message(STATUS "HiddifyCli.exe not found (will be added during build)")
endif()

# ============================================================================
# Plugin Libraries
# ============================================================================
if(PLUGIN_BUNDLED_LIBRARIES)
    install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime
    )
endif()

# ============================================================================
# Flutter Assets
# ============================================================================
# Full asset directory replacement on each build
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
    file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
    " COMPONENT Runtime
)

install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime
)

# ============================================================================
# AOT Library (Release/Profile only)
# ============================================================================
install(FILES "${AOT_LIBRARY}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    CONFIGURATIONS Profile Release
    COMPONENT Runtime
)

# ============================================================================
# Build Summary
# ============================================================================
message(STATUS "")
message(STATUS "========================================")
message(STATUS "Hiddify Windows Build Configuration")
message(STATUS "========================================")
message(STATUS "  CMake version:     ${CMAKE_VERSION}")
message(STATUS "  Generator:         ${CMAKE_GENERATOR}")
message(STATUS "  Build type:        ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ Standard:      C++20")
message(STATUS "  Binary name:       ${BINARY_NAME}")
message(STATUS "  Install prefix:    ${CMAKE_INSTALL_PREFIX}")
message(STATUS "========================================")
message(STATUS "")
