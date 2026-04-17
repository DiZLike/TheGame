shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D BASE_TEXTURE : filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 0.15) = 0.06;
uniform float speed : hint_range(0.0, 15.0) = 6.0;
uniform float block_size : hint_range(10.0, 80.0) = 15.0;
uniform float rgb_split_horizontal : hint_range(0.0, 0.1) = 0.01;
uniform float rgb_split_vertical : hint_range(0.0, 0.1) = -0.03;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    
    float block = floor(uv.y * block_size);
    float shift_x = random(vec2(block, floor(time * 2.0))) * intensity;
    shift_x += sin(time * 15.0 + uv.y * 40.0) * 0.005;
    
    vec2 shifted_uv = uv;
    shifted_uv.x += shift_x;
    
    float r = texture(BASE_TEXTURE, shifted_uv + vec2(rgb_split_horizontal, rgb_split_vertical)).r;
    float g = texture(BASE_TEXTURE, shifted_uv).g;
    float b = texture(BASE_TEXTURE, shifted_uv - vec2(rgb_split_horizontal, rgb_split_vertical)).b;
    
    COLOR = vec4(r, g, b, 1.0);
}