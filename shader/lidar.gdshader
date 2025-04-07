shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float max_depth;
uniform bool is_moving;
uniform bool wave_active;

float remap_depth(float x) {
    float low = x * (0.2 / 0.8);
    float high = 0.2 + (x - 0.8) * (0.8 / 0.2);
    float t = smoothstep(0.75, 0.85, x);
    return mix(low, high, t);
}

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
  vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
  float depth = texture(depth_texture, SCREEN_UV).r;

  vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
  vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  view_pos.xyz /= view_pos.w;
  float linear_depth = -view_pos.z;
  float normalized_depth = clamp(linear_depth / max_depth, 0.0, 1.0);
  float shade = 1.0 - normalized_depth;

  vec3 depthColor = vec3(remap_depth(shade));
  vec3 scanColor = vec3(0.0, 0.0, 1.0);

  if (is_moving || wave_active) {
    float wave_center = fract(TIME * 0.5); // progress from 0 to 1
    float wave_thickness = 0.1; // thickness of the wave
    float wave_start = wave_center - wave_thickness * 0.5;
    float wave_end = wave_center + wave_thickness * 0.5;

    float blend = smoothstep(wave_start, wave_center, normalized_depth) *
                  (1.0 - smoothstep(wave_center, wave_end, normalized_depth));

    vec3 finalColor = mix(depthColor, scanColor, blend);
    ALBEDO.rgb = finalColor;
  } else {
    ALBEDO.rgb = depthColor;
  }

  if (screen_color.r > 0.4) {
    ALBEDO.rgb = vec3(0.9, 0.0, 0.0);
  }
  else if (screen_color.g > 0.4) {
    ALBEDO.rgb = vec3(0.0, 0.9, 0.0);
  }

}
