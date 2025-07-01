shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // 混合原始颜色和白色，flash_amount 控制强度
    COLOR = mix(color, vec4(1.0, 1.0, 1.0, color.a), flash_amount);
}