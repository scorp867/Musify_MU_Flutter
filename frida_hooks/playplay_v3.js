// Playplay Key Interceptor v3 - Trace Cosmos router + p.n130 fields
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

function dumpFields(obj, label) {
    try {
        var cls = obj.getClass();
        var fields = cls.getDeclaredFields();
        console.log(label + " fields (" + fields.length + "):");
        for (var i = 0; i < fields.length; i++) {
            fields[i].setAccessible(true);
            var name = fields[i].getName();
            var val = fields[i].get(obj);
            var type = fields[i].getType().getName();
            try {
                if (val !== null) {
                    var valStr = val.toString();
                    if (valStr.length > 300) valStr = valStr.substring(0, 300) + "...";
                    console.log("  " + name + " [" + type + "]: " + valStr);
                    // If byte array, dump hex
                    if (type === "[B") {
                        var barr = Java.array("byte", val);
                        if (barr.length <= 256) {
                            console.log("    HEX: " + byteArrayToHex(barr));
                        } else {
                            console.log("    (size=" + barr.length + ")");
                        }
                    }
                } else {
                    console.log("  " + name + " [" + type + "]: null");
                }
            } catch (e) {
                console.log("  " + name + " [" + type + "]: <err: " + e.message + ">");
            }
        }
        // Also check superclass fields
        var superCls = cls.getSuperclass();
        if (superCls && superCls.getName() !== "java.lang.Object") {
            var superFields = superCls.getDeclaredFields();
            if (superFields.length > 0) {
                console.log(label + " superclass " + superCls.getName() + " fields:");
                for (var j = 0; j < superFields.length; j++) {
                    superFields[j].setAccessible(true);
                    var sname = superFields[j].getName();
                    var sval = superFields[j].get(obj);
                    var stype = superFields[j].getType().getName();
                    try {
                        console.log("  " + sname + " [" + stype + "]: " +
                            (sval !== null ? sval.toString().substring(0, 200) : "null"));
                    } catch (e) {}
                }
            }
        }
    } catch (e) {
        console.log(label + " field dump failed: " + e.message);
    }
}

