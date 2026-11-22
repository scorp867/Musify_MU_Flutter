// Network Interceptor - Catch playplay endpoint + all HTTP traffic
// Target: Spotify Android (x86 emulator)
// Goal: Find the playplay URL as it's constructed at runtime

"use strict";

var MAX_LOGS = 500;
var logCount = 0;

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

function tryReadCString(ptr, maxLen) {
    try {
        var s = ptr.readCString();
        if (s && s.length > 0 && s.length < (maxLen || 2000)) return s;
        return null;
    } catch (e) {
        return null;
    }
}

function tryReadUtf8(ptr, len) {
    try {
        return ptr.readUtf8String(len);
    } catch (e) {
        try { return ptr.readCString(); } catch (e2) { return null; }
    }
}

function scanForAscii(ptr, len) {
    // Extract printable ASCII runs from a buffer
    try {
        var bytes = ptr.readByteArray(len);
        if (!bytes) return "";
        var arr = new Uint8Array(bytes);
        var runs = [];
        var current = "";
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] >= 0x20 && arr[i] < 0x7f) {
                current += String.fromCharCode(arr[i]);
            } else {
                if (current.length >= 4) runs.push(current);
                current = "";
            }
        }
        if (current.length >= 4) runs.push(current);
        return runs.join(" | ");
    } catch (e) {
        return "";
    }
}

// ===== 1. HOOK getaddrinfo - DNS lookups =====
var libc = Process.findModuleByName("libc.so");
var getaddrinfo = libc ? libc.findExportByName("getaddrinfo") : null;
if (getaddrinfo) {
    Interceptor.attach(getaddrinfo, {
        onEnter: function (args) {
            this.host = tryReadCString(args[0]);
            this.service = tryReadCString(args[1]);
            if (this.host) {
                console.log("\n[DNS] getaddrinfo: " + this.host + " : " + (this.service || "?"));
            }
        }
    });
    console.log("[+] Hooked getaddrinfo");
}

// ===== 2. HOOK connect - outgoing TCP =====
var connect_fn = libc ? libc.findExportByName("connect") : null;
if (connect_fn) {
    Interceptor.attach(connect_fn, {
        onEnter: function (args) {
            this.fd = args[0].toInt32();
            var sa = args[1];
            try {
                var family = sa.readU16();
                if (family === 2) { // AF_INET
                    var port = (sa.add(2).readU8() << 8) | sa.add(3).readU8();
                    var ip = sa.add(4).readU8() + "." +
                             sa.add(5).readU8() + "." +
                             sa.add(6).readU8() + "." +
                             sa.add(7).readU8();
                    if (port === 443 || port === 80 || port === 4070) {
                        console.log("[CONNECT] fd=" + this.fd + " -> " + ip + ":" + port);
                    }
                }
            } catch (e) {}
        }
    });
    console.log("[+] Hooked connect");
}

// ===== 3. HOOK sendto - outgoing data =====
var sendto_fn = libc ? libc.findExportByName("sendto") : null;
if (sendto_fn) {
    Interceptor.attach(sendto_fn, {
        onEnter: function (args) {
            if (logCount >= MAX_LOGS) return;
            var fd = args[0].toInt32();
            var buf = args[1];
            var len = args[2].toInt32();
            if (len > 0 && len < 100000) {
                var ascii = scanForAscii(buf, Math.min(len, 512));
                if (ascii.indexOf("play") >= 0 || ascii.indexOf("key") >= 0 ||
                    ascii.indexOf("audio") >= 0 || ascii.indexOf("license") >= 0 ||
                    ascii.indexOf("spclient") >= 0 || ascii.indexOf("spotify") >= 0 ||
                    ascii.indexOf("drm") >= 0 || ascii.indexOf("token") >= 0) {
                    logCount++;
                    console.log("\n[SENDTO] fd=" + fd + " len=" + len);
                    console.log("  ASCII: " + ascii.substring(0, 500));
                }
            }
        }
    });
    console.log("[+] Hooked sendto");
}

// ===== 4. HOOK write - catches SSL_write internally =====
var write_fn = libc ? libc.findExportByName("write") : null;
if (write_fn) {
    Interceptor.attach(write_fn, {
        onEnter: function (args) {
            if (logCount >= MAX_LOGS) return;
            var fd = args[0].toInt32();
            var buf = args[1];
            var len = args[2].toInt32();
            // Only log medium-sized writes (skip tiny and huge)
            if (len > 20 && len < 50000) {
                var ascii = scanForAscii(buf, Math.min(len, 512));
                if (ascii.indexOf("play") >= 0 || ascii.indexOf("key") >= 0 ||
                    ascii.indexOf("audio") >= 0 || ascii.indexOf("license") >= 0 ||
                    ascii.indexOf("spclient") >= 0 || ascii.indexOf("drm") >= 0 ||
                    ascii.indexOf("protobuf") >= 0 || ascii.indexOf("token") >= 0 ||
                    ascii.indexOf("HTTP") >= 0 || ascii.indexOf("GET ") >= 0 ||
                    ascii.indexOf("POST ") >= 0) {
                    logCount++;
                    console.log("\n[WRITE] fd=" + fd + " len=" + len);
                    console.log("  ASCII: " + ascii.substring(0, 500));
                    if (len < 300) {
                        console.log("  HEX: " + hexdumpN(buf, len));
                    }
                }
            }
        }
    });
    console.log("[+] Hooked write");
}

