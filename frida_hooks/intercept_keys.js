/**
 * Spotify Key Interception — Frida Script
 *
 * Hooks:
 *   1. Java NativeCryptoProvider.hkdfSha512  — key derivation (IKM, salt, info, length)
 *   2. Java NativeCryptoProvider.chachaDecrypt — ChaCha20-Poly1305 decryption
 *   3. Java NativeCryptoProvider.chachaEncrypt — ChaCha20-Poly1305 encryption
 *   4. Native key_tree_insert (0x124323e)     — where derived keys enter the RB-tree
 *   5. Native decrypt_sample (0x124ca04)      — AES-CTR/CBCS sample decryption
 *   6. Native cipher_dispatch (0x124caab)     — AES block encrypt vtable call
 *   7. Native hkdf_jni_wrapper (0x153cae4)    — native-side JNI bridge to hkdfSha512
 *
 * Usage:
 *   frida -U -f com.spotify.music -l intercept_keys.js --no-pause
 *
 * Notes:
 *   - Java hooks work on ANY architecture (ARM64, x86_64, ARM32).
 *   - Native hooks use x86_64 offsets from liborbit-jni-spotify.so.
 *     For ARM64 device, replace offsets or comment out native hooks.
 *   - Anti-Frida bypass included for collectFridaFeatures().
 */

"use strict";

// ─── Configuration ───────────────────────────────────────────────────────────

const CONFIG = {
    // Set true to enable native hooks (requires correct arch offsets)
    enableNativeHooks: true,

    // Set true to dump full byte arrays (can be very verbose)
    dumpFullArrays: false,

    // Max bytes to print per array when dumpFullArrays is false
    maxDumpBytes: 64,

    // Target library for native hooks
    nativeLib: "liborbit-jni-spotify.so",

    // Architecture-specific offsets
    // Set arch to match your target device/emulator
    arch: "x86",  // "x86" for 32-bit emulator, "x86_64" for 64-bit

    offsets_x86: {
        // x86 32-bit (Android Emulator)
        decrypt_handler:    0x10c08d0,  // Pipeline decrypt handler (key lookup + AES-CTR)
        pipeline_process:   0x10bfd3e,  // Pipeline process (contains "sample decryption failed")
        key_tree_region:    0x16cea0d,  // Key tree insert/lookup region
        key_tree_lookup:    0x12fcfb6,  // Key lookup from tree (called from decrypt_handler)
        drm_setup:          0x9cee4c,   // "cpp-audio-drm_setup_impl"
        hkdf_registration:  0x141e928,  // hkdfSha512 JNI string ref region
        collectFridaFeatures: null,
    },

    offsets_x86_64: {
        // x86_64 (static analysis binary)
        key_tree_insert:    0x124323e,
        decrypt_sample:     0x124ca04,
        cipher_dispatch:    0x124caab,
        hkdf_jni_wrapper:   0x153cae4,
        key_tree_lookup:    0x124c8b2,
        collectFridaFeatures: null,
    },
};

// ─── Utilities ───────────────────────────────────────────────────────────────

function hexdump_compact(arr, max) {
    max = max || CONFIG.maxDumpBytes;
    const len = arr.length;
    const limit = Math.min(len, max);
    const hex = [];
    for (let i = 0; i < limit; i++) {
        const b = (arr[i] & 0xff);
        hex.push(("0" + b.toString(16)).slice(-2));
    }
    let s = hex.join(" ");
    if (len > max) s += ` ... (${len} bytes total)`;
    return s;
}

function javaByteArrayToHex(jarr) {
    if (!jarr) return "(null)";
    const len = jarr.length;
    const bytes = [];
    for (let i = 0; i < Math.min(len, CONFIG.maxDumpBytes); i++) {
        const b = jarr[i] & 0xff;
        bytes.push(("0" + b.toString(16)).slice(-2));
    }
    let s = bytes.join(" ");
    if (len > CONFIG.maxDumpBytes) s += ` ... (${len} bytes total)`;
    return s;
}

