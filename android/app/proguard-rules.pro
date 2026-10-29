# Proguard / R8 rules for Musify MU release build

# Preserve JNI-invoked Kotlin/Java classes called from native C++ (AudioEngine / NativeDecoder)
-keep class um.musify.mu.musify_mu.NativeHeadDownloader { *; }
-keepclassmembers class um.musify.mu.musify_mu.NativeHeadDownloader {
    public static <methods>;
    public static *;
}

-keep class um.musify.mu.musify_mu.NativeDrmBridge { *; }
-keepclassmembers class um.musify.mu.musify_mu.NativeDrmBridge {
    public static <methods>;
    public static *;
}

-keep class um.musify.mu.musify_mu.MusifyDrmManager { *; }
-keepclassmembers class um.musify.mu.musify_mu.MusifyDrmManager {
    public *;
}

-keep class um.musify.mu.musify_mu.MainActivity { *; }
-keepclassmembers class um.musify.mu.musify_mu.MainActivity {
    public *;
}

# Preserve Protobuf serialization and reflection structures
-keep class com.google.protobuf.** { *; }
