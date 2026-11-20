"use strict";
/*  Spotify AES Key Interceptor v9
 *  ───────────────────────────────
 *  Hooks the orchestrator CALL SITE to capture ecx/edx (key material)
 *  right before b394ae is called with the counter block.
 *
 *  Also hooks b2b6a0 directly (called 2x from orchestrator) to dump
 *  all registers and find the actual AES key.
 *
 *  Target: liborbit-jni-spotify.so  x86 32-bit
 *  Run:    frida -U -f com.spotify.music -l intercept_keys_v3.js
 */

var LIB = "liborbit-jni-spotify.so";

/* ── offsets ── */
var ORCH_CALL     = 0x12f0571;   // mov ecx,[edi+0x39c] — right before b394ae call
var CIPHER_CMP    = 0xb394ae;    // the verify/compare wrapper
var B2B6A0        = 0xb2b6a0;    // inner cipher — called from b394ae AND orchestrator
var B23BD4        = 0xb23bd4;    // core function called from b2b6a0
var COUNTER_MGR   = 0x12ecf88;   // counter manager
var ORCH_DIRECT1  = 0x12eff6a;   // orchestrator direct call to b2b6a0
var ORCH_DIRECT2  = 0x12f0a32;   // orchestrator 2nd direct call to b2b6a0
var ORCHESTRATOR  = 0x12efe92;   // orchestrator entry

function hex(ptr, n) {
    var buf = ptr.readByteArray(n);
    if (!buf) return "(null)";
    return Array.from(new Uint8Array(buf))
        .map(function (b) { return ("0" + b.toString(16)).slice(-2); })
        .join(" ");
}

function hexBlock(ptr, total) {
    var lines = [];
    for (var i = 0; i < total; i += 16) {
        var row = Math.min(16, total - i);
        lines.push("  +" + ("000" + i.toString(16)).slice(-3) + ": " + hex(ptr.add(i), row));
    }
    return lines.join("\n");
}