// ===== 5. HOOK recvfrom - incoming data =====
var recvfrom_fn = libc ? libc.findExportByName("recvfrom") : null;
if (recvfrom_fn) {
    Interceptor.attach(recvfrom_fn, {
        onLeave: function (retval) {
            if (logCount >= MAX_LOGS) return;
            var len = retval.toInt32();
            if (len > 20 && len < 50000) {
                var buf = this.context.ecx; // buf is arg[1], but on leave we check saved
                // Can't reliably get buf on leave in cdecl, skip detailed parsing
            }
        }
    });
    console.log("[+] Hooked recvfrom");
}

// ===== 6. HOOK Java URL class - catches high-level HTTP =====
function hookJavaHttp() {
    try {
        // Hook java.net.URL constructor
        var URL = Java.use("java.net.URL");
        URL.$init.overload("java.lang.String").implementation = function (urlStr) {
            if (urlStr && (urlStr.indexOf("play") >= 0 || urlStr.indexOf("key") >= 0 ||
                urlStr.indexOf("audio") >= 0 || urlStr.indexOf("license") >= 0 ||
                urlStr.indexOf("drm") >= 0 || urlStr.indexOf("spclient") >= 0)) {
                console.log("\n[JAVA_URL] " + urlStr);
            }
            return this.$init(urlStr);
        };
        console.log("[+] Hooked java.net.URL");
    } catch (e) {
        console.log("[-] java.net.URL hook failed: " + e.message);
    }

    try {
        // Hook OkHttp Request.Builder.url()
        var ReqBuilder = Java.use("okhttp3.Request$Builder");
        ReqBuilder.url.overload("java.lang.String").implementation = function (urlStr) {
            if (urlStr && (urlStr.indexOf("play") >= 0 || urlStr.indexOf("key") >= 0 ||
                urlStr.indexOf("audio") >= 0 || urlStr.indexOf("license") >= 0 ||
                urlStr.indexOf("drm") >= 0 || urlStr.indexOf("spclient") >= 0)) {
                console.log("\n[OKHTTP_URL] " + urlStr);
            }
            return this.url(urlStr);
        };
        console.log("[+] Hooked OkHttp Request.Builder");
    } catch (e) {
        console.log("[-] OkHttp hook failed: " + e.message);
    }

    try {
        // Hook OkHttp Response to see what comes back
        var RespBuilder = Java.use("okhttp3.Response");
        RespBuilder.code.implementation = function () {
            var code = this.code();
            var req = this.request();
            if (req) {
                var url = req.url().toString();
                if (url.indexOf("play") >= 0 || url.indexOf("key") >= 0 ||
                    url.indexOf("audio") >= 0 || url.indexOf("license") >= 0 ||
                    url.indexOf("drm") >= 0) {
                    console.log("\n[OKHTTP_RESP] " + code + " <- " + url);
                }
            }
            return code;
        };
        console.log("[+] Hooked OkHttp Response");
    } catch (e) {
        console.log("[-] OkHttp Response hook failed: " + e.message);
    }

    try {
        // Catch Spotify's internal HTTP client
        var classes = Java.enumerateLoadedClassesSync();
        for (var i = 0; i < classes.length; i++) {
            var cn = classes[i];
            if (cn.indexOf("spotify") >= 0 && cn.indexOf("http") >= 0 &&
                cn.indexOf("Http") >= 0) {
                console.log("[JAVA_CLASS] Found: " + cn);
            }
        }
    } catch (e) {}
}