function readNativeBytes(ptr, len, max) {
    if (ptr.isNull()) return "(null ptr)";
    max = max || CONFIG.maxDumpBytes;
    const limit = Math.min(len, max);
    const buf = ptr.readByteArray(limit);
    if (!buf) return "(unreadable)";
    const arr = new Uint8Array(buf);
    const hex = [];
    for (let i = 0; i < arr.length; i++) {
        hex.push(("0" + arr[i].toString(16)).slice(-2));
    }
    let s = hex.join(" ");
    if (len > max) s += ` ... (${len} bytes total)`;
    return s;
}

function timestamp() {
    return new Date().toISOString().slice(11, 23);
}

// ─── Java Hooks ──────────────────────────────────────────────────────────────

function hookJavaCrypto() {
    Java.perform(function () {
        const NCP = Java.use("com.spotify.native_crypto.NativeCryptoProvider");

        // ── hkdfSha512: THE key derivation function ──
        NCP.hkdfSha512.implementation = function (salt, info, ikm, length) {
            const result = this.hkdfSha512(salt, info, ikm, length);

            console.log("\n╔══════════════════════════════════════════════════════════╗");
            console.log("║  HKDF-SHA512 KEY DERIVATION                             ║");
            console.log("╚══════════════════════════════════════════════════════════╝");
            console.log(`[${timestamp()}] hkdfSha512 called`);
            console.log(`  IKM    (${ikm.length} bytes): ${javaByteArrayToHex(ikm)}`);
            console.log(`  Salt   (${salt.length} bytes): ${javaByteArrayToHex(salt)}`);
            console.log(`  Info   (${info.length} bytes): ${javaByteArrayToHex(info)}`);
            console.log(`  Length: ${length}`);
            console.log(`  OUTPUT (${result.length} bytes): ${javaByteArrayToHex(result)}`);

            // Java stack trace — shows the JNI caller chain
            const Exception = Java.use("java.lang.Exception");
            const Log = Java.use("android.util.Log");
            console.log("  Java call stack:");
            console.log(Log.getStackTraceString(Exception.$new()));


            return result;
        };

        // ── chachaDecrypt ──
        NCP.chachaDecrypt.implementation = function (key, nonce, aad, ciphertext) {
            const result = this.chachaDecrypt(key, nonce, aad, ciphertext);

            console.log("\n┌─ ChaCha20-Poly1305 DECRYPT ─────────────────────────────┐");
            console.log(`[${timestamp()}] chachaDecrypt called`);
            console.log(`  Key        (${key.length} bytes): ${javaByteArrayToHex(key)}`);
            console.log(`  Nonce      (${nonce.length} bytes): ${javaByteArrayToHex(nonce)}`);
            console.log(`  AAD        (${aad.length} bytes): ${javaByteArrayToHex(aad)}`);
            console.log(`  Ciphertext (${ciphertext.length} bytes): ${javaByteArrayToHex(ciphertext)}`);
            console.log(`  Plaintext  (${result.length} bytes): ${javaByteArrayToHex(result)}`);
            console.log("└──────────────────────────────────────────────────────────┘\n");

            return result;
        };

        // ── chachaEncrypt ──
        NCP.chachaEncrypt.implementation = function (key, nonce, aad, plaintext) {
            const result = this.chachaEncrypt(key, nonce, aad, plaintext);

            console.log("\n┌─ ChaCha20-Poly1305 ENCRYPT ─────────────────────────────┐");
            console.log(`[${timestamp()}] chachaEncrypt called`);
            console.log(`  Key       (${key.length} bytes): ${javaByteArrayToHex(key)}`);
            console.log(`  Nonce     (${nonce.length} bytes): ${javaByteArrayToHex(nonce)}`);
            console.log(`  AAD       (${aad.length} bytes): ${javaByteArrayToHex(aad)}`);
            console.log(`  Plaintext (${plaintext.length} bytes): ${javaByteArrayToHex(plaintext)}`);
            console.log(`  Output    (${result.length} bytes): ${javaByteArrayToHex(result)}`);
            console.log("└──────────────────────────────────────────────────────────┘\n");

            return result;
        };

        // ── hmacSha512 — called internally by hkdfSha512 ──
        NCP.hmacSha512.implementation = function (key, data) {
            const result = this.hmacSha512(key, data);

            console.log(`  [hmacSha512] key=${key.length}B data=${data.length}B -> ${result.length}B`);

            return result;
        };

        console.log("[+] Java NativeCryptoProvider hooks installed");
        console.log("    - hkdfSha512 (key derivation)");
        console.log("    - chachaDecrypt");
        console.log("    - chachaEncrypt");
        console.log("    - hmacSha512 (HKDF internal)");
    });
}

