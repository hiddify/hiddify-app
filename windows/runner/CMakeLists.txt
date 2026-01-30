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
cmake_minimum_required(VERSION 3.25)

project(runner LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

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
    "NOMINMAX"
    "STRICT"
    "UNICODE"
    "_UNICODE"
    "_CRT_SECURE_NO_WARNINGS"
)

if(MSVC)
    target_compile_options(${BINARY_NAME} PRIVATE 
        /O2 /Oi /Ot /GT /GL /Gw /Gy
        /guard:cf 
        /permissive-
    )
    target_link_options(${BINARY_NAME} PRIVATE 
        /LTCG /OPT:REF /OPT:ICF /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA
    )
endif()

target_link_libraries(${BINARY_NAME} PRIVATE
    flutter
    flutter_wrapper_app
    dwmapi
    shlwapi
    shell32
    user32
)

target_include_directories(${BINARY_NAME} PRIVATE
    "${CMAKE_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
