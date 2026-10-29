#pragma once

#include <jni.h>
#include <android/log.h>

#define JNI_TAG "MusifyJni"
#define JNI_LOGI(...) __android_log_print(ANDROID_LOG_INFO,  JNI_TAG, __VA_ARGS__)
#define JNI_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, JNI_TAG, __VA_ARGS__)

struct JniThreadAttacher {
    JavaVM* vm{nullptr};
    bool attached{false};

    explicit JniThreadAttacher(JavaVM* javaVm, const char* name = "MusifyWorker") : vm(javaVm) {
        if (!vm) return;
        JNIEnv* env = nullptr;
        jint res = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (res == JNI_EDETACHED) {
            JavaVMAttachArgs args;
            args.version = JNI_VERSION_1_6;
            args.name = name;
            args.group = nullptr;
            if (vm->AttachCurrentThread(&env, &args) == JNI_OK) {
                attached = true;
                JNI_LOGI("Thread '%s' attached to JavaVM", name);
            } else {
                JNI_LOGE("Failed to attach thread '%s' to JavaVM", name);
            }
        }
    }

    ~JniThreadAttacher() {
        if (attached && vm) {
            vm->DetachCurrentThread();
            JNI_LOGI("Thread detached from JavaVM");
        }
    }
};