// ─── Native Hooks (x86_64 — set enableNativeHooks=true) ─────────────────────

function hookNative() {
    if (!CONFIG.enableNativeHooks) {
        console.log("[*] Native hooks disabled (set CONFIG.enableNativeHooks = true)");
        return;
    }

    const mod = Process.findModuleByName(CONFIG.nativeLib);
    if (!mod) {
        console.log(`[-] ${CONFIG.nativeLib} not loaded yet, retrying...`);
        const interval = setInterval(function () {
            const m = Process.findModuleByName(CONFIG.nativeLib);
            if (m) {
                clearInterval(interval);
                installNativeHooks(m);
            }
        }, 1000);
        return;
    }
    installNativeHooks(mod);
}

function installNativeHooks(mod) {
    const base = mod.base;
    const arch = CONFIG.arch;
    const offsets = arch === "x86" ? CONFIG.offsets_x86 : CONFIG.offsets_x86_64;
    console.log(`[+] ${CONFIG.nativeLib} base: ${base} (arch: ${arch})`);

    if (arch === "x86") {
        installX86Hooks(mod, base, offsets);
    } else {
        installX86_64Hooks(mod, base, offsets);
    }

    console.log("[+] Native hooks installed");
}

// ── x86 32-bit hooks ──

function installX86Hooks(mod, base, offsets) {

    // ── Decrypt Handler (0x10c08d0) ──
    // This is the core: looks up key from tree, checks scheme, runs AES-CTR/CBCS.
    // Args passed via registers: ecx=pipeline_obj, edx=key_info
    try {
        const decryptHandler = base.add(offsets.decrypt_handler);
        Interceptor.attach(decryptHandler, {
            onEnter: function (args) {
                // In x86 __thiscall: ecx=this, edx=arg1, stack for rest
                const pipeline = this.context.ecx;
                const keyInfo = this.context.edx;
                console.log(`\n[${timestamp()}] decrypt_handler called`);
                console.log(`  pipeline: ${pipeline}  keyInfo: ${keyInfo}`);

                try {
                    // Key tree is at pipeline+0x74
                    const keyTreePtr = pipeline.add(0x74).readPointer();
                    console.log(`  key_tree_ptr: ${keyTreePtr}`);

                    // Scheme at pipeline+0x9c
                    const scheme = pipeline.add(0x9c).readS32();
                    console.log(`  scheme: ${scheme}`);
                } catch (e) {
                    console.log(`  (read error: ${e.message})`);
                }
            },
            onLeave: function (ret) {
                console.log(`  decrypt_handler returned`);
            },
        });
        console.log(`[+] Hooked decrypt_handler at ${decryptHandler}`);
    } catch (e) {
        console.log(`[-] decrypt_handler hook failed: ${e}`);
    }

    // ── Pipeline Process (0x10bfd3e) ──
    // Contains "sample decryption failed" — the main pipeline entry point.
    // This processes each audio sample.
    try {
        const pipelineProcess = base.add(offsets.pipeline_process);
        Interceptor.attach(pipelineProcess, {
            onEnter: function (args) {
                // This fires for EVERY sample — log sparingly
                this.entered = true;
            },
            onLeave: function (ret) {
                // Only log first few to avoid flood
                if (this.entered && !installX86Hooks._pipelineSeen) {
                    installX86Hooks._pipelineSeen = true;
                    console.log(`[${timestamp()}] pipeline_process called (first time). Decryption is active!`);
                    console.log("  (Suppressing further pipeline_process logs to avoid flood)");
                }
            },
        });
        console.log(`[+] Hooked pipeline_process at ${pipelineProcess}`);
    } catch (e) {
        console.log(`[-] pipeline_process hook failed: ${e}`);
    }

    // ── Key Tree Lookup (0x12fcfb6) ──
    // Called from decrypt_handler to fetch the key for a given key_id.
    // Returns key data from tree node.
    try {
        const keyLookup = base.add(offsets.key_tree_lookup);
        Interceptor.attach(keyLookup, {
            onEnter: function (args) {
                // ecx=output_buf, edx=tree_root
                this.outBuf = this.context.ecx;
                this.treeRoot = this.context.edx;
                console.log(`\n┌─ KEY_TREE_LOOKUP ──────────────────────────────────────┐`);
                console.log(`[${timestamp()}] key_tree_lookup`);
                console.log(`  output_buf: ${this.outBuf}  tree_root: ${this.treeRoot}`);
            },
            onLeave: function (ret) {
                // After return, output_buf should contain the key material
                try {
                    // Key data at output+0x00 (8 bytes), more at output+0x08
                    const keyData = readNativeBytes(this.outBuf, 16);
                    console.log(`  KEY DATA: ${keyData}`);
                } catch (e) {
                    console.log(`  (could not read key: ${e.message})`);
                }
                console.log(`└────────────────────────────────────────────────────────┘\n`);
            },
        });
        console.log(`[+] Hooked key_tree_lookup at ${keyLookup}`);
    } catch (e) {
        console.log(`[-] key_tree_lookup hook failed: ${e}`);
    }

    // ── Key Tree Region (0x16cea0d) ──
    // This is the key tree insert function. Called when new keys are derived.
    try {
        const keyTreeRegion = base.add(offsets.key_tree_region);
        Interceptor.attach(keyTreeRegion, {
            onEnter: function (args) {
                console.log(`\n╔══════════════════════════════════════════════════════════╗`);
                console.log(`║  KEY_TREE_INSERT — new key being stored!                ║`);
                console.log(`╚══════════════════════════════════════════════════════════╝`);
                console.log(`[${timestamp()}] key_tree_insert called`);

                // Print native backtrace to find what triggered key derivation
                console.log("  Backtrace:");
                const bt = Thread.backtrace(this.context, Backtracer.FUZZY);
                for (let i = 0; i < Math.min(bt.length, 12); i++) {
                    const offset = bt[i].sub(base);
                    console.log(`    [${i}] ${offset}`);
                }
            },
            onLeave: function (ret) {
                console.log(`  key_tree_insert returned\n`);
            },
        });
        console.log(`[+] Hooked key_tree_insert at ${keyTreeRegion}`);
    } catch (e) {
        console.log(`[-] key_tree_insert hook failed: ${e}`);
    }

    // ── DRM Setup (0x9cee4c) ──
    // "cpp-audio-drm_setup_impl" — called once during initialization
    try {
        const drmSetup = base.add(offsets.drm_setup);
        Interceptor.attach(drmSetup, {
            onEnter: function (args) {
                console.log(`\n[${timestamp()}] DRM_SETUP (cpp-audio-drm_setup_impl) called`);
                console.log("  Backtrace:");
                const bt = Thread.backtrace(this.context, Backtracer.FUZZY);
                for (let i = 0; i < Math.min(bt.length, 8); i++) {
                    console.log(`    [${i}] ${bt[i].sub(base)}`);
                }
            },
        });
        console.log(`[+] Hooked drm_setup at ${drmSetup}`);
    } catch (e) {
        console.log(`[-] drm_setup hook failed: ${e}`);
    }
}

