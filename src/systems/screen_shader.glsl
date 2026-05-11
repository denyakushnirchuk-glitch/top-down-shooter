// src/systems/screen_shader.glsl
// Screen-space post-processing applied by blitting the game canvas.
// Effects: radial vignette, subtle blue atmospheric tint.

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);

    // ── Radial vignette ───────────────────────────────────────────────────
    // Stretch vertically a little so it hugs a 16:9 frame naturally.
    vec2  vc       = (texture_coords - 0.5) * vec2(1.0, 1.22);
    float vigSq    = dot(vc, vc);
    float vignette = 1.0 - vigSq * 3.1;
    vignette       = clamp(vignette, 0.0, 1.0);
    vignette       = pow(vignette, 0.62);    // soften: dark at corners, bright centre

    // ── Blue atmospheric tint ─────────────────────────────────────────────
    // Pull reds down, push blues up slightly — keeps the cyan/blue palette.
    pixel.r = pixel.r * 0.90;
    pixel.g = pixel.g * 0.95;
    pixel.b = min(1.0, pixel.b + 0.012);

    pixel.rgb *= vignette;

    return pixel;
}
