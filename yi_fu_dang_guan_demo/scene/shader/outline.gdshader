shader_type canvas_item;
render_mode unshaded;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 20.0, 0.1) = 0.0;  // 默认0，不显示描边

void fragment() {
    vec2 pixel = TEXTURE_PIXEL_SIZE * outline_width;
    
    // 8方向采样 alpha
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-pixel.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(-pixel.x, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x, pixel.y)).a;
    
    outline = clamp(outline, 0.0, 1.0);
    
    vec4 tex = texture(TEXTURE, UV);
    
    if (tex.a > 0.01) {
        COLOR = tex;                    // 显示原图
    } else if (outline > 0.01) {
        COLOR = line_color;
        COLOR.a *= outline;
    } else {
        COLOR = vec4(0.0);
    }
}