cmake_minimum_required(VERSION 3.22.1)
project(musify_audio LANGUAGES C CXX)

find_package(oboe REQUIRED CONFIG)
find_library(LOG_LIB log)
find_library(MEDIANDK_LIB mediandk)

set(DART_SDK_INCLUDE "$ENV{HOME}/development/flutter/bin/cache/dart-sdk/include")

add_library(musify_audio SHARED
    DataSource.cpp
    NativeDecoder.cpp
    AudioEngine.cpp
    ContextProcessor.cpp
    player/ContextPlayerImpl.cpp
    ffi_bridge.cpp
    ${DART_SDK_INCLUDE}/dart_api_dl.c
)

target_include_directories(musify_audio PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${DART_SDK_INCLUDE}
)

set_target_properties(musify_audio PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)

target_link_libraries(musify_audio PRIVATE
    oboe::oboe
    ${LOG_LIB}
    ${MEDIANDK_LIB}
)
