# Proguard / R8 rules for Musify MU release build

-keep class um.musify.mu.musify_mu.MainActivity { *; }
-keepclassmembers class um.musify.mu.musify_mu.MainActivity {
    public *;
}

# Preserve Protobuf serialization and reflection structures
-keep class com.google.protobuf.** { *; }
