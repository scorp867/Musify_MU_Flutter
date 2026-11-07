#include "NativeHttpClient.h"

#include "../JniHelper.h"

#include <android/log.h>
#include <cstring>

#define HTTP_LOG_TAG "MusifyNativeHttp"
#define HTTP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, HTTP_LOG_TAG, __VA_ARGS__)
#define HTTP_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, HTTP_LOG_TAG, __VA_ARGS__)

namespace spotify::network {

namespace {
constexpr const char* kWebPlayerAppVersion = "1.2.87.215.g6e7e7fc2";
constexpr const char* kWebPlayerUserAgent =
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36";
} // namespace

NativeHttpClient::NativeHttpClient(AuthSessionStore& auth_store)
    : auth_store_(auth_store) {}

HttpResponse NativeHttpClient::get(
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    return executeWithAuthRetry(
        "GET",
        url,
        extra_headers,
        nullptr,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth);
}

HttpResponse NativeHttpClient::post(
    const std::string& url,
    const std::vector<uint8_t>& body,
    const std::string& content_type,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    std::vector<std::pair<std::string, std::string>> merged = extra_headers;
    if (!content_type.empty()) {
        merged.emplace_back("Content-Type", content_type);
    }
    return executeWithAuthRetry(
        "POST",
        url,
        merged,
        &body,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth);
}

HttpResponse NativeHttpClient::executeWithAuthRetry(
    const std::string& method,
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::vector<uint8_t>* body,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    for (int attempt = 0; attempt < 2; ++attempt) {
        const AuthCredentials creds = auth_store_.snapshot();
        std::vector<std::pair<std::string, std::string>> headers;
        headers.reserve(extra_headers.size() + 9);

        if (include_spotify_auth) {
            if (!creds.access_token.empty()) {
                headers.emplace_back("Authorization", "Bearer " + creds.access_token);
            }
            if (!creds.client_token.empty()) {
                headers.emplace_back("client-token", creds.client_token);
            }
            if (!creds.sp_dc.empty()) {
                headers.emplace_back("Cookie", "sp_dc=" + creds.sp_dc);
            }
            headers.emplace_back("app-platform", "WebPlayer");
            headers.emplace_back("spotify-app-version", kWebPlayerAppVersion);
            headers.emplace_back("User-Agent", kWebPlayerUserAgent);
            headers.emplace_back("Origin", "https://open.spotify.com");
            headers.emplace_back("Referer", "https://open.spotify.com/");
            headers.emplace_back("Accept-Encoding", "gzip");
            if (!creds.accept_language.empty()) {
                headers.emplace_back("accept-language", creds.accept_language);
            }
        }

        for (const auto& kv : extra_headers) {
            headers.push_back(kv);
        }

        HttpResponse resp = executeOnce(
            method, url, headers, body, connect_timeout_ms, read_timeout_ms);

        if (include_spotify_auth && resp.transport_ok && resp.status_code == 401 && attempt == 0) {
            HTTP_LOGW("HTTP 401 on %s %s; requesting token refresh from Dart",
                      method.c_str(), url.c_str());
            if (auth_store_.requestTokenRefreshAndWait(creds.generation, 8000)) {
                continue;
            }
        }
        return resp;
    }

    return HttpResponse{};
}

HttpResponse NativeHttpClient::executeOnce(
    const std::string& method,
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& headers,
    const std::vector<uint8_t>* body,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpResponse out;

    JavaVM* vm = getMusifyJavaVm();
    if (!vm) {
        HTTP_LOGE("JavaVM is null in NativeHttpClient::executeOnce");
        return out;
    }

    JniThreadAttacher attacher(vm, "MusifyHttpWorker");
    JNIEnv* env = attacher.env;
    if (!env) {
        HTTP_LOGE("JNIEnv is null in NativeHttpClient::executeOnce");
        return out;
    }

    jclass bridge_cls = getMusifyHttpBridgeClass();
    jmethodID exec_mid = getMusifyExecuteHttpMethod();
    bool delete_local_cls = false;

    if ((!bridge_cls || !exec_mid) && getMusifyClassLoader() && getMusifyLoadClassMethod()) {
        jstring cls_name = env->NewStringUTF("um.musify.mu.musify_mu.NativeHttpBridge");
        auto loaded = static_cast<jclass>(
            env->CallObjectMethod(getMusifyClassLoader(), getMusifyLoadClassMethod(), cls_name));
        env->DeleteLocalRef(cls_name);
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        } else if (loaded) {
            bridge_cls = loaded;
            exec_mid = env->GetStaticMethodID(
                bridge_cls,
                "executeRequest",
                "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;[BII)[B");
            if (env->ExceptionCheck()) {
                env->ExceptionClear();
                exec_mid = nullptr;
            }
            delete_local_cls = true;
        }
    }

