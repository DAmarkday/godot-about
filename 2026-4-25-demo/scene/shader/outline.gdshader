shader_type canvas_item;
render_mode unshaded;   // 必须保留

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 20.0, 0.1) = 2.0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec2 pixel = SCREEN_PIXEL_SIZE * outline_width;
    
    // 采样8方向 alpha
    float outline = 0.0;
    outline += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, 0.0)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2( pixel.x, 0.0)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2(0.0, -pixel.y)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2(0.0, pixel.y)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, -pixel.y)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, pixel.y)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2( pixel.x, -pixel.y)).a;
    outline += texture(screen_texture, SCREEN_UV + vec2( pixel.x, pixel.y)).a;
    
    outline = clamp(outline, 0.0, 1.0);
    
    // 读取当前合成像素
    vec4 tex = texture(screen_texture, SCREEN_UV);
    
    // 关键：反预乘 alpha（Godot CanvasGroup 必须）
    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }
    
    // 核心逻辑
    if (tex.a > 0.01) {
        COLOR = tex;                    // 原内容
    } else if (outline > 0.01) {
        COLOR = line_color;
        COLOR.a *= outline;
    } else {
        COLOR = vec4(0.0);
    }
    
    // 重要修正：保留 Self Modulate / Modulate 颜色（社区标准写法）
    COLOR *= COLOR.a;   // 只乘 alpha，避免颜色变暗
    // 或者用下面这行（godotshaders.com 常用写法，更推荐）
    // COLOR = mix(COLOR, tex, tex.a);  // 如果想更自然混合
}