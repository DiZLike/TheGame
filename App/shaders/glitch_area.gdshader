shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 0.15) = 0.06;
uniform float speed : hint_range(0.0, 15.0) = 6.0;
uniform float block_size : hint_range(10.0, 80.0) = 15.0;
uniform float rgb_split_horizontal : hint_range(0.0, 0.1) = 0.01;
uniform float rgb_split_vertical : hint_range(0.0, 0.1) = -0.03;
uniform float edge_fade : hint_range(0.0, 2.0) = 0.5;
uniform float curve_strength : hint_range(0.0, 0.1) = 0.02;

uniform float alpha_fade_top : hint_range(0.0, 1.0) = 0.15;
uniform float alpha_fade_bottom : hint_range(0.0, 1.0) = 0.15;
uniform float alpha_fade_left : hint_range(0.0, 1.0) = 0.15;
uniform float alpha_fade_right : hint_range(0.0, 1.0) = 0.15;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    vec2 uv = UV; // UV самого ColorRect для прозрачности
    float time = TIME * speed;
    
    // Изогнутый градиент (эффект выпуклого экрана) - используем screen_uv для эффекта
    vec2 center = vec2(0.5);
    vec2 dist = screen_uv - center;
    float curve = 1.0 - length(dist) * curve_strength;
    
    // Виньетка - используем screen_uv
    float vignette = 1.0 - pow(length(dist) * edge_fade, 1.5);
    vignette = clamp(vignette, 0.0, 1.0);
    
    // Горизонтальный сдвиг строк - используем screen_uv для эффекта
    float block = floor(screen_uv.y * block_size);
    float shift_x = random(vec2(block, floor(time * 2.0))) * intensity * vignette;
    shift_x += sin(time * 15.0 + screen_uv.y * 40.0) * 0.005 * vignette;
    
    vec2 shifted_uv = screen_uv;
    shifted_uv.x += shift_x;
    
    // Применяем изгиб
    shifted_uv = (shifted_uv - center) * curve + center;
    
    // RGB-расщепление
    float split_h = rgb_split_horizontal * vignette;
    float split_v = rgb_split_vertical * vignette;
    
    float r = texture(screen_texture, shifted_uv + vec2(split_h, split_v)).r;
    float g = texture(screen_texture, shifted_uv).g;
    float b = texture(screen_texture, shifted_uv - vec2(split_h, split_v)).b;
    
    // Вычисляем альфа-канал с прозрачностью по краям САМОГО ColorRect (используем UV)
    float alpha = 1.0;
    
    // Верхний край ColorRect
    if (uv.y < alpha_fade_top) {
        alpha = uv.y / alpha_fade_top;
    }
    
    // Нижний край ColorRect
    if (uv.y > 1.0 - alpha_fade_bottom) {
        alpha = min(alpha, (1.0 - uv.y) / alpha_fade_bottom);
    }
    
    // Левый край ColorRect
    if (uv.x < alpha_fade_left) {
        alpha = min(alpha, uv.x / alpha_fade_left);
    }
    
    // Правый край ColorRect
    if (uv.x > 1.0 - alpha_fade_right) {
        alpha = min(alpha, (1.0 - uv.x) / alpha_fade_right);
    }
    
    COLOR = vec4(r, g, b, alpha);
}