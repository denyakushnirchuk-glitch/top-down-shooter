// src/systems/bullet_shader.glsl
// Fragment shader for the laser bolt glow.
//
// Each bullet is drawn as a small rectangle (the canvas passed in).
// This shader runs once per pixel of that rectangle and computes:
//   1. A hard bright core along the bolt's long axis
//   2. A soft radial glow that falls off with distance from the centre
//   3. A slight colour shift from white-cyan core → deep cyan edge
//
// Uniforms set from Lua each draw call:
//   vec2  size      — pixel dimensions of the canvas (width, height)
//   vec4  coreColor — RGBA of the inner bright core
//   vec4  glowColor — RGBA of the outer glow tint
//   float glowPower — falloff exponent; higher = tighter glow (default 2.0)
//
// Love2D passes the canvas texture as `MainTex` automatically.
// VaryingTexCoord is the UV coordinate (0..1, 0..1) of the current pixel.

uniform vec2  size;
uniform vec4  coreColor;
uniform vec4  glowColor;
uniform float glowPower;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screenCoords)
{
    // Centre the UV so (0,0) is the middle of the canvas
    vec2 centred = uv - vec2(0.5, 0.5);

    // Aspect-correct distance along each axis.
    // `centred.x * (size.x / size.y)` stretches the X axis so the glow
    // is circular on-screen even though the canvas is rectangular.
    float aspect = size.x / size.y;
    float dx = centred.x * aspect;   // along bolt length
    float dy = centred.y;            // across bolt width

    // Radial distance from bolt centre line (just the Y component),
    // used for the cross-section glow.
    float radial = abs(dy);

    // Full distance from the very centre of the bolt.
    float dist = sqrt(dx * dx + dy * dy);

    // ── Core: a tight bright band along the bolt axis ─────────────────────
    // smoothstep gives a soft-edged band rather than a hard cutoff.
    float core = 1.0 - smoothstep(0.0, 0.18, radial);

    // ── Glow: radial falloff from centre ──────────────────────────────────
    // pow(1 - dist, glowPower): at dist=0 → 1.0 (full), at dist=0.5 → ~0
    float glow = pow(max(0.0, 1.0 - dist * 2.0), glowPower);

    // ── Combine ───────────────────────────────────────────────────────────
    vec4 result = mix(glowColor, coreColor, core) * max(core, glow);

    // Multiply by the Love2D sprite color (passed as `color`)
    return result * color;
}