    if (!bridge_cls || !exec_mid) {
        if (delete_local_cls && bridge_cls) env->DeleteLocalRef(bridge_cls);
        HTTP_LOGE("NativeHttpBridge.executeRequest unavailable");
        return out;
    }

    jstring j_method = env->NewStringUTF(method.c_str());
    jstring j_url = env->NewStringUTF(url.c_str());
    jclass string_cls = env->FindClass("java/lang/String");
    const jsize pair_count = static_cast<jsize>(headers.size() * 2);
    jobjectArray j_headers = env->NewObjectArray(pair_count, string_cls, nullptr);

    for (size_t i = 0; i < headers.size(); ++i) {
        jstring jk = env->NewStringUTF(headers[i].first.c_str());
        jstring jv = env->NewStringUTF(headers[i].second.c_str());
        env->SetObjectArrayElement(j_headers, static_cast<jsize>(i * 2), jk);
        env->SetObjectArrayElement(j_headers, static_cast<jsize>(i * 2 + 1), jv);
        env->DeleteLocalRef(jk);
        env->DeleteLocalRef(jv);
    }

    jbyteArray j_body = nullptr;
    if (body && !body->empty()) {
        j_body = env->NewByteArray(static_cast<jsize>(body->size()));
        env->SetByteArrayRegion(
            j_body,
            0,
            static_cast<jsize>(body->size()),
            reinterpret_cast<const jbyte*>(body->data()));
    }

    auto j_resp = static_cast<jbyteArray>(env->CallStaticObjectMethod(
        bridge_cls,
        exec_mid,
        j_method,
        j_url,
        j_headers,
        j_body,
        static_cast<jint>(connect_timeout_ms),
        static_cast<jint>(read_timeout_ms)));

    if (env->ExceptionCheck()) {
        env->ExceptionClear();
        j_resp = nullptr;
    }

    if (j_resp) {
        const jsize total_len = env->GetArrayLength(j_resp);
        if (total_len >= 4) {
            std::vector<uint8_t> raw(static_cast<size_t>(total_len));
            env->GetByteArrayRegion(
                j_resp, 0, total_len, reinterpret_cast<jbyte*>(raw.data()));
            const uint32_t code_u32 =
                static_cast<uint32_t>(raw[0]) |
                (static_cast<uint32_t>(raw[1]) << 8) |
                (static_cast<uint32_t>(raw[2]) << 16) |
                (static_cast<uint32_t>(raw[3]) << 24);
            out.status_code = static_cast<int32_t>(code_u32);
            out.transport_ok = true;
            if (total_len > 4) {
                out.body.assign(raw.begin() + 4, raw.end());
            }
        }
        env->DeleteLocalRef(j_resp);
    }

    if (j_body) env->DeleteLocalRef(j_body);
    env->DeleteLocalRef(j_headers);
    env->DeleteLocalRef(string_cls);
    env->DeleteLocalRef(j_url);
    env->DeleteLocalRef(j_method);
    if (delete_local_cls) env->DeleteLocalRef(bridge_cls);

    return out;
}

} // namespace spotify::network
