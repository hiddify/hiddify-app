cmake_minimum_required(VERSION 3.14)

project(hiddify LANGUAGES CXX)

set(BINARY_NAME "Hiddify")

cmake_policy(VERSION 3.14...3.25)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
    set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release" CACHE STRING "" FORCE)
else()
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Flutter build mode" FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Profile" "Release")
    endif()
endif()

set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

add_compile_definitions(UNICODE _UNICODE)

function(APPLY_STANDARD_SETTINGS TARGET)
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    if(MSVC)
        target_compile_options(${TARGET} PRIVATE /W4 /wd4100)
        target_compile_options(${TARGET} PRIVATE /EHsc)
        target_compile_definitions(${TARGET} PRIVATE _HAS_EXCEPTIONS=0)
        target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
    endif()
endfunction()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})
add_subdirectory("runner")

include(flutter/generated_plugins.cmake)

set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "Install prefix" FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME}
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
    COMPONENT Runtime
)

install(FILES "${FLUTTER_ICU_DATA_FILE}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime
)

install(FILES "${FLUTTER_LIBRARY}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime
)

if(PLUGIN_BUNDLED_LIBRARIES)
    install(FILES ${PLUGIN_BUNDLED_LIBRARIES}
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime
    )
endif()

set(LIBCORE_DLL_CANDIDATES
    "${CMAKE_CURRENT_SOURCE_DIR}/runner/libcore.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../libcore/bin/libcore.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../libcore/libcore.dll"
)

set(LIBCORE_DLL_PATH "")
foreach(p IN LISTS LIBCORE_DLL_CANDIDATES)
    if(EXISTS "${p}")
        set(LIBCORE_DLL_PATH "${p}")
        break()
    endif()
endforeach()

if(LIBCORE_DLL_PATH)
    install(FILES "${LIBCORE_DLL_PATH}"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime
    )
else()
    message(WARNING "libcore.dll not found; app may not function correctly.")
endif()

set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}/native_assets/windows")
if(EXISTS "${NATIVE_ASSETS_DIR}")
    install(DIRECTORY "${NATIVE_ASSETS_DIR}/"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime
    )
endif()

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")"
    COMPONENT Runtime
)

install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    COMPONENT Runtime
)

install(FILES "${AOT_LIBRARY}"
    DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
    CONFIGURATIONS Profile;Release
    COMPONENT Runtime
)
