"use strict";

/**
 * Validate x86 offsets at runtime.
 * This script:
 *  1. Waits for liborbit-jni-spotify.so to load
 *  2. Reads prologue bytes at each offset to verify they match
 *  3. Installs a minimal interceptor on each to prove it fires
 *  4. Hooks dlsym/dlopen to watch library loading
 */

const LIB = "liborbit-jni-spotify.so";

const OFFSETS = {
    decrypt_handler:  0x10c08d0,
    pipeline_process: 0x10bfd3e,
    key_tree_region:  0x16cea0d,
    key_tree_lookup:  0x12fcfb6,
    drm_setup:        0x9cee4c,
};

// Expected first 4 bytes at each offset (from static analysis)
const EXPECTED_PROLOGUE = [0x55, 0x89, 0xe5, 0x53]; // push ebp; mov ebp,esp; push ebx

function hexBytes(ptr, n) {
    const buf = ptr.readByteArray(n);
    if (!buf) return "(unreadable)";
    const arr = new Uint8Array(buf);
    return Array.from(arr).map(b => ("0" + b.toString(16)).slice(-2)).join(" ");
}

function tryAttach(name, addr) {
    try {
        Interceptor.attach(addr, {
            onEnter: function () {
                console.log(`>>> ${name} FIRED at ${addr}`);
                // Print a compact backtrace
                const bt = Thread.backtrace(this.context, Backtracer.FUZZY);
                if (bt.length > 0) {
                    const mod = Process.findModuleByName(LIB);
                    const base = mod ? mod.base : ptr(0);
                    for (let i = 0; i < Math.min(bt.length, 6); i++) {
                        const off = mod ? bt[i].sub(base) : bt[i];
                        console.log(`    [${i}] ${off}`);
                    }
                }
            }
        });
        console.log(`  [+] Interceptor attached: ${name}`);
        return true;
    } catch (e) {
        console.log(`  [-] Interceptor FAILED for ${name}: ${e.message}`);
        return false;
    }
}

function validateAndHook() {
    const mod = Process.findModuleByName(LIB);
    if (!mod) {
        console.log(`[-] ${LIB} not found. Loaded modules:`);
        Process.enumerateModules().forEach(function (m) {
            if (m.name.indexOf("orbit") !== -1 || m.name.indexOf("spotify") !== -1) {
                console.log(`    ${m.name} base=${m.base} size=${m.size}`);
            }
        });
        return false;
    }

    console.log(`\n[+] Found ${LIB}`);
    console.log(`    base: ${mod.base}`);
    console.log(`    size: 0x${mod.size.toString(16)}`);

    // Verify each offset
    let allOk = true;
    for (const [name, offset] of Object.entries(OFFSETS)) {
        const addr = mod.base.add(offset);
        const actual = hexBytes(addr, 8);
        const matches = EXPECTED_PROLOGUE.every(function (b, i) {
            return addr.add(i).readU8() === b;
        });

        const status = matches ? "OK" : "MISMATCH";
        console.log(`  ${name}: ${addr} -> ${actual}  [${status}]`);

        if (!matches) allOk = false;
    }

    if (!allOk) {
        console.log("\n[!] Some offsets don't match expected prologues.");
        console.log("    The binary may be a different version.");
    }

    // Attach interceptors
    console.log("\n[*] Attaching interceptors...");
    for (const [name, offset] of Object.entries(OFFSETS)) {
        const addr = mod.base.add(offset);
        tryAttach(name, addr);
    }

    // Also hook a few known libc/libdl functions to prove Frida works
    console.log("\n[*] Sanity check: hooking malloc to prove Frida interceptor works...");
    const mallocAddr = Module.findExportByName("libc.so", "malloc");
    if (mallocAddr) {
        let mallocCount = 0;
        Interceptor.attach(mallocAddr, {
            onEnter: function (args) {
                mallocCount++;
                if (mallocCount <= 3) {
                    console.log(`  malloc(${args[0]}) called (count=${mallocCount})`);
                }
                if (mallocCount === 3) {
                    console.log("  (suppressing further malloc logs)");
                }
            }
        });
        console.log("  [+] malloc hook installed");
    }

    return true;
}

// ── Enumerate ALL spotify/orbit modules ──
console.log("╔══════════════════════════════════════════════════════════╗");
console.log("║  Offset Validator & Minimal Hook Test                   ║");
console.log("╚══════════════════════════════════════════════════════════╝");

console.log("\n[*] All loaded modules matching 'orbit' or 'spotify':");
Process.enumerateModules().forEach(function (m) {
    if (m.name.indexOf("orbit") !== -1 || m.name.indexOf("spotify") !== -1 || m.name.indexOf("jni") !== -1) {
        console.log(`    ${m.name}  base=${m.base}  size=0x${m.size.toString(16)}`);
    }
});

// Try immediate
if (!validateAndHook()) {
    console.log("\n[*] Library not loaded yet. Setting up dlopen monitor...");

    // Watch for library loading via linker namespace
    const dlopen = Module.findExportByName(null, "dlopen");
    const android_dlopen_ext = Module.findExportByName(null, "android_dlopen_ext");

    function watchDlopen(funcAddr, funcName) {
        if (!funcAddr) return;
        try {
            Interceptor.attach(funcAddr, {
                onEnter: function (args) {
                    const path = args[0].readCString();
                    if (path && path.indexOf("orbit") !== -1) {
                        console.log(`\n[*] ${funcName}("${path}") detected!`);
                        this.isTarget = true;
                    }
                },
                onLeave: function (ret) {
                    if (this.isTarget) {
                        console.log(`[*] Library loaded, handle=${ret}. Validating offsets...`);
                        setTimeout(validateAndHook, 500);
                    }
                }
            });
            console.log(`  [+] Watching ${funcName} at ${funcAddr}`);
        } catch (e) {
            console.log(`  [-] Cannot watch ${funcName}: ${e.message}`);
        }
    }

    watchDlopen(dlopen, "dlopen");
    watchDlopen(android_dlopen_ext, "android_dlopen_ext");
}

console.log("\n[*] Ready. Play a track and watch for '>>>' lines.");
console.log("[*] If nothing fires in 30s, the offsets may be wrong for this APK version.\n");
