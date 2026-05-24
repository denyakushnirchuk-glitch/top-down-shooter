// src/systems/bullet_shader.glsl
// Fragment shader for the laser bolt glow.
// Love2D 11.x GLSL syntax (OpenGL ES 2 / GLSL 1.20 compatible).
//
// How it works:
//   The bolt canvas is a solid white rectangle.
//   This shader ignores the canvas pixel colour entirely and instead uses
//   the UV coordinate of each pixel to compute:
//     1. A tight bright CORE band along the bolt's long axis (the centre line)
//     2. A soft radial GLOW that falls off with distance from the centre
//   The two are blended together and tinted by coreColor / glowColor.
//   With blend mode "add" in Love2D, the result blooms against dark backgrounds.
//
// Uniforms:
//   vec2  size       — canvas pixel dimensions (set once at load)
//   vec4  coreColor  — inner bright colour (near-white cyan)
//   vec4  glowColor  — outer halo colour (deep cyan)
//   float glowPower  — glow falloff exponent; higher = tighter halo

uniform vec2  size;
uniform vec4  coreColor;
uniform vec4  glowColor;
uniform float glowPower;

// Love2D 11.x entry point.
// `texture` is the canvas being drawn; `texture_coords` is the UV (0..1).
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Remap UV from [0,1] to [-0.5, 0.5] so (0,0) is the bolt centre
    vec2 uv = texture_coords - vec2(0.5, 0.5);

    // Correct for aspect ratio so the glow is round, not squashed.
    // The bolt canvas is wider than tall (e.g. 48x24), so uv.x gets scaled
    // up to match the proportions, making equal distances equal on screen.
    float aspect = size.x / size.y;
    float ax = uv.x * aspect;   // aspect-corrected X (along bolt length)
    float ay = uv.y;            // Y stays as-is    (across bolt width)

    // Distance purely across the bolt width (ignores length).
    // This is what shapes the bright centre line.
    float crossDist = abs(ay);

    // Full distance from the very centre of the bolt.
    float fullDist = sqrt(ax * ax + ay * ay);

    // CORE: a narrow bright band. smoothstep gives soft edges.
    // Pixels near the centre line (crossDist ≈ 0) get core ≈ 1.
    // Pixels far from it (crossDist > 0.25) get core ≈ 0.
    float core = 1.0 - smoothstep(0.0, 0.22, crossDist);

    // GLOW: spherical falloff from the bolt centre.
    // At fullDist=0 → glow=1; at fullDist=0.5 → glow=0.
    float glow = pow(max(0.0, 1.0 - fullDist * 2.0), glowPower);

    // Combine: pixels that are both central AND close get the core colour;
    // pixels that are far but still within the glow radius get glowColor.
    float t = core;                          // blend factor: 1=core, 0=glow
    vec4  col = mix(glowColor, coreColor, t);

    // Overall intensity is the max of core and glow contributions
    float intensity = max(core, glow);

    // Multiply by Love2D's sprite color (carries the per-bullet alpha we set)
    return col * intensity * color;
}
