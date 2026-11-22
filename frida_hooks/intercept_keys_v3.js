// Spotify Audio Decryption Key Interceptor v10
// Target: liborbit-jni-spotify.so (x86 32-bit)
//
// Architecture discovered:
//   1. SHA-1 hashes the playplay response/token to derive key material
//   2. Custom NLFSR stream cipher initialized with key material
//   3. Audio data XORed byte-by-byte with cipher keystream
//
// Key functions:
//   0x1680b2e = Cipher INIT (Fibonacci + magic 0x6996c53a)
//   0x1680cad = Cipher round (XOR+ROL inner)
//   0x1680d43 = Cipher full permutation
//   0x168138b = Cipher output / keystream step
//   0x16813db = Cipher encrypt/decrypt bytes
//   0xba2ba2  = Key setup function (calls INIT twice)
//   0xba4ade  = Stream decrypt (XOR loop + cipher output)
//   0x167f28c = SHA-1 init
//   0x167f2e4 = SHA-1 transform
//   0x1680966 = Some crypto setup called from key setup

"use strict";

var lib = null;
var base = null;
var hookCount = 0;
var MAX_LOGS = 200;

function hexdump16(ptr) {
    var out = "";
    for (var i = 0; i < 16; i++) {
        var b = ptr.add(i).readU8();
        out += (b < 16 ? "0" : "") + b.toString(16) + " ";
    }
    return out.trim();
}

function hexdumpN(ptr, n) {
    var out = "";
    for (var i = 0; i < n; i++) {
        var b = ptr.add(i).readU8();
        out += (b < 16 ? "0" : "") + b.toString(16) + " ";
        if ((i + 1) % 16 === 0 && i + 1 < n) out += "\n    ";
    }
    return out.trim();
}

function safeRead(ptr, n) {
    try {
        return hexdumpN(ptr, n);
    } catch (e) {
        return "<unreadable: " + e.message + ">";
    }
}

function tryReadPtr(ptr, offset) {
    try {
        return ptr.add(offset).readPointer();
    } catch (e) {
        return null;
    }
}

