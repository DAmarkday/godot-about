shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(1.0, 3.0) = 1.0; // 控制亮度
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // 默认白色

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float flash = flash_intensity * (0.5 + 0.5 * sin(TIME * 25.0)); // 快速闪烁
    vec4 bright_flash = flash_color * brightness; // 增强亮度
    COLOR = mix(tex_color, bright_flash, flash); // 混合亮白
    COLOR.a = tex_color.a; // 保持透明度
}