Java.perform(function () {
    console.log("=== Playplay v3 - Cosmos Router Trace ===");

    // ===== 1. Dump p.n130 fields =====
    try {
        var qt7 = Java.use("p.qt7");
        qt7.invoke.implementation = function (arg0, arg1) {
            var result = this.invoke(arg0, arg1);
            // Only dump when this is a playplay-related call
            // Check if arg0 is p.n130
            try {
                var cls = arg0.getClass().getName();
                if (cls === "p.n130") {
                    console.log("\n[QT7] ===== p.qt7.invoke (p.n130) =====");
                    dumpFields(arg0, "[N130]");
                }
            } catch (e) {}
            return result;
        };
        console.log("[+] Hooked p.qt7");
    } catch (e) {
        console.log("[-] qt7: " + e.message);
    }

    // ===== 2. Find ALL Cosmos classes =====
    try {
        var classes = Java.enumerateLoadedClassesSync();
        var cosmosClasses = [];
        for (var i = 0; i < classes.length; i++) {
            if (classes[i].indexOf("cosmos") >= 0 || classes[i].indexOf("Cosmos") >= 0) {
                cosmosClasses.push(classes[i]);
            }
        }
        cosmosClasses.sort();
        console.log("\n[COSMOS] Found " + cosmosClasses.length + " classes:");
        for (var j = 0; j < cosmosClasses.length; j++) {
            console.log("  " + cosmosClasses[j]);
        }
    } catch (e) {}

    // ===== 3. Hook Cosmos ScopedCallbackRouter =====
    try {
        var Router = Java.use("com.spotify.cosmos.servicebasedrouter.ScopedCallbackRouter");
        var routerMethods = Router.class.getDeclaredMethods();
        console.log("\n[ROUTER] ScopedCallbackRouter methods (" + routerMethods.length + "):");
        for (var m = 0; m < routerMethods.length; m++) {
            console.log("  " + routerMethods[m].toString());
        }
    } catch (e) {
        console.log("[-] Router: " + e.message);
    }

    // ===== 4. Hook Cosmos Request/Response classes =====
    try {
        var classes2 = Java.enumerateLoadedClassesSync();
        var reqRespClasses = [];
        for (var i = 0; i < classes2.length; i++) {
            var cn = classes2[i];
            if (cn.indexOf("cosmos") >= 0 &&
                (cn.indexOf("Request") >= 0 || cn.indexOf("Response") >= 0 ||
                 cn.indexOf("request") >= 0 || cn.indexOf("response") >= 0)) {
                reqRespClasses.push(cn);
            }
        }
        console.log("\n[COSMOS_REQ_RESP] Found " + reqRespClasses.length + ":");
        for (var j = 0; j < reqRespClasses.length; j++) {
            console.log("  " + reqRespClasses[j]);
        }
    } catch (e) {}

    // ===== 5. Hook Cosmos resolve/send methods that handle playplay =====
    // Try hooking the Cosmos client that actually sends requests
    try {
        var classes3 = Java.enumerateLoadedClassesSync();
        for (var i = 0; i < classes3.length; i++) {
            var cn = classes3[i];
            if (cn.indexOf("cosmos") >= 0 && cn.indexOf("Client") >= 0 &&
                cn.indexOf("$") < 0) {
                try {
                    var clientCls = Java.use(cn);
                    var cMethods = clientCls.class.getDeclaredMethods();
                    if (cMethods.length > 0 && cMethods.length < 30) {
                        console.log("\n[COSMOS_CLIENT] " + cn + " (" + cMethods.length + " methods):");
                        for (var cm = 0; cm < cMethods.length; cm++) {
                            console.log("  " + cMethods[cm].toString());
                        }
                    }
                } catch (e2) {}
            }
        }
    } catch (e) {}

    // ===== 6. Hook JNI calls for key data - look for native method calls =====
    // The key response likely gets passed to native code via JNI
    // Find native methods in playplay-related classes
    try {
        var classes4 = Java.enumerateLoadedClassesSync();
        var nativeMethods = [];
        for (var i = 0; i < classes4.length; i++) {
            var cn = classes4[i];
            if (cn.indexOf("spotify") >= 0 &&
                (cn.indexOf("key") >= 0 || cn.indexOf("Key") >= 0 ||
                 cn.indexOf("drm") >= 0 || cn.indexOf("Drm") >= 0 ||
                 cn.indexOf("DRM") >= 0 || cn.indexOf("crypt") >= 0 ||
                 cn.indexOf("Decrypt") >= 0 || cn.indexOf("cipher") >= 0)) {
                try {
                    var c = Java.use(cn);
                    var ms = c.class.getDeclaredMethods();
                    for (var m2 = 0; m2 < ms.length; m2++) {
                        var mod = ms[m2].getModifiers();
                        // Check if native (modifier bit 0x100)
                        if ((mod & 0x100) !== 0) {
                            nativeMethods.push(cn + "." + ms[m2].getName());
                            console.log("[NATIVE_METHOD] " + ms[m2].toString());
                        }
                    }
                } catch (e3) {}
            }
        }
        if (nativeMethods.length === 0) {
            console.log("[NATIVE_METHOD] No native key/drm methods found in Java classes");
        }
    } catch (e) {}

    // ===== 7. Broader search: any class with "playplay" =====
    try {
        var classes5 = Java.enumerateLoadedClassesSync();
        var ppClasses = [];
        for (var i = 0; i < classes5.length; i++) {
            if (classes5[i].toLowerCase().indexOf("playplay") >= 0) {
                ppClasses.push(classes5[i]);
            }
        }
        console.log("\n[PLAYPLAY_CLASSES] " + ppClasses.length + " found:");
        for (var j = 0; j < ppClasses.length; j++) {
            console.log("  " + ppClasses[j]);
        }
    } catch (e) {}

    // ===== 8. Hook native crypto (keep these for verification) =====
    function hookNative() {
        var lib = Process.findModuleByName("liborbit-jni-spotify.so");
        if (!lib) { setTimeout(hookNative, 3000); return; }
        var base = lib.base;
        console.log("\n[+] liborbit base: " + base);

        var hooks = [
            [0xba2ba2, "KEY_SETUP"],
            [0x1680b2e, "CIPHER_INIT"],
            [0xba4ade, "STREAM_DECRYPT"],
            [0x16813db, "XOR_ENCRYPT"],
            [0x167f28c, "SHA1_INIT"],
            [0x1680966, "CRYPTO_SETUP"],
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
                    console.log("[+] " + name);
                } catch (e) {
                    console.log("[-] " + name + ": " + e.message);
                }
            })(hooks[i][0], hooks[i][1]);
        }
    }
    hookNative();

    console.log("\n=== Play a track. Watch for [N130], [COSMOS], [NATIVE] ===");
});
