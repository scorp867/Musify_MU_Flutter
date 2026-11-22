// Playplay Key Interceptor v4 - Hook RegisterNatives + JNI byte array calls
// Strategy: Catch ALL dynamically registered native methods at startup,
// then hook the JNI byte-array functions to catch key data crossing the boundary

"use strict";

var NativeInterceptor = Interceptor;

function byteArrayToHex(arr) {
    var hex = "";
    for (var i = 0; i < arr.length; i++) {
        var b = arr[i] & 0xff;
        hex += (b < 16 ? "0" : "") + b.toString(16) + " ";
        if ((i + 1) % 32 === 0 && i + 1 < arr.length) hex += "\n    ";
    }
    return hex.trim();
}

function hexdumpN(ptr, n) {
    try {
        var out = "";
        for (var i = 0; i < n; i++) {
            var b = ptr.add(i).readU8();
            out += (b < 16 ? "0" : "") + b.toString(16) + " ";
            if ((i + 1) % 32 === 0 && i + 1 < n) out += "\n    ";
        }
        return out.trim();
    } catch (e) {
        return "<unreadable>";
    }
}

// ===== 1. Hook RegisterNatives to catch ALL dynamically registered JNI methods =====
// This is called from JNI_OnLoad at 0x878833
var registeredNatives = [];

