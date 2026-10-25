#version 460 core
// Three pools of pigment on wet paper, after website/WatercolorWash.vue:
// fractal noise displaces the blobs' edges so they bleed instead of cutting.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColor; // premultiplied-free: rgb pigment, a overall strength

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
    f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p *= 2.03;
    a *= 0.5;
  }
  return v;
}

// A blob with a soft, noisy rim; returns coverage and writes the rim weight.
float blob(vec2 p, vec2 centre, float radius, vec2 warp, out float rim) {
  float d = length(p - centre + warp) / radius;
  float body = 1.0 - smoothstep(0.55, 1.0, d);
  rim = smoothstep(0.35, 0.8, d) * (1.0 - smoothstep(0.8, 1.05, d));
  return body;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  // Same framing as the SVG: a 1000x800 box covering the screen ("slice").
  float scale = max(uSize.x / 1000.0, uSize.y / 800.0);
  vec2 p = (frag - 0.5 * uSize) / scale; // centred, in box units

  float t = uTime;
  vec2 q = p / 420.0;
  vec2 warp = (vec2(
    fbm(q * 2.2 + vec2(t * 0.012, 3.1)),
    fbm(q * 2.2 + vec2(7.7, -t * 0.015))) - 0.5) * 210.0;

  // Slow drift, each pool on its own period (22s / 28s / 34s in the site).
  vec2 d1 = vec2(sin(t * 0.285), cos(t * 0.23)) * 28.0;
  vec2 d2 = vec2(cos(t * 0.224), sin(t * 0.26)) * 24.0;
  vec2 d3 = vec2(sin(t * 0.185 + 1.7), cos(t * 0.2)) * 26.0;

  float r1; float r2; float r3;
  float b1 = blob(p, vec2(-270.0, -210.0) + d1, 300.0, warp, r1);
  float b2 = blob(p, vec2(300.0, -70.0) + d2, 255.0, warp, r2);
  float b3 = blob(p, vec2(20.0, 260.0) + d3, 310.0, warp, r3);

  float cover = 1.0 - (1.0 - b1) * (1.0 - b2) * (1.0 - b3);
  float rim = max(r1, max(r2, r3));

  // Pigment pools at the edge and thins in the middle, like real watercolour.
  float mottling = 0.8 + 0.4 * fbm(q * 5.0 + 11.0);
  float alpha = clamp(cover * mottling * (0.78 + 0.5 * rim), 0.0, 1.0) * uColor.a;

  fragColor = vec4(uColor.rgb * alpha, alpha);
}
