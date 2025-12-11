cmake_minimum_required(VERSION 3.21)
project(runner LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(${BINARY_NAME} WIN32
    "flutter_window.cpp"
    "main.cpp"
    "utils.cpp"
    "win32_window.cpp"
    "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
    "Runner.rc"
    "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE
    "FLUTTER_VERSION=\"${FLUTTER_VERSION}\""
    "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}"
    "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}"
    "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}"
    "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}"
)

target_compile_definitions(${BINARY_NAME} PRIVATE
    "NOMINMAX"
    "STRICT"
)

target_link_libraries(${BINARY_NAME} PRIVATE
    flutter
    flutter_wrapper_app
)

target_link_libraries(${BINARY_NAME} PRIVATE
    dwmapi.lib
    uxtheme.lib
    comctl32.lib
)

target_include_directories(${BINARY_NAME} PRIVATE
    "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)

set(LIBCORE_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/libcore.dll")
set(LIBCORE_ALT_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/../libcore/bin/libcore.dll")

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "Checking for libcore.dll..."
    COMMAND ${CMAKE_COMMAND}
        "-DSOURCE1=${LIBCORE_SOURCE}"
        "-DSOURCE2=${LIBCORE_ALT_SOURCE}"
        "-DDEST=$<TARGET_FILE_DIR:${BINARY_NAME}>"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/copy_libcore.cmake"
    VERBATIM
)

file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/copy_libcore.cmake" [[
if(EXISTS "${SOURCE1}")
    file(COPY "${SOURCE1}" DESTINATION "${DEST}")
    message(STATUS "Copied libcore.dll from runner directory")
elseif(EXISTS "${SOURCE2}")
    file(COPY "${SOURCE2}" DESTINATION "${DEST}")
    message(STATUS "Copied libcore.dll from libcore/bin directory")
else()
    message(STATUS "libcore.dll not found - will be copied during deployment")
endif()
]])
