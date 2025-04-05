shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform float max_depth = 10.0;

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
    float depth = texture(depth_texture, SCREEN_UV).r;

    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    float linear_depth = -view_pos.z;

    float normalized_depth = clamp(linear_depth / max_depth, 0.0, 1.0);
    float shade = 1.0 - normalized_depth;

    ALBEDO.rgb = vec3(remap_depth(shade));
}
