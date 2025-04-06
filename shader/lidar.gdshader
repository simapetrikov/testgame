shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float max_depth;

float remap_depth(float x) {
  if (x < 0.8) {
    return x * (0.2 / 0.8);
  } else {
    return 0.2 + (x - 0.8) * (0.8 / 0.2);
  }
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

  float anim_progress = clamp(fract(TIME * 0.5), 0.0, 1.0);
  float range_start = mix(0.0, 0.9, anim_progress);
  float range_end   = range_start + 0.1;

  vec3 depthColor = vec3(remap_depth(shade));
  vec3 scanColor = vec3(0.0, 0.0, 1.0);

  if (normalized_depth > range_start && normalized_depth < range_end) {
    float mid = (range_start + range_end) * 0.5;
    vec3 finalColor;
    if (normalized_depth <= mid) {
      float t = smoothstep(range_start, mid, normalized_depth);
      finalColor = mix(depthColor, scanColor, t);
    } else {
      float t = smoothstep(mid, range_end, normalized_depth);
      finalColor = mix(scanColor, depthColor, t);
    }
    ALBEDO.rgb = finalColor;
  } else {
    ALBEDO.rgb = depthColor;
  }
  if (screen_color.r > .4) {
	ALBEDO.rgb = vec3(1.0, 0.0, 0.0);
        //scanColor = vec3(1.0, 0.0, 0.0);
  }
}
