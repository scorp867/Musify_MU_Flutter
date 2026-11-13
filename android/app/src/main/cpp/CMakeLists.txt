cmake_minimum_required(VERSION 3.22.1)
project(musify_audio LANGUAGES C CXX)

include(FetchContent)

find_package(oboe REQUIRED CONFIG)
find_package(ZLIB REQUIRED)
find_library(LOG_LIB log)
find_library(MEDIANDK_LIB mediandk)

# -----------------------------------------------------------------------------
# Third-party TLS + HTTP stack (mbedTLS 3.6.2 + libcurl 8.11.1, static build)
# -----------------------------------------------------------------------------
set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(MBEDTLS_FATAL_WARNINGS OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    mbedtls
    URL https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.2/mbedtls-3.6.2.tar.bz2
)
FetchContent_MakeAvailable(mbedtls)

set(MBEDTLS_INCLUDE_DIR "${mbedtls_SOURCE_DIR}/include" CACHE PATH "" FORCE)
set(MBEDTLS_INCLUDE_DIRS "${mbedtls_SOURCE_DIR}/include" CACHE PATH "" FORCE)
set(MBEDTLS_LIBRARY mbedtls CACHE STRING "" FORCE)
set(MBEDX509_LIBRARY mbedx509 CACHE STRING "" FORCE)
set(MBEDCRYPTO_LIBRARY mbedcrypto CACHE STRING "" FORCE)
set(MBEDTLS_LIBRARIES "mbedtls;mbedx509;mbedcrypto" CACHE STRING "" FORCE)
set(HAVE_MBEDTLS_DES_CRYPT_ECB 1 CACHE INTERNAL "")

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_CURL_EXE OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_LIBCURL_DOCS OFF CACHE BOOL "" FORCE)
set(BUILD_MISC_DOCS OFF CACHE BOOL "" FORCE)
set(ENABLE_CURL_MANUAL OFF CACHE BOOL "" FORCE)
set(HTTP_ONLY ON CACHE BOOL "" FORCE)
set(CURL_USE_MBEDTLS ON CACHE BOOL "" FORCE)
set(CURL_USE_OPENSSL OFF CACHE BOOL "" FORCE)
set(CURL_USE_SCHANNEL OFF CACHE BOOL "" FORCE)
set(CURL_USE_SECTRANSP OFF CACHE BOOL "" FORCE)
set(CURL_ZLIB ON CACHE BOOL "" FORCE)
set(CURL_USE_LIBPSL OFF CACHE BOOL "" FORCE)
set(USE_LIBIDN2 OFF CACHE BOOL "" FORCE)
set(USE_NGHTTP2 OFF CACHE BOOL "" FORCE)
set(CURL_BROTLI OFF CACHE BOOL "" FORCE)
set(CURL_ZSTD OFF CACHE BOOL "" FORCE)
set(CURL_DISABLE_INSTALL ON CACHE BOOL "" FORCE)
set(CURL_ENABLE_EXPORT_TARGET OFF CACHE BOOL "" FORCE)
set(ENABLE_UNIX_SOCKETS OFF CACHE BOOL "" FORCE)
# Disable eventfd in libcurl 8.11.1 to avoid the upstream asyn-thread.c double-close
# fdsan abort (Curl_eventfd assigns the same fd to sock_pair[0] and sock_pair[1] while
# asyn-thread.c closes both ends independently; Curl_pipe uses two distinct fds).
set(HAVE_EVENTFD 0 CACHE INTERNAL "" FORCE)
set(HAVE_SYS_EVENTFD_H 0 CACHE INTERNAL "" FORCE)

FetchContent_Declare(
    curl
    URL https://curl.se/download/curl-8.11.1.tar.xz
)
FetchContent_MakeAvailable(curl)

foreach(_third_party_target IN ITEMS mbedtls mbedx509 mbedcrypto libcurl libcurl_object libcurl_static curlu)
    if(TARGET ${_third_party_target})
        get_target_property(_aliased_target ${_third_party_target} ALIASED_TARGET)
        get_target_property(_target_type ${_third_party_target} TYPE)
        if(NOT _aliased_target AND NOT "${_target_type}" STREQUAL "INTERFACE_LIBRARY")
            target_compile_options(${_third_party_target} PRIVATE -Wno-error)
        endif()
    endif()
endforeach()

set(DART_SDK_INCLUDE "$ENV{HOME}/development/flutter/bin/cache/dart-sdk/include")

add_library(musify_audio SHARED
    DataSource.cpp
    NativeDecoder.cpp
    AudioEngine.cpp
    ContextProcessor.cpp
    network/AuthSessionStore.cpp
    network/NativeHttpClient.cpp
    network/HttpRangeStreamCache.cpp
    cache/DiskCache.cpp
    metadata/TrackInfoProvider.cpp
    content_delivery/HeadFileManager.cpp
    content_delivery/StorageResolveClient.cpp
    drm/WidevineLicenseClient.cpp
    streamer/FileStreamerImpl.cpp
    rendering/CoreAudioTrackPlayer.cpp
    rendering/AudioTrackPlayer.cpp
    rendering/UnplayableTrackPlayer.cpp
    rendering/RoutingTrackPlayer.cpp
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
    CURL::libcurl
    mbedtls
    mbedx509
    mbedcrypto
    ZLIB::ZLIB
    oboe::oboe
    ${LOG_LIB}
    ${MEDIANDK_LIB}
)
