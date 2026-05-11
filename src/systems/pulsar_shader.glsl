// src/systems/pulsar_shader.glsl
// Fullscreen pulsating pulsar-star background.
// Draw on a plain rectangle each frame and send `time` + `resolution` uniforms.

uniform float time;
uniform vec2  resolution;
uniform vec2  worldOffset; // screen-space parallax shift; pass (0,0) for menus

// ── Utilities ──────────────────────────────────────────────────────────────────

float hash2(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

// One star-field layer: grid of random stars that twinkle.
float starLayer(vec2 uv, float scale, float speed) {
    vec2 grid = floor(uv * scale);
    vec2 cell = fract(uv * scale) - 0.5;
    float h   = hash2(grid);
    if (h < 0.38) return 0.0;                // ~62 % of cells contain a star
    float r   = h * 0.032 + 0.004;           // star radius in UV space
    float bri = h * 0.65 + 0.35;
    float twk = 0.65 + 0.35 * sin(time * speed * (h * 9.0 + 0.5) + h * 57.3);
    return smoothstep(r, r * 0.2, length(cell)) * bri * twk;
}

// ── Entry point ───────────────────────────────────────────────────────────────

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Center-origin, aspect-corrected UV — (0,0) is the screen centre.
    vec2 uv = texture_coords - 0.5;
    uv.x   *= resolution.x / resolution.y;

    // Parallax-shifted UV for stars (stars are "far away" so shift is tiny).
    vec2 starUV = texture_coords + worldOffset * 0.025;

    float dist  = length(uv);
    float angle = atan(uv.y, uv.x);

    // ── Star field ────────────────────────────────────────────────────────
    float stars = 0.0;
    stars += starLayer(starUV,                              44.0, 0.9);
    stars += starLayer(starUV * 1.4 + vec2(0.17, 0.43),    29.0, 0.6)  * 0.55;
    stars += starLayer(starUV * 0.75 + vec2(0.61, 0.29),   18.0, 1.3)  * 0.75;

    // ── Pulsating rings ───────────────────────────────────────────────────
    // Five rings expand radially; each ring is a Gaussian bump on the
    // fractional part of (dist * freq - time * speed), giving the
    // impression of continuous waves flowing outward from the core.
    float rings    = 0.0;
    float ringMask = exp(-dist * 2.6);     // rings fade near the screen edge

    for (int i = 0; i < 5; i++) {
        float fi   = float(i);
        float t    = fract(dist * 4.2 - time * 1.1 + fi * 0.78);
        rings     += exp(-t * t * 26.0) * (1.0 - fi * 0.16);
    }
    rings *= ringMask;

    // A slow, broad shockwave for depth variation.
    float swT   = fract(dist * 2.0 - time * 0.42);
    float shock = exp(-swT * swT * 16.0) * exp(-dist * 1.7) * 0.32;

    // ── Pulsar jets ───────────────────────────────────────────────────────
    // Two pairs of perpendicular beams that pulse on and off.
    float pulse   = pow(max(0.0, sin(time * 5.5)), 2.5);
    float jetFade = exp(-dist * 2.1);
    float jetA    = pow(max(0.0, abs(cos(angle))), 14.0) * jetFade;
    float jetB    = pow(max(0.0, abs(sin(angle))), 14.0) * jetFade;
    // Diagonal secondary jets, subtler.
    float jetC    = pow(max(0.0, abs(cos(angle + 0.7854))), 22.0)
                  * exp(-dist * 2.8) * 0.28;
    float jets    = (jetA + jetB) * pulse + jetC * pulse;

    // ── Nebula wisps ──────────────────────────────────────────────────────
    float neb = sin(angle * 5.0 + dist * 7.0 - time * 0.35) * 0.5 + 0.5;
    neb      *= sin(angle * 3.0 - dist * 4.5 + time * 0.22) * 0.5 + 0.5;
    neb      *= exp(-dist * 1.9) * 0.11;

    // ── Core glow ─────────────────────────────────────────────────────────
    float corePulse = 0.72 + 0.28 * sin(time * 8.5);
    float core      = exp(-dist * dist * 52.0) * corePulse;
    float corona    = exp(-dist * 4.2) * 0.30 * (0.55 + 0.45 * sin(time * 2.9));

    // ── Colour composition ────────────────────────────────────────────────
    vec3 col = vec3(0.0, 0.005, 0.018);                     // deep space

    col += stars  * vec3(0.50, 0.62, 0.92);                 // cool white-blue stars
    col += rings  * vec3(0.00, 0.42, 1.00) * 0.72;          // electric-blue rings
    col += shock  * vec3(0.00, 0.28, 0.82);                  // shockwave
    col += jets   * vec3(0.25, 0.62, 1.00);                  // bright jets
    col += neb    * vec3(0.18, 0.12, 0.50);                  // purple-blue nebula
    col += corona * vec3(0.04, 0.18, 0.52);                  // soft corona halo
    col += core   * vec3(0.65, 0.84, 1.00);                  // white-hot pulsar core

    return vec4(col, 1.0);
}