Java.perform(function () {
    console.log("=== Playplay v4 - JNI Boundary Intercept ===");

    // ===== 2. Enumerate Cosmos + key classes and their native methods =====
    try {
        var classes = Java.enumerateLoadedClassesSync();
        var relevant = [];
        for (var i = 0; i < classes.length; i++) {
            var cn = classes[i];
            if (cn.indexOf("cosmos") >= 0 || cn.indexOf("Cosmos") >= 0) {
                relevant.push(cn);
            }
        }
        relevant.sort();
        console.log("\n[COSMOS] " + relevant.length + " classes:");
        for (var j = 0; j < Math.min(relevant.length, 50); j++) {
            console.log("  " + relevant[j]);
        }
    } catch (e) {}

    // ===== 3. Find classes with native methods related to keys/crypto =====
    try {
        var classes2 = Java.enumerateLoadedClassesSync();
        console.log("\n[NATIVE_SCAN] Scanning for classes with native methods...");
        var nativeCount = 0;
        for (var i = 0; i < classes2.length; i++) {
            var cn = classes2[i];
            // Skip framework classes
            if (cn.indexOf("android.") === 0 || cn.indexOf("java.") === 0 ||
                cn.indexOf("sun.") === 0 || cn.indexOf("dalvik.") === 0 ||
                cn.indexOf("libcore.") === 0) continue;

            try {
                var c = Java.use(cn);
                var ms = c.class.getDeclaredMethods();
                for (var m = 0; m < ms.length; m++) {
                    var mod = ms[m].getModifiers();
                    if ((mod & 0x100) !== 0) { // native
                        var methodName = ms[m].getName();
                        var fullSig = ms[m].toString();
                        // Log ALL native methods from spotify classes
                        if (cn.indexOf("spotify") >= 0 || cn.indexOf("p.") === 0) {
                            console.log("[NATIVE] " + fullSig);
                            nativeCount++;
                        }
                    }
                }
            } catch (e2) {}
        }
        console.log("[NATIVE_SCAN] Found " + nativeCount + " native methods");
    } catch (e) {
        console.log("[-] native scan: " + e.message);
    }

    // ===== 4. Hook ALL classes in the playplay call chain =====
    // From stack: p.qt7 -> p.bt10 -> p.ph51 -> p.oh51
    // These are Kotlin coroutine/flow classes

    // Hook p.ph51.m (line 197) - processes the playplay request
    try {
        var ph51 = Java.use("p.ph51");
        var ph51methods = ph51.class.getDeclaredMethods();
        console.log("\n[PH51] p.ph51 methods (" + ph51methods.length + "):");
        for (var i = 0; i < ph51methods.length; i++) {
            console.log("  " + ph51methods[i].toString());
        }
    } catch (e) {
        console.log("[-] ph51: " + e.message);
    }

    // Hook p.oh51 (line 13) - Kotlin coroutine suspend function
    try {
        var oh51 = Java.use("p.oh51");
        var oh51methods = oh51.class.getDeclaredMethods();
        console.log("\n[OH51] p.oh51 methods (" + oh51methods.length + "):");
        for (var i = 0; i < oh51methods.length; i++) {
            console.log("  " + oh51methods[i].toString());
        }
        // Also dump fields - might contain the response handler
        var oh51fields = oh51.class.getDeclaredFields();
        console.log("[OH51] fields (" + oh51fields.length + "):");
        for (var i = 0; i < oh51fields.length; i++) {
            console.log("  " + oh51fields[i].getName() + " : " + oh51fields[i].getType().getName());
        }
    } catch (e) {
        console.log("[-] oh51: " + e.message);
    }

    // ===== 5. CRITICAL: Hook the Cosmos response callback =====
    // ScopedCallbackRouter routes spotify-endpoint:// to actual HTTP
    // Find its methods and hook the response path
    try {
        var Router = Java.use("com.spotify.cosmos.servicebasedrouter.ScopedCallbackRouter");
        var rMethods = Router.class.getDeclaredMethods();
        console.log("\n[ROUTER] Methods (" + rMethods.length + "):");
        for (var i = 0; i < rMethods.length; i++) {
            console.log("  " + rMethods[i].toString());
        }
        var rFields = Router.class.getDeclaredFields();
        console.log("[ROUTER] Fields (" + rFields.length + "):");
        for (var i = 0; i < rFields.length; i++) {
            console.log("  " + rFields[i].getName() + " : " + rFields[i].getType().getName());
        }
    } catch (e) {
        console.log("[-] Router: " + e.message);
    }

    // ===== 6. Hook protobuf parsing - response is protobuf =====
    try {
        var classes3 = Java.enumerateLoadedClassesSync();
        var protoClasses = [];
        for (var i = 0; i < classes3.length; i++) {
            var cn = classes3[i];
            if ((cn.indexOf("proto") >= 0 || cn.indexOf("Proto") >= 0) &&
                cn.indexOf("spotify") >= 0 && cn.indexOf("$") < 0) {
                protoClasses.push(cn);
            }
        }
        console.log("\n[PROTO] Spotify protobuf classes (" + protoClasses.length + "):");
        for (var j = 0; j < Math.min(protoClasses.length, 30); j++) {
            console.log("  " + protoClasses[j]);
        }
    } catch (e) {}

    // ===== 7. Hook Google protobuf parseFrom - catches ALL protobuf responses =====
    try {
        var CodedInputStream = Java.use("com.google.protobuf.CodedInputStream");
        // Log readBytes calls that could carry key data
        CodedInputStream.readBytes.implementation = function () {
            var result = this.readBytes();
            var size = result.size();
            if (size >= 16 && size <= 256) {
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                var stackStr = "";
                for (var s = 0; s < Math.min(stack.length, 15); s++) {
                    stackStr += stack[s].toString() + " | ";
                }
                if (stackStr.indexOf("key") >= 0 || stackStr.indexOf("Key") >= 0 ||
                    stackStr.indexOf("play") >= 0 || stackStr.indexOf("drm") >= 0 ||
                    stackStr.indexOf("crypt") >= 0 || stackStr.indexOf("audio") >= 0) {
                    console.log("\n[PROTO_BYTES] readBytes size=" + size);
                    var arr = result.toByteArray();
                    console.log("[PROTO_BYTES] hex:\n    " + byteArrayToHex(arr));
                    console.log("[PROTO_BYTES] stack: " + stackStr.substring(0, 500));
                }
            }
            return result;
        };
        console.log("[+] Hooked CodedInputStream.readBytes");
    } catch (e) {
        console.log("[-] protobuf hook: " + e.message);
    }

    // ===== 8. Hook ByteBuffer.wrap and allocate for key-sized buffers =====
    try {
        var ByteBuffer = Java.use("java.nio.ByteBuffer");
        ByteBuffer.wrap.overload("[B").implementation = function (arr) {
            if (arr.length === 16 || arr.length === 20 || arr.length === 32 ||
                (arr.length >= 128 && arr.length <= 256)) {
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                var stackStr = "";
                for (var s = 0; s < Math.min(stack.length, 10); s++) {
                    stackStr += stack[s].toString() + " | ";
                }
                if (stackStr.indexOf("key") >= 0 || stackStr.indexOf("Key") >= 0 ||
                    stackStr.indexOf("play") >= 0 || stackStr.indexOf("drm") >= 0 ||
                    stackStr.indexOf("crypt") >= 0 || stackStr.indexOf("cosmos") >= 0) {
                    console.log("\n[BYTEBUF] wrap(" + arr.length + " bytes)");
                    console.log("[BYTEBUF] hex:\n    " + byteArrayToHex(arr));
                    console.log("[BYTEBUF] stack: " + stackStr.substring(0, 300));
                }
            }
            return this.wrap(arr);
        };
        console.log("[+] Hooked ByteBuffer.wrap");
    } catch (e) {
        console.log("[-] ByteBuffer: " + e.message);
    }

    // ===== 9. Hook JNI GetByteArrayElements / SetByteArrayRegion =====
    // These are how native code reads/writes Java byte arrays
    function hookJNIBoundary() {
        var lib = Process.findModuleByName("liborbit-jni-spotify.so");
        if (!lib) { setTimeout(hookJNIBoundary, 3000); return; }
        var base = lib.base;
        console.log("\n[+] liborbit base: " + base);

        // Hook the JNI env functions through the function table
        // On Android, the JNI function table is accessed through JNIEnv*
        // GetByteArrayElements is at index 184 (0xB8*4 = 0x2E0)
        // We can hook the libart functions instead

        var libart = Process.findModuleByName("libart.so");
        if (!libart) {
            console.log("[-] libart not found");
            return;
        }

        // Hook NewByteArray - when native code creates a byte array to return to Java
        var newByteArray = libart.findExportByName("_ZN3art3JNI12NewByteArrayEP7_JNIEnvi");
        if (newByteArray) {
            var nbaCount = 0;
            NativeInterceptor.attach(newByteArray, {
                onEnter: function (args) {
                    this.size = args[1].toInt32();
                },
                onLeave: function (retval) {
                    if (this.size === 16 || this.size === 20 || this.size === 128 ||
                        this.size === 160 || this.size === 256) {
                        nbaCount++;
                        if (nbaCount <= 20) {
                            console.log("[JNI] NewByteArray(" + this.size + ")");
                        }
                    }
                }
            });
            console.log("[+] Hooked NewByteArray");
        }

        // Hook SetByteArrayRegion - when native code writes bytes into a Java array
        var setBAR = libart.findExportByName("_ZN3art3JNI18SetByteArrayRegionEP7_JNIEnvP11_jbyteArrayiiBKa");
        if (!setBAR) setBAR = libart.findExportByName("_ZN3art3JNI18SetByteArrayRegionEP7_JNIEnvP11_jbyteArrayiiPKa");
        if (setBAR) {
            NativeInterceptor.attach(setBAR, {
                onEnter: function (args) {
                    var start = args[2].toInt32();
                    var len = args[3].toInt32();
                    var buf = args[4];
                    if (len === 16 || len === 20 || len === 128) {
                        console.log("\n[JNI] SetByteArrayRegion(start=" + start + " len=" + len + ")");
                        console.log("[JNI] data:\n    " + hexdumpN(buf, len));
                    }
                }
            });
            console.log("[+] Hooked SetByteArrayRegion");
        }

        // Keep monitoring native crypto
        var hooks = [
            [0xba2ba2, "KEY_SETUP"],
            [0x1680b2e, "CIPHER_INIT"],
            [0xba4ade, "STREAM_DECRYPT"],
        ];
        for (var i = 0; i < hooks.length; i++) {
            (function (offset, name) {
                try {
                    var count = 0;
                    NativeInterceptor.attach(base.add(offset), {
                        onEnter: function () {
                            count++;
                            if (count <= 3) console.log("[NATIVE] " + name + " FIRED #" + count);
                        }
                    });
                } catch (e) {}
            })(hooks[i][0], hooks[i][1]);
        }
        console.log("[+] Native hooks installed");
    }
    hookJNIBoundary();

    console.log("\n=== Play a track. Watch for [PROTO_BYTES], [BYTEBUF], [JNI], [NATIVE] ===");
});
