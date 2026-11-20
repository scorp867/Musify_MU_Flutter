/**
 * Diagnostic: find what crypto path Spotify actually uses at runtime.
 *
 * Usage: frida -U -f com.spotify.music -l diagnose_crypto.js --no-pause
 */

"use strict";

// ─── 1. Enumerate all crypto-related classes ────────────────────────────────

function enumCryptoClasses() {
    Java.perform(function () {
        console.log("\n=== Loaded classes matching crypto/decipher/drm ===");
        const found = [];
        Java.enumerateLoadedClasses({
            onMatch: function (name) {
                const lower = name.toLowerCase();
                if (lower.indexOf("crypto") !== -1 ||
                    lower.indexOf("decipher") !== -1 ||
                    lower.indexOf("cipher") !== -1 ||
                    lower.indexOf("hkdf") !== -1 ||
                    lower.indexOf("hmac") !== -1 ||
                    lower.indexOf("playplay") !== -1 ||
                    (lower.indexOf("drm") !== -1 && lower.indexOf("android") === -1)) {
                    found.push(name);
                }
            },
            onComplete: function () {
                found.sort();
                found.forEach(function (c) { console.log("  " + c); });
                console.log(`\n  Total: ${found.length} classes\n`);
            }
        });
    });
}

// ─── 2. Inspect NativeCryptoProvider: does it exist? what methods? ───────────

function inspectNCP() {
    Java.perform(function () {
        console.log("\n=== NativeCryptoProvider inspection ===");
        try {
            const NCP = Java.use("com.spotify.native_crypto.NativeCryptoProvider");
            console.log("[+] Class found: com.spotify.native_crypto.NativeCryptoProvider");

            // List all declared methods
            const methods = NCP.class.getDeclaredMethods();
            console.log(`  Methods (${methods.length}):`);
            for (let i = 0; i < methods.length; i++) {
                console.log(`    ${methods[i].toString()}`);
            }

            // Check if any instances exist
            Java.choose("com.spotify.native_crypto.NativeCryptoProvider", {
                onMatch: function (instance) {
                    console.log(`  [!] Live instance found: ${instance}`);
                    console.log(`      class: ${instance.getClass().getName()}`);
                },
                onComplete: function () {
                    console.log("  Instance scan complete.");
                }
            });
        } catch (e) {
            console.log(`[-] NativeCryptoProvider NOT found: ${e.message}`);

            // Search for anything with "CryptoProvider" in the name
            console.log("  Searching for *CryptoProvider* classes...");
            Java.enumerateLoadedClasses({
                onMatch: function (name) {
                    if (name.toLowerCase().indexOf("cryptoprovider") !== -1) {
                        console.log(`    ${name}`);
                    }
                },
                onComplete: function () {}
            });
        }
    });
}

// ─── 3. Hook ALL Java crypto (JCE layer) ────────────────────────────────────
//    If hkdfSha512 uses hmacSha512 which uses javax.crypto.Mac internally,
//    we catch it here regardless of which class calls it.

function hookJCE() {
    Java.perform(function () {
        console.log("\n=== Hooking javax.crypto (JCE) ===");

        // javax.crypto.Mac — catches ALL HMAC operations
        try {
            const Mac = Java.use("javax.crypto.Mac");
            Mac.doFinal.overload("[B").implementation = function (input) {
                const result = this.doFinal(input);
                const algo = this.getAlgorithm();
                console.log(`\n[MAC] ${algo} doFinal(${input.length}B) -> ${result.length}B`);
                if (algo.indexOf("512") !== -1 || algo.indexOf("SHA512") !== -1) {
                    console.log(`  input:  ${bytesToHex(input, 48)}`);
                    console.log(`  output: ${bytesToHex(result, 48)}`);
                    printJavaTrace();
                }
                return result;
            };

            Mac.doFinal.overload().implementation = function () {
                const result = this.doFinal();
                const algo = this.getAlgorithm();
                console.log(`\n[MAC] ${algo} doFinal() -> ${result.length}B`);
                if (algo.indexOf("512") !== -1) {
                    console.log(`  output: ${bytesToHex(result, 48)}`);
                    printJavaTrace();
                }
                return result;
            };
            console.log("[+] javax.crypto.Mac.doFinal hooked");
        } catch (e) {
            console.log(`[-] Mac hook failed: ${e.message}`);
        }

        // javax.crypto.Cipher — catches ALL AES/ChaCha operations
        try {
            const Cipher = Java.use("javax.crypto.Cipher");
            Cipher.doFinal.overload("[B").implementation = function (input) {
                const result = this.doFinal(input);
                const algo = this.getAlgorithm();
                console.log(`\n[CIPHER] ${algo} doFinal(${input.length}B) -> ${result.length}B`);
                if (input.length < 256) {
                    console.log(`  input:  ${bytesToHex(input, 48)}`);
                    console.log(`  output: ${bytesToHex(result, 48)}`);
                }
                printJavaTrace();
                return result;
            };
            console.log("[+] javax.crypto.Cipher.doFinal hooked");
        } catch (e) {
            console.log(`[-] Cipher hook failed: ${e.message}`);
        }

        // SecretKeySpec — catches ALL symmetric key creation
        try {
            const SKS = Java.use("javax.crypto.spec.SecretKeySpec");
            SKS.$init.overload("[B", "java.lang.String").implementation = function (key, algo) {
                console.log(`\n[KEY] SecretKeySpec(${algo}, ${key.length}B): ${bytesToHex(key, 48)}`);
                if (algo.indexOf("AES") !== -1 || algo.indexOf("HmacSHA") !== -1) {
                    printJavaTrace();
                }
                return this.$init(key, algo);
            };
            console.log("[+] javax.crypto.spec.SecretKeySpec hooked");
        } catch (e) {
            console.log(`[-] SecretKeySpec hook failed: ${e.message}`);
        }
    });
}

