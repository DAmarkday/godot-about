shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // 默认黄色
uniform float outline_width : hint_range(0.0, 20.0, 0.1) = 2.0;

void fragment() {
    vec2 pixel = TEXTURE_PIXEL_SIZE * outline_width;
    
    // 采样周围（8方向）
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-pixel.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0,  pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(-pixel.x, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2(-pixel.x,  pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x, -pixel.y)).a;
    outline += texture(TEXTURE, UV + vec2( pixel.x,  pixel.y)).a;
    
    // 把 outline 限制在 0~1 之间（可选，但更稳定）
    outline = clamp(outline, 0.0, 1.0);
    
    vec4 tex = texture(TEXTURE, UV);
    
    // 关键：只在原图透明的地方绘制描边
    if (tex.a > 0.01) {          // 原像素不透明 → 保持原样
        COLOR = tex;
    } else {                     // 原像素透明 → 如果有邻居，就画描边
        if (outline > 0.01) {
            COLOR = line_color;
            COLOR.a *= outline;   // 让描边边缘更柔和（可选）
        } else {
            COLOR = vec4(0.0);    // 完全没邻居 → 透明
        }
    }
}