extends CharacterBody2D
@onready var sprite2D = $AnimatedSprite2D

var outline_material: ShaderMaterial = preload("res://scene/battle/chess/shader/outline_shader_material.tres")  # 你的ShaderMaterial资源
@export var outline_color_high_light = Color('#ffff54')


func _ready() -> void:
	sprite2D.material = outline_material  # 默认应用，但宽度=0无效果
	# 关键：duplicate 成唯一实例
	sprite2D.material = sprite2D.material.duplicate() as ShaderMaterial
	clear_outline_hight_light(self)
	
	Events.piece_selected.connect(set_outline_hight_light)
	Events.piece_deselected.connect(clear_outline_hight_light)
	
	add_to_group("pieces")
	pass

func set_outline_hight_light(selected_piece:CharacterBody2D):
	print("selected_piece is",selected_piece)
	if selected_piece != self:
		clear_outline_hight_light(self)
		return
	sprite2D.material.set_shader_parameter("width", 0.002)  # 显示描边
	sprite2D.material.set_shader_parameter("outline_color", outline_color_high_light)  # 黄色高亮
	pass
	
func clear_outline_hight_light(selected_piece:CharacterBody2D):
	if selected_piece != self:
		return
	sprite2D.material.set_shader_parameter("width", 0)  # 显示描边
	pass