// ===== 7. HOOK inside liborbit for string construction =====
function hookNativeStrings() {
    var lib = Process.findModuleByName("liborbit-jni-spotify.so");
    if (!lib) {
        console.log("[-] liborbit not loaded yet");
        return;
    }
    var base = lib.base;
    console.log("[+] liborbit base: " + base);

    // Hook the logging function at 0x17f273c that takes format strings
    // This is called from the sample decryption code with error messages
    // It will show us DRM/key-related log messages
    var logFunc = base.add(0x17f273c);
    try {
        Interceptor.attach(logFunc, {
            onEnter: function (args) {
                if (logCount >= MAX_LOGS) return;
                // args: level, source_file, line_num, format_string, ...
                var level = args[0].toInt32();
                var src = tryReadCString(args[1]);
                var line = args[2].toInt32();
                var fmt = tryReadCString(args[3]);
                if (fmt && (fmt.indexOf("key") >= 0 || fmt.indexOf("Key") >= 0 ||
                    fmt.indexOf("decrypt") >= 0 || fmt.indexOf("drm") >= 0 ||
                    fmt.indexOf("DRM") >= 0 || fmt.indexOf("license") >= 0 ||
                    fmt.indexOf("play") >= 0 || fmt.indexOf("cenc") >= 0 ||
                    fmt.indexOf("sample") >= 0 || fmt.indexOf("audio") >= 0)) {
                    logCount++;
                    console.log("\n[NATIVE_LOG] level=" + level + " " + (src || "?") + ":" + line);
                    console.log("  fmt: " + fmt);
                    // Try to read first 2 format args as strings
                    var a1 = tryReadCString(args[4]);
                    var a2 = tryReadCString(args[5]);
                    if (a1) console.log("  arg1: " + a1);
                    if (a2) console.log("  arg2: " + a2);
                }
            }
        });
        console.log("[+] Hooked native log function @ 0x17f273c");
    } catch (e) {
        console.log("[-] Native log hook failed: " + e.message);
    }

    // Hook the "Track Got key" caller function area
    // The xref was at 0xbfe49f - hook the function at 0xbfe33c
    var gotKeyFunc = base.add(0xbfe33c);
    try {
        Interceptor.attach(gotKeyFunc, {
            onEnter: function (args) {
                console.log("\n[GOT_KEY] ========== TRACK GOT KEY ==========");
                console.log("[GOT_KEY] arg0 (this): " + this.context.ecx);
                console.log("[GOT_KEY] arg1: " + args[0]);
                console.log("[GOT_KEY] arg2: " + args[1]);
                // Try to dump the key data from the args
                try {
                    var obj = args[1].readPointer();
                    console.log("[GOT_KEY] *arg1: " + obj);
                    console.log("[GOT_KEY] key data: " + hexdumpN(obj, 32));
                } catch (e) {}
                try {
                    console.log("[GOT_KEY] ecx+0x00: " + hexdumpN(this.context.ecx, 16));
                } catch (e) {}
            }
        });
        console.log("[+] Hooked 'Track Got Key' function @ 0xbfe33c");
    } catch (e) {
        console.log("[-] Track Got Key hook failed: " + e.message);
    }

    // Hook the license request function - "Queuing a license request" xref at 0xbc8816
    // Find the function containing 0xbc8816
    var licReqAddr = base.add(0xbc8816);
    try {
        // Scan back for function prologue
        var funcStart = base.add(0xbc8700); // approximate
        for (var off = 0xbc8816; off > 0xbc8600; off--) {
            try {
                var b0 = base.add(off).readU8();
                var b1 = base.add(off + 1).readU8();
                var b2 = base.add(off + 2).readU8();
                if (b0 === 0x55 && b1 === 0x89 && b2 === 0xe5) {
                    funcStart = base.add(off);
                    break;
                }
            } catch (e) { break; }
        }
        Interceptor.attach(funcStart, {
            onEnter: function (args) {
                console.log("\n[LICENSE_REQ] ========== LICENSE REQUEST ==========");
                console.log("[LICENSE_REQ] ecx: " + this.context.ecx);
                // Try to dump request object
                try {
                    console.log("[LICENSE_REQ] data: " + hexdumpN(this.context.ecx, 64));
                } catch (e) {}
            }
        });
        console.log("[+] Hooked license request function near 0xbc8816");
    } catch (e) {
        console.log("[-] License request hook failed: " + e.message);
    }

    // Hook the sample decryption function at 0x10bfd3e
    var sampleDecrypt = base.add(0x10bfd3e);
    try {
        Interceptor.attach(sampleDecrypt, {
            onEnter: function (args) {
                if (logCount >= MAX_LOGS) return;
                logCount++;
                console.log("\n[SAMPLE_DECRYPT] ========== CALLED ==========");
                console.log("[SAMPLE_DECRYPT] ecx: " + this.context.ecx);
                try {
                    // Dump object fields
                    var ecx = this.context.ecx;
                    console.log("[SAMPLE_DECRYPT] [ecx+0x00..0x40]: " + hexdumpN(ecx, 64));
                } catch (e) {}
            }
        });
        console.log("[+] Hooked sample decryption @ 0x10bfd3e");
    } catch (e) {
        console.log("[-] Sample decryption hook failed: " + e.message);
    }

    // Hook cenc/ctr scheme selector at 0xaabd15
    var cencSelector = base.add(0xaabd15);
    try {
        Interceptor.attach(cencSelector, {
            onEnter: function (args) {
                var scheme = args[0].toInt32();
                console.log("\n[CENC] Scheme selector called, arg0=" + scheme +
                    (scheme === 8 ? " (cenc/ctr)" : scheme === 9 ? " (cenc/cbcs)" : ""));
                console.log("[CENC] ecx: " + this.context.ecx);
                console.log("[CENC] edx: " + this.context.edx);
            }
        });
        console.log("[+] Hooked CENC scheme selector @ 0xaabd15");
    } catch (e) {
        console.log("[-] CENC selector hook failed: " + e.message);
    }
}

// ===== MAIN =====
console.log("=== Spotify Network + DRM Interceptor ===");
console.log("Play a track after hooks are installed.");
console.log("Look for [JAVA_URL], [OKHTTP_URL], [DNS], [NATIVE_LOG], [GOT_KEY]");
console.log("");

Java.perform(function () {
    hookJavaHttp();
    hookNativeStrings();
});