// ── x86_64 hooks (original) ──

function installX86_64Hooks(mod, base, offsets) {
    // x86_64 hooks — for static analysis binary or 64-bit emulator
    try {
        Interceptor.attach(base.add(offsets.key_tree_insert), {
            onEnter: function (args) {
                console.log(`\n[${timestamp()}] key_tree_insert (x64)`);
                console.log(`  arg0: ${args[0]}  arg4(pipeline): ${args[4]}`);
                try {
                    const keyId = args[0].add(0x10).readU32();
                    const scheme = args[0].add(0x20).readU32();
                    console.log(`  key_id: ${keyId}  scheme: ${scheme}`);
                } catch (e) {}
            },
        });
        console.log(`[+] Hooked key_tree_insert`);
    } catch (e) { console.log(`[-] key_tree_insert: ${e}`); }

    try {
        Interceptor.attach(base.add(offsets.decrypt_sample), {
            onEnter: function (args) {
                this.buf = args[1]; this.size = args[2].toInt32();
                const scheme = args[0].readU32();
                console.log(`[${timestamp()}] decrypt_sample: scheme=${scheme} size=${this.size}`);
                if (this.size > 0) console.log(`  encrypted: ${readNativeBytes(this.buf, Math.min(this.size, 32))}`);
            },
            onLeave: function (ret) {
                if (this.size > 0) console.log(`  decrypted: ${readNativeBytes(this.buf, Math.min(this.size, 32))}`);
            },
        });
        console.log(`[+] Hooked decrypt_sample`);
    } catch (e) { console.log(`[-] decrypt_sample: ${e}`); }

    try {
        Interceptor.attach(base.add(offsets.hkdf_jni_wrapper), {
            onEnter: function (args) {
                console.log(`[${timestamp()}] hkdf_jni_wrapper (native)`);
                console.log("  Backtrace:");
                const bt = Thread.backtrace(this.context, Backtracer.ACCURATE);
                for (let i = 0; i < Math.min(bt.length, 12); i++) {
                    console.log(`    [${i}] ${bt[i].sub(base)}`);
                }
            },
        });
        console.log(`[+] Hooked hkdf_jni_wrapper`);
    } catch (e) { console.log(`[-] hkdf_jni_wrapper: ${e}`); }
}

