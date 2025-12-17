cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

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
    dwmapi
)

target_include_directories(${BINARY_NAME} PRIVATE
    "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
