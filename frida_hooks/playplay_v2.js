// Playplay Key Interceptor v2 - Hook the actual obfuscated classes
// p.qt7.invoke constructs the URL. We need to trace what handles the RESPONSE.

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

function dumpObject(obj, label) {
    if (obj === null || obj === undefined) {
        console.log(label + ": null");
        return;
    }
    try {
        var cls = obj.getClass();
        var clsName = cls.getName();
        console.log(label + ": [" + clsName + "] " + obj.toString().substring(0, 300));

        // If it's a byte array, dump hex
        if (clsName === "[B") {
            var barr = Java.array("byte", obj);
            console.log(label + " hex (" + barr.length + " bytes):\n    " + byteArrayToHex(barr));
        }
    } catch (e) {
        try {
            console.log(label + ": " + obj.toString().substring(0, 300));
        } catch (e2) {
            console.log(label + ": <cannot dump: " + e2.message + ">");
        }
    }
}

Java.perform(function () {
    console.log("=== Playplay Key Interceptor v2 ===");

    // ===== 1. Hook p.qt7.invoke to see args and return =====
    try {
        var qt7 = Java.use("p.qt7");
        qt7.invoke.implementation = function (arg0, arg1) {
            console.log("\n[QT7] ========== p.qt7.invoke ==========");
            dumpObject(arg0, "[QT7] arg0");
            dumpObject(arg1, "[QT7] arg1");

            var result = this.invoke(arg0, arg1);

            dumpObject(result, "[QT7] RESULT");
            return result;
        };
        console.log("[+] Hooked p.qt7.invoke");
    } catch (e) {
        console.log("[-] qt7: " + e.message);
    }

    // ===== 2. Hook p.bt10.emit - called right after qt7 =====
    try {
        var bt10 = Java.use("p.bt10");
        var bt10methods = bt10.class.getDeclaredMethods();
        console.log("[BT10] p.bt10 methods (" + bt10methods.length + "):");
        for (var i = 0; i < bt10methods.length; i++) {
            console.log("  " + bt10methods[i].toString());
        }
        // Hook emit
        bt10.emit.implementation = function (arg0) {
            console.log("\n[BT10] emit called");
            dumpObject(arg0, "[BT10] arg0");
            var result = this.emit(arg0);
            dumpObject(result, "[BT10] result");
            return result;
        };
        console.log("[+] Hooked p.bt10.emit");
    } catch (e) {
        console.log("[-] bt10: " + e.message);
    }

    // ===== 3. Enumerate classes near qt7 to find response handler =====
    try {
        var classes = Java.enumerateLoadedClassesSync();
        var nearby = [];
        for (var i = 0; i < classes.length; i++) {
            var cn = classes[i];
            // Look for classes in the p.q* range and p.o*, p.p* (from stack trace)
            if (cn.match(/^p\.[opq][a-z][0-9]+$/) || cn.match(/^p\.[opq][a-z][a-z][0-9]+$/)) {
                nearby.push(cn);
            }
        }
        nearby.sort();
        // Find ones near qt7
        var relevantRange = nearby.filter(function(c) {
            return c >= "p.qs" && c <= "p.qu";
        });
        console.log("\n[CLASSES] Near qt7 (" + relevantRange.length + "):");
        for (var j = 0; j < relevantRange.length; j++) {
            console.log("  " + relevantRange[j]);
        }
        // Also show ph51, oh51 from stack trace
        console.log("\n[CLASSES] Stack trace classes:");
        var stackClasses = ["p.ph51", "p.oh51", "p.ss9", "p.fjt", "p.jem"];
        for (var k = 0; k < stackClasses.length; k++) {
            try {
                var sc = Java.use(stackClasses[k]);
                var scm = sc.class.getDeclaredMethods();
                console.log("  " + stackClasses[k] + " (" + scm.length + " methods):");
                for (var m = 0; m < scm.length; m++) {
                    console.log("    " + scm[m].toString());
                }
            } catch (e3) {
                console.log("  " + stackClasses[k] + ": not found");
            }
        }
    } catch (e) {
        console.log("[-] class enum: " + e.message);
    }

    // ===== 4. Find the ACTUAL HTTP client Spotify uses =====
    try {
        var classes2 = Java.enumerateLoadedClassesSync();
        var httpClasses = [];
        for (var i = 0; i < classes2.length; i++) {
            var cn = classes2[i];
            if (cn.indexOf("HttpUrl") >= 0 || cn.indexOf("httpurl") >= 0 ||
                cn.indexOf("HttpEngine") >= 0 || cn.indexOf("OkHttp") >= 0 ||
                cn.indexOf("okhttp") >= 0 || cn.indexOf("Http2") >= 0 ||
                cn.indexOf("RealCall") >= 0) {
                httpClasses.push(cn);
            }
        }
        console.log("\n[HTTP_CLASSES] Found " + httpClasses.length + ":");
        for (var j = 0; j < httpClasses.length; j++) {
            console.log("  " + httpClasses[j]);
        }
    } catch (e) {}

    // ===== 5. Search for playplay-related classes =====
    try {
        var classes3 = Java.enumerateLoadedClassesSync();
        var playClasses = [];
        for (var i = 0; i < classes3.length; i++) {
            var cn = classes3[i];
            if (cn.indexOf("playplay") >= 0 || cn.indexOf("PlayPlay") >= 0 ||
                cn.indexOf("Playplay") >= 0 || cn.indexOf("PLAYPLAY") >= 0) {
                playClasses.push(cn);
            }
        }
        console.log("\n[PLAYPLAY_CLASSES] Found " + playClasses.length + ":");
        for (var j = 0; j < playClasses.length; j++) {
            console.log("  " + playClasses[j]);
        }
    } catch (e) {}

    // ===== 6. Hook ByteBuffer - keys often passed as ByteBuffer =====
    try {
        var ByteBuffer = Java.use("java.nio.ByteBuffer");
        ByteBuffer.wrap.overload("[B").implementation = function (arr) {
            if (arr.length >= 16 && arr.length <= 256) {
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                var stackStr = "";
                for (var s = 0; s < Math.min(stack.length, 15); s++) {
                    stackStr += stack[s].toString() + " | ";
                }
                if (stackStr.indexOf("key") >= 0 || stackStr.indexOf("Key") >= 0 ||
                    stackStr.indexOf("play") >= 0 || stackStr.indexOf("crypt") >= 0 ||
                    stackStr.indexOf("drm") >= 0 || stackStr.indexOf("qt7") >= 0 ||
                    stackStr.indexOf("license") >= 0) {
                    console.log("\n[BYTEBUF] wrap(" + arr.length + " bytes) - KEY CANDIDATE");
                    console.log("[BYTEBUF] hex:\n    " + byteArrayToHex(arr));
                    console.log("[BYTEBUF] stack: " + stackStr.substring(0, 400));
                }
            }
            return this.wrap(arr);
        };
        console.log("[+] Hooked ByteBuffer.wrap");
    } catch (e) {
        console.log("[-] ByteBuffer: " + e.message);
    }

    // ===== 7. Hook native JNI calls from liborbit =====
    function hookNative() {
        var lib = Process.findModuleByName("liborbit-jni-spotify.so");
        if (!lib) {
            setTimeout(hookNative, 3000);
            return;
        }
        var base = lib.base;
        console.log("[+] liborbit base: " + base);

        // Hook KEY_SETUP, CIPHER_INIT, STREAM_DECRYPT
        var hooks = [
            [0xba2ba2, "KEY_SETUP"],
            [0x1680b2e, "CIPHER_INIT"],
            [0xba4ade, "STREAM_DECRYPT"],
            [0xaabd15, "CENC_SELECT"],
            [0x10bfd3e, "SAMPLE_DECRYPT"],
            [0x1680966, "CRYPTO_SETUP"],
            [0x167f28c, "SHA1_INIT"],
            [0x16813db, "XOR_ENCRYPT"],
        ];

        for (var i = 0; i < hooks.length; i++) {
            (function (offset, name) {
                try {
                    var count = 0;
                    NativeInterceptor.attach(base.add(offset), {
                        onEnter: function () {
                            count++;
                            if (count <= 3) {
                                console.log("[NATIVE] " + name + " called (#" + count + ")");
                            }
                        }
                    });
                    console.log("[+] " + name + " @ " + offset.toString(16));
                } catch (e) {
                    console.log("[-] " + name + ": " + e.message);
                }
            })(hooks[i][0], hooks[i][1]);
        }
    }

    hookNative();
    console.log("\n=== Play a track now ===");
});