// ─── Memory Scanner — Find RB-Tree Nodes After Key Insert ────────────────────

function scanKeyTree(pipelinePtr) {
    // Pipeline+0xd8 is the key tree root.
    // Each node: +0x20=key_id(u32), +0x28=aes_key(16 bytes)
    // This is for manual investigation — call from Frida REPL:
    //   scanKeyTree(ptr("0x..."))
    if (!pipelinePtr) {
        console.log("Usage: scanKeyTree(ptr('0xADDRESS_OF_PIPELINE'))");
        return;
    }
    try {
        const treeRoot = pipelinePtr.add(0xd8).readPointer();
        console.log(`Key tree root: ${treeRoot}`);
        walkRBTree(treeRoot, 0);
    } catch (e) {
        console.log(`Error scanning key tree: ${e}`);
    }
}

function walkRBTree(node, depth) {
    if (node.isNull()) return;
    if (depth > 20) return; // safety limit

    const indent = "  ".repeat(depth);
    try {
        const left = node.readPointer();          // +0x00
        const right = node.add(0x08).readPointer(); // +0x08
        const parent = node.add(0x10).readPointer(); // +0x10
        const color = node.add(0x18).readU8();     // +0x18 (red=0/black=1)
        const keyId = node.add(0x20).readU32();    // +0x20
        const aesKey = readNativeBytes(node.add(0x28), 16); // +0x28

        console.log(`${indent}Node ${node}: key_id=${keyId} color=${color === 0 ? "RED" : "BLK"}`);
        console.log(`${indent}  AES key: ${aesKey}`);

        walkRBTree(left, depth + 1);
        walkRBTree(right, depth + 1);
    } catch (e) {
        console.log(`${indent}Node ${node}: (unreadable: ${e})`);
    }
}

// Export for REPL use
globalThis.scanKeyTree = scanKeyTree;

// ─── Bonus: Hook ExoPlayer MediaDrm if Widevine is used ─────────────────────

