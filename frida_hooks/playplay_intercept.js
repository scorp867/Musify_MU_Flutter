// Playplay Key Interceptor v1
// Captures request + response for playplay/v1/key/{file_id}
// Goal: Extract the obfuscated key response and the hardcoded token request

"use strict";

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

function byteArrayToHex(arr) {
    var hex = "";
    for (var i = 0; i < arr.length; i++) {
        var b = arr[i] & 0xff;
        hex += (b < 16 ? "0" : "") + b.toString(16) + " ";
        if ((i + 1) % 32 === 0 && i + 1 < arr.length) hex += "\n    ";
    }
    return hex.trim();
}

Java.perform(function () {
    console.log("=== Playplay Key Interceptor ===");

    // Save Frida's native Interceptor before any Java class can shadow it
    var NativeInterceptor = Interceptor;

    // ===== 1. Load OkHttp classes =====
    try {
        var OkBuffer = Java.use("okio.Buffer");
        console.log("[+] OkHttp classes loaded");
    } catch (e) {
        console.log("[-] OkHttp load failed: " + e.message);
    }

    // ===== 2. Hook the URL builder to intercept playplay requests =====
    try {
        var URL = Java.use("java.net.URL");
        URL.$init.overload("java.lang.String").implementation = function (urlStr) {
            if (urlStr && urlStr.indexOf("playplay/v1/key") >= 0) {
                console.log("\n[PLAYPLAY] ========================================");
                console.log("[PLAYPLAY] URL: " + urlStr);
                // Print stack trace to find the caller
                console.log("[PLAYPLAY] Stack:");
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                for (var i = 2; i < Math.min(stack.length, 15); i++) {
                    console.log("  " + stack[i].toString());
                }
            }
            return this.$init(urlStr);
        };
        console.log("[+] Hooked java.net.URL for playplay detection");
    } catch (e) {
        console.log("[-] URL hook: " + e.message);
    }

    // ===== 3. Hook OkHttp Request.Builder to capture request body =====
    try {
        var ReqBuilder = Java.use("okhttp3.Request$Builder");

        // Hook .url() to tag playplay requests
        ReqBuilder.url.overload("java.lang.String").implementation = function (urlStr) {
            if (urlStr && urlStr.indexOf("playplay") >= 0) {
                console.log("\n[PLAYPLAY_REQ] Building request: " + urlStr);
            }
            return this.url(urlStr);
        };

        // Hook .post() / .method() to capture the body
        try {
            ReqBuilder.post.overload("okhttp3.RequestBody").implementation = function (body) {
                try {
                    // Check if this builder has a playplay URL by building and checking
                    var built = this.build();
                    var url = built.url().toString();
                    if (url.indexOf("playplay") >= 0) {
                        console.log("[PLAYPLAY_REQ] POST body for: " + url);
                        if (body) {
                            var buf = Buffer.$new();
                            body.writeTo(buf);
                            var bytes = buf.readByteArray();
                            console.log("[PLAYPLAY_REQ] Body size: " + bytes.length + " bytes");
                            console.log("[PLAYPLAY_REQ] Body hex:\n    " + byteArrayToHex(bytes));
                            // Also show content type
                            var ct = body.contentType();
                            if (ct) console.log("[PLAYPLAY_REQ] Content-Type: " + ct.toString());
                        }
                    }
                } catch (e2) {
                    // Can't build yet, just log
                }
                return this.post(body);
            };
            console.log("[+] Hooked Request.Builder.post()");
        } catch (e) {
            console.log("[-] post hook: " + e.message);
        }

        console.log("[+] Hooked OkHttp Request.Builder");
    } catch (e) {
        console.log("[-] Request.Builder hook: " + e.message);
    }

    // ===== 4. Hook Response body reading to capture the key response =====
    try {
        var RespBody = Java.use("okhttp3.ResponseBody");

        // Hook bytes() - most likely used for binary key data
        RespBody.bytes.implementation = function () {
            var bytes = this.bytes();
            try {
                var resp = Java.use("java.lang.Thread").currentThread();
                // We need to check the URL somehow - use stack trace
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                var stackStr = "";
                for (var i = 0; i < Math.min(stack.length, 20); i++) {
                    stackStr += stack[i].toString() + "\n";
                }
                // Log all response bodies that could be keys (small binary blobs)
                if (bytes.length > 0 && bytes.length < 2048) {
                    console.log("\n[RESP_BODY] bytes() called, size=" + bytes.length);
                    console.log("[RESP_BODY] hex:\n    " + byteArrayToHex(bytes));
                    if (stackStr.indexOf("playplay") >= 0 || stackStr.indexOf("key") >= 0 ||
                        stackStr.indexOf("drm") >= 0 || stackStr.indexOf("decrypt") >= 0) {
                        console.log("[RESP_BODY] *** LIKELY KEY RESPONSE ***");
                        console.log("[RESP_BODY] Stack:\n" + stackStr.substring(0, 500));
                    }
                }
            } catch (e) {}
            return bytes;
        };
        console.log("[+] Hooked ResponseBody.bytes()");

        // Hook string() too
        RespBody.string.implementation = function () {
            var s = this.string();
            if (s && s.length < 500 && (s.indexOf("key") >= 0 || s.indexOf("token") >= 0)) {
                console.log("\n[RESP_STR] " + s);
            }
            return s;
        };
        console.log("[+] Hooked ResponseBody.string()");

    } catch (e) {
        console.log("[-] ResponseBody hook: " + e.message);
    }

    // ===== 5. Hook the internal spotify-endpoint resolver =====
    // The spotify-endpoint:/// scheme is routed internally. Find the router.
    try {
        var classes = Java.enumerateLoadedClassesSync();
        var candidates = [];
        for (var i = 0; i < classes.length; i++) {
            var cn = classes[i];
            if (cn.indexOf("spotify") >= 0 && cn.indexOf("ndpoint") >= 0 &&
                cn.indexOf("$") < 0) {
                candidates.push(cn);
            }
        }
        console.log("\n[ENDPOINT_CLASSES] Found " + candidates.length + " endpoint classes:");
        for (var j = 0; j < Math.min(candidates.length, 30); j++) {
            console.log("  " + candidates[j]);
        }
    } catch (e) {
        console.log("[-] Class enumeration: " + e.message);
    }

    // ===== 6. Hook ByteArrayInputStream - catches binary response reading =====
    try {
        var BAIS = Java.use("java.io.ByteArrayInputStream");
        BAIS.$init.overload("[B").implementation = function (arr) {
            // Only log small binary blobs (likely key responses)
            if (arr.length >= 16 && arr.length <= 256) {
                var stack = Java.use("java.lang.Thread").currentThread().getStackTrace();
                var stackStr = "";
                for (var k = 0; k < Math.min(stack.length, 15); k++) {
                    stackStr += stack[k].toString();
                }
                if (stackStr.indexOf("playplay") >= 0 || stackStr.indexOf("key") >= 0 ||
                    stackStr.indexOf("drm") >= 0 || stackStr.indexOf("crypt") >= 0) {
                    console.log("\n[BAIS] ByteArrayInputStream(" + arr.length + " bytes) - KEY CANDIDATE");
                    console.log("[BAIS] hex:\n    " + byteArrayToHex(arr));
                    console.log("[BAIS] stack: " + stackStr.substring(0, 300));
                }
            }
            return this.$init(arr);
        };
        console.log("[+] Hooked ByteArrayInputStream");
    } catch (e) {
        console.log("[-] BAIS hook: " + e.message);
    }

    // ===== 7. Hook p.qt7 - the class that constructs playplay URLs =====
    try {
        var qt7 = Java.use("p.qt7");
        var methods = qt7.class.getDeclaredMethods();
        console.log("[QT7] p.qt7 methods (" + methods.length + "):");
        for (var m = 0; m < methods.length; m++) {
            console.log("  " + methods[m].toString());
        }
    } catch (e) {
        console.log("[-] p.qt7 hook: " + e.message);
    }

    // ===== 8. Hook InputStream.read to catch key response bytes =====
    try {
        var HttpURLConnection = Java.use("java.net.HttpURLConnection");
        var InputStreamReader = Java.use("java.io.InputStreamReader");
        // Hook URL.openConnection to intercept playplay connections
        var URL2 = Java.use("java.net.URL");
        URL2.openConnection.overload().implementation = function () {
            var conn = this.openConnection();
            var urlStr = this.toString();
            if (urlStr.indexOf("playplay") >= 0) {
                console.log("\n[PLAYPLAY_CONN] openConnection: " + urlStr);
            }
            return conn;
        };
        console.log("[+] Hooked URL.openConnection");
    } catch (e) {
        console.log("[-] openConnection: " + e.message);
    }

    // ===== 9. Also hook native crypto entry points from v10 =====
    function hookNativeCrypto() {
        var lib = Process.findModuleByName("liborbit-jni-spotify.so");
        if (!lib) {
            console.log("[-] liborbit not loaded yet, retrying in 3s...");
            setTimeout(hookNativeCrypto, 3000);
            return;
        }
        var base = lib.base;
        console.log("[+] liborbit base: " + base);

        // KEY_SETUP at 0xba2ba2 - where NLFSR cipher gets initialized from key material
        try {
            NativeInterceptor.attach(base.add(0xba2ba2), {
                onEnter: function (args) {
                    console.log("\n[NLFSR_KEY_SETUP] ========== CALLED ==========");
                    console.log("[NLFSR_KEY_SETUP] ecx: " + this.context.ecx);
                    console.log("[NLFSR_KEY_SETUP] edx: " + this.context.edx);
                    console.log("[NLFSR_KEY_SETUP] esi: " + this.context.esi);
                    try {
                        var ecx = this.context.ecx;
                        console.log("[NLFSR_KEY_SETUP] [ecx+0x00..0x3f]:\n    " +
                            hexdumpN(ecx, 64));
                        console.log("[NLFSR_KEY_SETUP] [ecx+0x24..0x37] (20-byte hash?):\n    " +
                            hexdumpN(ecx.add(0x24), 20));
                    } catch (e) {}
                    try {
                        var esi = this.context.esi;
                        console.log("[NLFSR_KEY_SETUP] esi data:\n    " + hexdumpN(esi, 32));
                    } catch (e) {}
                }
            });
            console.log("[+] Hooked NLFSR KEY_SETUP @ 0xba2ba2");
        } catch (e) {
            console.log("[-] KEY_SETUP: " + e.message);
        }

        // CIPHER_INIT at 0x1680b2e - Fibonacci + magic 0x6996c53a
        try {
            NativeInterceptor.attach(base.add(0x1680b2e), {
                onEnter: function (args) {
                    console.log("\n[CIPHER_INIT] Called (Fibonacci + 0x6996c53a)");
                    console.log("[CIPHER_INIT] ecx: " + this.context.ecx);
                    try {
                        console.log("[CIPHER_INIT] input:\n    " +
                            hexdumpN(this.context.ecx, 32));
                    } catch (e) {}
                }
            });
            console.log("[+] Hooked CIPHER_INIT @ 0x1680b2e");
        } catch (e) {
            console.log("[-] CIPHER_INIT: " + e.message);
        }

        // STREAM_DECRYPT at 0xba4ade - actual XOR decrypt loop
        try {
            var decryptCount = 0;
            NativeInterceptor.attach(base.add(0xba4ade), {
                onEnter: function (args) {
                    decryptCount++;
                    if (decryptCount <= 5) {
                        console.log("\n[STREAM_DECRYPT] Call #" + decryptCount);
                        console.log("[STREAM_DECRYPT] ecx: " + this.context.ecx);
                        try {
                            console.log("[STREAM_DECRYPT] first 32 bytes of data:\n    " +
                                hexdumpN(this.context.ecx, 32));
                        } catch (e) {}
                    } else if (decryptCount === 6) {
                        console.log("[STREAM_DECRYPT] (suppressing further logs, count=" + decryptCount + ")");
                    }
                }
            });
            console.log("[+] Hooked STREAM_DECRYPT @ 0xba4ade");
        } catch (e) {
            console.log("[-] STREAM_DECRYPT: " + e.message);
        }

        // CENC scheme selector at 0xaabd15
        try {
            NativeInterceptor.attach(base.add(0xaabd15), {
                onEnter: function (args) {
                    var scheme = this.context.eax.toInt32();
                    console.log("\n[CENC] Scheme=" + scheme +
                        (scheme === 8 ? " (cenc/ctr)" : scheme === 9 ? " (cenc/cbcs)" : " (unknown)"));
                }
            });
            console.log("[+] Hooked CENC selector @ 0xaabd15");
        } catch (e) {
            console.log("[-] CENC: " + e.message);
        }

        // Sample decryption at 0x10bfd3e
        try {
            var sampleCount = 0;
            NativeInterceptor.attach(base.add(0x10bfd3e), {
                onEnter: function (args) {
                    sampleCount++;
                    if (sampleCount <= 3) {
                        console.log("\n[SAMPLE_DECRYPT] Call #" + sampleCount);
                        try {
                            console.log("[SAMPLE_DECRYPT] ecx:\n    " +
                                hexdumpN(this.context.ecx, 64));
                        } catch (e) {}
                    }
                }
            });
            console.log("[+] Hooked SAMPLE_DECRYPT @ 0x10bfd3e");
        } catch (e) {
            console.log("[-] SAMPLE_DECRYPT: " + e.message);
        }
    }

    hookNativeCrypto();

    console.log("\n=== All hooks installed. Play a track. ===");
    console.log("Watch for [PLAYPLAY_REQ], [RESP_BODY], [NLFSR_KEY_SETUP], [CIPHER_INIT]");
});