function installHooks() {
    console.log("[v10] Installing hooks on base: " + base);

    // ===== HOOK 1: KEY SETUP (0xba2ba2) =====
    // This is the function that sets up the cipher from key material
    // It calls INIT twice (at ba2e6f and ba2e89)
    // ecx = input object with key data at various offsets
    var keySetup = base.add(0xba2ba2);
    Interceptor.attach(keySetup, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            this.entryEcx = this.context.ecx;
            this.entryEdx = this.context.edx;
            this.entryEsi = this.context.esi;

            console.log("\n[KEY_SETUP] ==================================");
            console.log("[KEY_SETUP] ecx (this): " + this.context.ecx);
            console.log("[KEY_SETUP] edx: " + this.context.edx);
            console.log("[KEY_SETUP] esi: " + this.context.esi);

            // Try to read key material from the input object
            var ecx = this.context.ecx;
            try {
                console.log("[KEY_SETUP] [ecx+0x00..0x03] (flags): " + safeRead(ecx, 4));
                console.log("[KEY_SETUP] [ecx+0x10..0x23] (key?):  " + safeRead(ecx.add(0x10), 20));
                console.log("[KEY_SETUP] [ecx+0x24..0x37] (hash?): " + safeRead(ecx.add(0x24), 20));
            } catch (e) {}

            // esi holds a pointer used for key data
            var esi = this.context.esi;
            try {
                console.log("[KEY_SETUP] esi data: " + safeRead(esi, 32));
                console.log("[KEY_SETUP] [esi+0x10]: " + safeRead(esi.add(0x10), 16));
            } catch (e) {}
        },
        onLeave: function (retval) {
            if (hookCount >= MAX_LOGS + 1) return;
            console.log("[KEY_SETUP] returned");
        }
    });

    // ===== HOOK 2: CIPHER INIT (0x1680b2e) =====
    // ecx = cipher state object
    // edx = key data pointer
    // Initializes Fibonacci sequence, stores magic 0x6996c53a
    var cipherInit = base.add(0x1680b2e);
    Interceptor.attach(cipherInit, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            this.cipherState = this.context.ecx;
            this.keyData = this.context.edx;

            console.log("\n[CIPHER_INIT] ==============================");
            console.log("[CIPHER_INIT] ecx (cipher state): " + this.cipherState);
            console.log("[CIPHER_INIT] edx (key input):    " + this.keyData);

            // The key data fed into the cipher
            try {
                console.log("[CIPHER_INIT] key input (32 bytes): " + safeRead(this.keyData, 32));
                console.log("[CIPHER_INIT] key input (next 32):  " + safeRead(this.keyData.add(32), 32));
                console.log("[CIPHER_INIT] key input (next 32):  " + safeRead(this.keyData.add(64), 32));
            } catch (e) {}
        },
        onLeave: function (retval) {
            if (hookCount >= MAX_LOGS + 1) return;
            // After init, dump the cipher state
            try {
                var s = this.cipherState;
                console.log("[CIPHER_INIT] POST state[0x00-0x3f]: " + safeRead(s, 64));
                console.log("[CIPHER_INIT] POST state[0x80-0xbf]: " + safeRead(s.add(0x80), 64));
                console.log("[CIPHER_INIT] POST state[0xc0] (magic): " + safeRead(s.add(0xc0), 16));
            } catch (e) {}
        }
    });

    // ===== HOOK 3: STREAM DECRYPT (0xba4ade) =====
    // ecx = cipher context
    // edx = data pointer
    // [ebp+0x08] = length
    var streamDecrypt = base.add(0xba4ade);
    Interceptor.attach(streamDecrypt, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            this.ctx = this.context.ecx;
            this.dataPtr = this.context.edx;
            // Read length from stack [ebp+0x08]
            var ebp = this.context.ebp;
            try {
                this.len = ebp.add(0x08).readU32();
            } catch (e) {
                this.len = 0;
            }

            console.log("\n[STREAM_DECRYPT] ===========================");
            console.log("[STREAM_DECRYPT] ctx: " + this.ctx + " data: " + this.dataPtr + " len: " + this.len);

            // Dump first 32 bytes of encrypted data BEFORE decrypt
            if (this.len > 0) {
                var dumpLen = Math.min(this.len, 32);
                try {
                    console.log("[STREAM_DECRYPT] ENCRYPTED (first " + dumpLen + "): " + safeRead(this.dataPtr, dumpLen));
                } catch (e) {}
            }

            // Dump cipher state
            try {
                var ctx = this.ctx;
                console.log("[STREAM_DECRYPT] cipher[0x00-0x0f]: " + safeRead(ctx, 16));
                console.log("[STREAM_DECRYPT] cipher[0x40-0x4f]: " + safeRead(ctx.add(0x40), 16));
                console.log("[STREAM_DECRYPT] cipher[0xc0-0xcf]: " + safeRead(ctx.add(0xc0), 16));
                console.log("[STREAM_DECRYPT] cipher[0x100-0x10f]: " + safeRead(ctx.add(0x100), 16));
            } catch (e) {}
        },
        onLeave: function (retval) {
            if (hookCount >= MAX_LOGS + 1) return;
            // Dump first 32 bytes AFTER decrypt
            if (this.len > 0) {
                var dumpLen = Math.min(this.len, 32);
                try {
                    console.log("[STREAM_DECRYPT] DECRYPTED (first " + dumpLen + "): " + safeRead(this.dataPtr, dumpLen));
                } catch (e) {}
            }
        }
    });

    // ===== HOOK 4: SHA-1 INIT (0x167f28c) =====
    // Called to hash key material. ecx = SHA-1 context
    var sha1Init = base.add(0x167f28c);
    Interceptor.attach(sha1Init, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            this.sha1ctx = this.context.ecx;
            console.log("\n[SHA1_INIT] ecx: " + this.sha1ctx);
        },
        onLeave: function (retval) {
            if (hookCount >= MAX_LOGS + 1) return;
            // After init, the state has the IV
            try {
                console.log("[SHA1_INIT] POST IV: " + safeRead(this.sha1ctx, 32));
            } catch (e) {}
        }
    });

    // ===== HOOK 5: CIPHER ROUND (0x1680ba3) =====
    // Called with ecx = cipher state, [ebp+0x08] = round count
    // edx = data being mixed in
    var cipherRound = base.add(0x1680ba3);
    Interceptor.attach(cipherRound, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            var ebp = this.context.ebp;
            var roundCount = 0;
            try {
                roundCount = ebp.add(0x08).readU32();
            } catch (e) {}
            console.log("[CIPHER_ROUND] ecx: " + this.context.ecx +
                       " edx (data): " + this.context.edx +
                       " rounds: " + roundCount);
            try {
                console.log("[CIPHER_ROUND] data in: " + safeRead(this.context.edx, 32));
            } catch (e) {}
        }
    });

    // ===== HOOK 6: KEYSTREAM OUTPUT XOR (0x16813db) =====
    // This is where individual bytes get XORed
    // ecx = cipher state, edx = data buffer, [ebp+0x08] = byte count
    var keystreamXor = base.add(0x16813db);
    Interceptor.attach(keystreamXor, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            this.ctx = this.context.ecx;
            this.buf = this.context.edx;
            var ebp = this.context.ebp;
            try {
                this.count = ebp.add(0x08).readU32();
            } catch (e) {
                this.count = 0;
            }

            if (this.count > 0 && this.count < 100000) {
                console.log("[KEYSTREAM_XOR] ctx: " + this.ctx +
                           " buf: " + this.buf +
                           " count: " + this.count);
                // Dump keystream state before XOR
                try {
                    console.log("[KEYSTREAM_XOR] cipher_c4: " + safeRead(this.ctx.add(0xc4), 4) +
                               " cipher_c8: " + safeRead(this.ctx.add(0xc8), 4) +
                               " cipher_cc: " + safeRead(this.ctx.add(0xcc), 4));
                } catch (e) {}
            }
        },
        onLeave: function (retval) {
            // After XOR, the data is decrypted in-place
        }
    });

    // ===== HOOK 7: CRYPTO SETUP (0x1680966) =====
    // Called from key setup at ba2e11 with edx=0x60 (96 bytes)
    var cryptoSetup = base.add(0x1680966);
    Interceptor.attach(cryptoSetup, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            console.log("\n[CRYPTO_SETUP] ecx: " + this.context.ecx +
                       " edx: " + this.context.edx +
                       " eax: " + this.context.eax);
            try {
                // ecx = destination cipher state, edx = size/count, eax = data ptr
                console.log("[CRYPTO_SETUP] data (32 bytes): " + safeRead(this.context.eax, 32));
                console.log("[CRYPTO_SETUP] ecx data:        " + safeRead(this.context.ecx, 32));
            } catch (e) {}
        }
    });

    // ===== HOOK 8: SHA-1 related calls from the cipher cluster =====
    // 0x1680794, 0x16808d5, 0x16808f0 call SHA1_INIT from within the cipher suite
    var sha1FromCipher = [0x1680794, 0x16808d5, 0x16808f0];
    for (var i = 0; i < sha1FromCipher.length; i++) {
        (function(addr, idx) {
            try {
                Interceptor.attach(base.add(addr), {
                    onEnter: function (args) {
                        if (hookCount >= MAX_LOGS) return;
                        // Just log that this specific SHA1 callsite was hit
                        console.log("[SHA1_CALL_" + idx + "] at 0x" + addr.toString(16) +
                                   " ecx: " + this.context.ecx);
                    }
                });
            } catch (e) {
                console.log("[!] Failed to hook SHA1 callsite 0x" + addr.toString(16) + ": " + e);
            }
        })(sha1FromCipher[i], i);
    }

    // ===== HOOK 9: 167503e and 1675120 — HMAC/Key derivation helpers =====
    // Called from key setup at ba2d31, ba2d40, ba2d58, ba2d89
    var hmacSetup = base.add(0x167503e);
    Interceptor.attach(hmacSetup, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            console.log("\n[HMAC_SETUP] ecx: " + this.context.ecx +
                       " edx (data): " + this.context.edx +
                       " esp[0] (len): 0x" + (this.context.esp.readU32()).toString(16));
            try {
                console.log("[HMAC_SETUP] data: " + safeRead(this.context.edx, 32));
            } catch (e) {}
        }
    });

    var hmacFinish = base.add(0x1675120);
    Interceptor.attach(hmacFinish, {
        onEnter: function (args) {
            if (hookCount >= MAX_LOGS) return;
            hookCount++;
            console.log("\n[HMAC_FINISH] ecx: " + this.context.ecx +
                       " edx (data): " + this.context.edx);
            try {
                console.log("[HMAC_FINISH] data: " + safeRead(this.context.edx, 32));
            } catch (e) {}
        }
    });

    console.log("[v10] All hooks installed successfully!");
    console.log("[v10] Waiting for audio playback...");
}

// Wait for library to load
function waitForLib() {
    var mod = Process.findModuleByName("liborbit-jni-spotify.so");
    if (mod) {
        lib = mod;
        base = mod.base;
        console.log("[v10] Found liborbit at " + base + " (size: " + mod.size + ")");
        installHooks();
        return true;
    }
    return false;
}

if (!waitForLib()) {
    console.log("[v10] Waiting for liborbit-jni-spotify.so to load...");
    var timer = setInterval(function() {
        if (waitForLib()) {
            clearInterval(timer);
        }
    }, 500);
}