function hookWidevine() {
    Java.perform(function () {
        try {
            const MediaDrm = Java.use("android.media.MediaDrm");

            MediaDrm.getKeyRequest.overload(
                "[B", "[B", "java.lang.String", "int", "java.util.HashMap"
            ).implementation = function (scope, init, mime, keyType, optParams) {
                console.log("\n┌─ MediaDrm.getKeyRequest ────────────────────────────────┐");
                console.log(`  mime: ${mime}  keyType: ${keyType}`);
                if (scope) console.log(`  scope (${scope.length} bytes): ${javaByteArrayToHex(scope)}`);
                if (init) console.log(`  init  (${init.length} bytes): ${javaByteArrayToHex(init)}`);
                console.log("└──────────────────────────────────────────────────────────┘\n");
                return this.getKeyRequest(scope, init, mime, keyType, optParams);
            };

            MediaDrm.provideKeyResponse.overload("[B", "[B").implementation = function (scope, response) {
                console.log("\n┌─ MediaDrm.provideKeyResponse ───────────────────────────┐");
                console.log(`  scope    (${scope.length} bytes): ${javaByteArrayToHex(scope)}`);
                console.log(`  response (${response.length} bytes): ${javaByteArrayToHex(response)}`);
                console.log("└──────────────────────────────────────────────────────────┘\n");
                return this.provideKeyResponse(scope, response);
            };

            console.log("[+] MediaDrm (Widevine) hooks installed");
        } catch (e) {
            console.log("[*] MediaDrm hooks skipped (not loaded or N/A)");
        }
    });
}

// ─── Bonus: Hook OkHttp to catch PlayPlay requests ──────────────────────────

function hookPlayPlayHttp() {
    Java.perform(function () {
        try {
            // Hook the HTTP client to find PlayPlay / decipher-proxy requests
            const OkHttpClient = Java.use("okhttp3.OkHttpClient");
            const Request = Java.use("okhttp3.Request");
            const RealCall = Java.use("okhttp3.RealCall");

            RealCall.getResponseWithInterceptorChain.implementation = function () {
                const req = this.originalRequest.value;
                const url = req.url().toString();

                // Filter for DRM-related endpoints
                if (url.indexOf("decipher") !== -1 ||
                    url.indexOf("playplay") !== -1 ||
                    url.indexOf("license") !== -1 ||
                    url.indexOf("key") !== -1 ||
                    url.indexOf("drm") !== -1 ||
                    url.indexOf("storage-resolve") !== -1) {

                    console.log("\n┌─ HTTP Request (DRM-related) ────────────────────────────┐");
                    console.log(`  URL: ${url}`);
                    console.log(`  Method: ${req.method()}`);

                    const body = req.body();
                    if (body) {
                        try {
                            const Buffer = Java.use("okio.Buffer");
                            const buf = Buffer.$new();
                            body.writeTo(buf);
                            const bodyBytes = buf.readByteArray();
                            console.log(`  Body (${bodyBytes.length} bytes): ${javaByteArrayToHex(bodyBytes)}`);
                        } catch (e) {
                            console.log(`  Body: (could not read: ${e})`);
                        }
                    }
                    console.log("└──────────────────────────────────────────────────────────┘");
                }

                return this.getResponseWithInterceptorChain();
            };

            console.log("[+] OkHttp DRM endpoint hooks installed");
        } catch (e) {
            console.log(`[*] OkHttp hooks skipped: ${e.message}`);
        }
    });
}

// ─── Main Entry ──────────────────────────────────────────────────────────────

console.log("╔══════════════════════════════════════════════════════════╗");
console.log("║  Spotify Key Intercept v2.0                             ║");
console.log("║  Java + Native + HTTP hooks                             ║");
console.log("╚══════════════════════════════════════════════════════════╝");

// Java hooks — always install, arch-independent
hookJavaCrypto();
hookWidevine();
hookPlayPlayHttp();

// Native hooks — only if enabled and arch matches
hookNative();

console.log("\n[*] All hooks installed. Play a track to trigger key derivation.");
console.log("[*] REPL: call scanKeyTree(ptr('0x...')) to dump cached keys.\n");
