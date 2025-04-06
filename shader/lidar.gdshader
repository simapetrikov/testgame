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
    // Получаем значение глубины
    float depth = texture(depth_texture, SCREEN_UV).r;
    
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    float linear_depth = -view_pos.z;
    float normalized_depth = clamp(linear_depth / max_depth, 0.0, 1.0);
    
    // Вычисляем оттенок красного цвета на основе глубины
    float shade = 1.0 - normalized_depth;
    
    // Анимация диапазона: от 0.0-0.1 до 0.9-1.0
    float anim_progress = clamp(fract(TIME * 0.5), 0.0, 1.0); // регулируйте скорость, умножая TIME
    float range_start = mix(0.0, 0.9, anim_progress);
    float range_end   = range_start + 0.1;
    
    vec3 redColor = vec3(remap_depth(shade));
    vec3 blueColor = vec3(0.0, 0.0, 1.0);
    
    if (normalized_depth > range_start && normalized_depth < range_end) {
        float mid = (range_start + range_end) * 0.5;
        vec3 finalColor;
        if (normalized_depth <= mid) {
            // Используем smoothstep для плавного перехода от красного к синему
            float t = smoothstep(range_start, mid, normalized_depth);
            finalColor = mix(redColor, blueColor, t);
        } else {
            // Плавный переход от синего обратно к красному
            float t = smoothstep(mid, range_end, normalized_depth);
            finalColor = mix(blueColor, redColor, t);
        }
        ALBEDO.rgb = finalColor;
    } else {
        // За пределами диапазона – отображаем только красный цвет
        ALBEDO.rgb = redColor;
    }
}