// ─── 4. Hook MediaDrm more aggressively ─────────────────────────────────────

function hookMediaDrmFull() {
    Java.perform(function () {
        console.log("\n=== Hooking MediaDrm (all overloads) ===");
        try {
            const MediaDrm = Java.use("android.media.MediaDrm");

            // Hook ALL overloads of getKeyRequest
            const overloads = MediaDrm.getKeyRequest.overloads;
            overloads.forEach(function (overload, idx) {
                overload.implementation = function () {
                    console.log(`\n[WIDEVINE] MediaDrm.getKeyRequest (overload ${idx}) called`);
                    for (let i = 0; i < arguments.length; i++) {
                        console.log(`  arg${i}: ${arguments[i]}`);
                    }
                    printJavaTrace();
                    return overload.apply(this, arguments);
                };
            });

            MediaDrm.provideKeyResponse.overload("[B", "[B").implementation = function (scope, resp) {
                console.log(`\n[WIDEVINE] provideKeyResponse`);
                console.log(`  scope: ${bytesToHex(scope, 32)}`);
                console.log(`  resp:  ${bytesToHex(resp, 64)}`);
                printJavaTrace();
                return this.provideKeyResponse(scope, resp);
            };

            // openSession
            const openOverloads = MediaDrm.openSession.overloads;
            openOverloads.forEach(function (overload, idx) {
                overload.implementation = function () {
                    const result = overload.apply(this, arguments);
                    console.log(`\n[WIDEVINE] openSession -> ${bytesToHex(result, 32)}`);
                    return result;
                };
            });

            console.log("[+] MediaDrm full hooks installed");
        } catch (e) {
            console.log(`[-] MediaDrm hooks failed: ${e.message}`);
        }

        // Also hook MediaCodec for crypto setup
        try {
            const MediaCodec = Java.use("android.media.MediaCodec");
            MediaCodec.configure.overload(
                "android.media.MediaFormat",
                "android.view.Surface",
                "android.media.MediaCrypto",
                "int"
            ).implementation = function (fmt, surface, crypto, flags) {
                console.log(`\n[CODEC] MediaCodec.configure`);
                console.log(`  format: ${fmt}`);
                console.log(`  crypto: ${crypto}`);
                console.log(`  flags:  ${flags}`);
                return this.configure(fmt, surface, crypto, flags);
            };
            console.log("[+] MediaCodec.configure hooked");
        } catch (e) {
            console.log(`[-] MediaCodec hook failed: ${e.message}`);
        }
    });
}

// ─── 5. Hook native JNI RegisterNatives to see what gets registered ─────────

function hookJNIRegister() {
    try {
        // Find art JNI exports for monitoring
        const libart = Process.findModuleByName("libart.so");
        if (libart) {
            const exports = libart.enumerateExports();
            const callObj = [];
            exports.forEach(function (exp) {
                if (exp.name.indexOf("CallObjectMethod") !== -1 &&
                    exp.name.indexOf("CheckJNI") === -1 &&
                    exp.type === "function") {
                    callObj.push(exp.name);
                }
            });
            if (callObj.length > 0) {
                console.log(`[+] Found ${callObj.length} CallObjectMethod variants in libart`);
            }
        }
    } catch (e) {
        console.log(`[*] JNI register hook skipped: ${e.message}`);
    }
}

// ─── 6. Monitor native lib loading ──────────────────────────────────────────

function hookDlopen() {
    try {
        const linker = Process.findModuleByName("linker") ||
                       Process.findModuleByName("linker64");
        if (!linker) {
            console.log("[*] dlopen monitor skipped (linker not found)");
            return;
        }
        // Use Process module load callback instead
        Process.setExceptionHandler(function () { return false; });
        console.log("[*] dlopen monitor skipped (non-critical)");
    } catch (e) {
        console.log("[*] dlopen monitor skipped");
    }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function bytesToHex(arr, max) {
    if (!arr) return "(null)";
    max = max || 48;
    const len = arr.length;
    const limit = Math.min(len, max);
    const hex = [];
    for (let i = 0; i < limit; i++) {
        hex.push(("0" + (arr[i] & 0xff).toString(16)).slice(-2));
    }
    let s = hex.join(" ");
    if (len > max) s += ` ... (${len}B total)`;
    return s;
}

function printJavaTrace() {
    const Exception = Java.use("java.lang.Exception");
    const Log = Java.use("android.util.Log");
    const trace = Log.getStackTraceString(Exception.$new());
    // Print only first 15 frames to keep output manageable
    const lines = trace.split("\n").slice(0, 15);
    console.log("  " + lines.join("\n  "));
}

// ─── Main ────────────────────────────────────────────────────────────────────

console.log("╔══════════════════════════════════════════════════════════╗");
console.log("║  Spotify Crypto Diagnostic v1.0                        ║");
console.log("╚══════════════════════════════════════════════════════════╝");

hookDlopen();
hookJCE();
hookMediaDrmFull();
inspectNCP();
hookJNIRegister();

// Delay class enum slightly so more classes are loaded
setTimeout(enumCryptoClasses, 5000);

console.log("\n[*] Diagnostics active. Play a song and watch for output.");
console.log("[*] If NOTHING fires, crypto is 100% native (no Java path).\n");
