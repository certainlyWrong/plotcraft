#version 460 core
// Paper grain: speckle whose alpha comes from noise, so colour looks absorbed
// by the paper rather than printed on it (website body::after).
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uOpacity;
uniform vec3 uTone;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return fract((p.x + p.y) * p.x);
}

void main() {
  vec2 frag = floor(FlutterFragCoord().xy * 0.75);
  float n = hash(frag) * 0.65 + hash(frag * 0.5 + 3.0) * 0.35;
  float alpha = n * uOpacity;
  fragColor = vec4(uTone * alpha, alpha);
}
