#pragma once

#include <jni.h>
#include <android/log.h>

#define JNI_TAG "MusifyJni"
#define JNI_LOGI(...) __android_log_print(ANDROID_LOG_INFO,  JNI_TAG, __VA_ARGS__)
#define JNI_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, JNI_TAG, __VA_ARGS__)

JavaVM* getMusifyJavaVm() noexcept;
jclass getMusifyHttpBridgeClass() noexcept;
jmethodID getMusifyExecuteHttpMethod() noexcept;
jobject getMusifyClassLoader() noexcept;
jmethodID getMusifyLoadClassMethod() noexcept;

struct JniThreadAttacher {
    JavaVM* vm{nullptr};
    JNIEnv* env{nullptr};
    bool attached{false};

    explicit JniThreadAttacher(JavaVM* javaVm, const char* name = "MusifyWorker") : vm(javaVm) {
        if (!vm) return;
        jint res = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (res == JNI_EDETACHED) {
            JavaVMAttachArgs args;
            args.version = JNI_VERSION_1_6;
            args.name = name;
            args.group = nullptr;
            if (vm->AttachCurrentThread(&env, &args) == JNI_OK) {
                attached = true;
            } else {
                env = nullptr;
                JNI_LOGE("Failed to attach thread '%s' to JavaVM", name);
            }
        }
    }

    ~JniThreadAttacher() {
        if (attached && vm) {
            vm->DetachCurrentThread();
        }
    }
};
