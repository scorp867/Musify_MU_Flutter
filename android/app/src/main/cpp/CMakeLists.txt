cmake_minimum_required(VERSION 3.22.1)
project(musify_audio LANGUAGES CXX)

find_package(oboe REQUIRED CONFIG)
find_library(LOG_LIB log)
find_library(MEDIANDK_LIB mediandk)

add_library(musify_audio SHARED
    DataSource.cpp
    NativeDecoder.cpp
    AudioEngine.cpp
    ffi_bridge.cpp
)

target_include_directories(musify_audio PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

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