function attach(m) {
    var base = m.base;
    console.log("[+] " + LIB + " base=" + base);

    var stats = { orch: 0, cmp: 0, b2b: 0, b23: 0, ctr: 0 };
    var dumpCount = { orch: 0, b2b: 0, b23: 0, ctr: 0 };
    var MAX_DUMPS = 3;

    /* ════════════════════════════════════════════════════════════
     *  1. Hook at 0x12f0571 — the mov ecx,[edi+0x39c] instruction
     *     At this point edi = the orchestrator's object ('this' eventually)
     *     We read [edi+0x39c] and [edi+0x3a0] which become ecx/edx
     *     for the b394ae call 0x2c bytes later.
     * ════════════════════════════════════════════════════════════ */
    Interceptor.attach(base.add(ORCH_CALL), {
        onEnter: function () {
            stats.orch++;
            if (dumpCount.orch >= MAX_DUMPS) return;
            dumpCount.orch++;

            var edi = this.context.edi;
            console.log("\n╔══════════════════════════════════════════════╗");
            console.log("║  ORCH_CALL #" + dumpCount.orch + "  edi=" + edi);
            console.log("╚══════════════════════════════════════════════╝");

            try {
                /* read the values that become ecx, edx, eax, esi for b394ae */
                var key_lo = edi.add(0x39c).readU32();
                var key_hi = edi.add(0x3a0).readU32();
                var arg3   = edi.add(0x3a4).readU32();
                var arg4   = edi.add(0x3a8).readU32();
                console.log("  [edi+0x39c] -> ecx = 0x" + key_lo.toString(16));
                console.log("  [edi+0x3a0] -> edx = 0x" + key_hi.toString(16));
                console.log("  [edi+0x3a4] -> eax = 0x" + arg3.toString(16));
                console.log("  [edi+0x3a8] -> esi = 0x" + arg4.toString(16));

                /* Dump surrounding area of edi for context */
                console.log("\n  edi object +0x380..0x3c0:");
                console.log(hexBlock(edi.add(0x380), 0x40));

                /* The key data might be a 64-bit value in ecx:edx */
                /* Or ecx might be a pointer to key material */
                if (key_lo > 0x10000) {
                    /* Looks like a pointer — try reading what it points to */
                    console.log("\n  *ecx (if pointer) first 64 bytes:");
                    try {
                        console.log(hexBlock(ptr(key_lo), 64));
                    } catch (e) {
                        console.log("  NOT A VALID POINTER");
                    }
                }

                /* Also read the counter/IV from [esp+0x60] area */
                /* The movaps loads from [esp+0x60] AFTER sub esp,0x20 */
                /* At this instruction, esp hasn't been adjusted yet */
                var esp = this.context.esp;
                console.log("\n  Counter area (esp+0x38..0x58):");
                console.log(hexBlock(esp.add(0x38), 0x20));
                console.log("  Counter area (esp+0x58..0x78):");
                console.log(hexBlock(esp.add(0x58), 0x20));

                /* Dump edi+0x480 area (had interesting data in v8) */
                console.log("\n  edi+0x480..0x500 (potential key area):");
                console.log(hexBlock(edi.add(0x480), 0x80));

                /* edi+0x4bc was compared in the code — check it */
                var val_4bc = edi.add(0x4bc).readU32();
                console.log("\n  [edi+0x4bc] = 0x" + val_4bc.toString(16));

            } catch (e) {
                console.log("  READ ERR: " + e);
            }
        }
    });

    /* ════════════════════════════════════════════════════════════
     *  2. Hook b2b6a0 — the inner cipher
     *     ecx = 'this' or key pointer
     *     edx = another key/param
     *     stack args: counter bytes
     * ════════════════════════════════════════════════════════════ */
    Interceptor.attach(base.add(B2B6A0), {
        onEnter: function () {
            stats.b2b++;
            if (dumpCount.b2b >= MAX_DUMPS) return;
            dumpCount.b2b++;

            var ecx = this.context.ecx;
            var edx = this.context.edx;
            var eax = this.context.eax;
            var esp = this.context.esp;

            console.log("\n[b2b6a0 #" + dumpCount.b2b + "] ecx=" + ecx + " edx=" + edx + " eax=" + eax);

            try {
                /* stack: [esp]=ret, [esp+4]=arg1, [esp+8]=arg2, ... */
                console.log("  ret   = " + esp.readPointer());
                console.log("  stack args:");
                for (var i = 4; i <= 0x20; i += 4) {
                    console.log("    [esp+0x" + i.toString(16) + "] = 0x" +
                        esp.add(i).readU32().toString(16));
                }

                /* ecx and edx likely contain key material or pointers */
                console.log("\n  ecx value = 0x" + ecx.toString(16));
                console.log("  edx value = 0x" + edx.toString(16));

                /* Try reading ecx as pointer */
                if (ecx.toInt32() > 0x10000 || ecx.toInt32() < -0x10000) {
                    console.log("  *ecx (64 bytes):");
                    try { console.log(hexBlock(ecx, 64)); }
                    catch (e) { console.log("    NOT READABLE"); }
                }

                /* Try reading edx as pointer */
                if (edx.toInt32() > 0x10000 || edx.toInt32() < -0x10000) {
                    console.log("  *edx (64 bytes):");
                    try { console.log(hexBlock(edx, 64)); }
                    catch (e) { console.log("    NOT READABLE"); }
                }

            } catch (e) {
                console.log("  ERR: " + e);
            }
        },
        onLeave: function (retval) {
            if (dumpCount.b2b <= MAX_DUMPS) {
                console.log("[b2b6a0] returned: " + retval);
            }
        }
    });

    /* ════════════════════════════════════════════════════════════
     *  3. Hook b23bd4 — the actual encrypt call
     *     This is called twice per b2b6a0 invocation.
     *     ecx = output buffer pointer
     *     edx = input/key pointer
     *     stack: more params
     * ════════════════════════════════════════════════════════════ */
    Interceptor.attach(base.add(B23BD4), {
        onEnter: function () {
            stats.b23++;
            if (dumpCount.b23 >= MAX_DUMPS * 2) return;
            dumpCount.b23++;

            var ecx = this.context.ecx;
            var edx = this.context.edx;
            var esp = this.context.esp;

            console.log("\n  [b23bd4 #" + dumpCount.b23 + "] ecx=" + ecx + " edx=" + edx);

            try {
                /* stack args */
                console.log("    ret = " + esp.readPointer());
                for (var i = 4; i <= 0x14; i += 4) {
                    console.log("    [esp+0x" + i.toString(16) + "] = 0x" +
                        esp.add(i).readU32().toString(16));
                }

                /* read *edx as the input data */
                if (edx.toInt32() > 0x10000 || edx.toInt32() < -0x10000) {
                    console.log("    *edx (32 bytes):");
                    try { console.log(hexBlock(edx, 32)); }
                    catch (e) { console.log("      NOT READABLE"); }
                }
            } catch (e) {
                console.log("    ERR: " + e);
            }

            this._ecx = ecx;
        },
        onLeave: function (retval) {
            if (dumpCount.b23 <= MAX_DUMPS * 2 && this._ecx) {
                /* dump output buffer */
                try {
                    console.log("  [b23bd4] output at " + this._ecx + ": " +
                        hex(this._ecx, 16));
                } catch (e) {}
            }
        }
    });

    /* ════════════════════════════════════════════════════════════
     *  4. Hook COUNTER_MGR (0x12ecf88)
     * ════════════════════════════════════════════════════════════ */
    Interceptor.attach(base.add(COUNTER_MGR), {
        onEnter: function () {
            stats.ctr++;
            if (dumpCount.ctr >= MAX_DUMPS) return;
            dumpCount.ctr++;

            var ecx = this.context.ecx;
            var edx = this.context.edx;
            console.log("\n[COUNTER_MGR #" + dumpCount.ctr + "] ecx=" + ecx + " edx=" + edx);

            try {
                var esp = this.context.esp;
                console.log("  stack[0..0x20]:");
                console.log(hexBlock(esp, 0x24));
            } catch (e) {}
        }
    });

    /* ════════════════════════════════════════════════════════════
     *  5. Also hook b394ae to track ecx/edx on ENTRY (preserved from caller)
     * ════════════════════════════════════════════════════════════ */
    var cmpDumps = 0;
    Interceptor.attach(base.add(CIPHER_CMP), {
        onEnter: function () {
            stats.cmp++;
            if (cmpDumps >= MAX_DUMPS) return;
            cmpDumps++;

            var ecx = this.context.ecx;
            var edx = this.context.edx;
            var esp = this.context.esp;

            console.log("\n[CIPHER_CMP #" + cmpDumps + "] ecx=" + ecx + " edx=" + edx);
            try {
                /* XMM data on stack */
                console.log("  stack counter: " + hex(esp.add(4), 16));
                console.log("  arg3=0x" + esp.add(0x14).readU32().toString(16) +
                    " arg4=0x" + esp.add(0x18).readU32().toString(16));
            } catch (e) {}
        }
    });

    /* ── stats ── */
    setInterval(function () {
        if (stats.orch + stats.cmp + stats.b2b > 0) {
            console.log("\n[STATS] orch_call=" + stats.orch +
                " cmp=" + stats.cmp +
                " b2b6a0=" + stats.b2b +
                " b23bd4=" + stats.b23 +
                " counter=" + stats.ctr);
        }
    }, 10000);

    console.log("[+] READY. Play a track.\n");
}

(function boot() {
    var m = Process.findModuleByName(LIB);
    if (m) { attach(m); return; }
    console.log("[*] " + LIB + " not loaded. Polling...");
    var t = setInterval(function () {
        var mod = Process.findModuleByName(LIB);
        if (mod) { clearInterval(t); attach(mod); }
    }, 500);
})();
