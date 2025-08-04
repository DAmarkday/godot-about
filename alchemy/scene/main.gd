extends Node2D
@onready var canvas_layer:CanvasLayer =$CanvasLayer

func _ready():
	#pass
	# 加载面板场景
	var panel_scene = preload("res://scene/battle/turnBased/turnBased.tscn")
	var panel_instance = panel_scene.instantiate()
	
	# 添加到场景树
	#panel_instance.canvas_layer = 1  # 设置到不同的 CanvasLayer
	canvas_layer.add_child(panel_instance)
	
	# 获取窗口大小
	var viewport_size = get_viewport_rect().size
	
	# 设置面板位置
	var panel_size = panel_instance.get_rect().size  # 获取面板的尺寸
	var bottom_margin = 20  # 距离底部的边距，可调整
	
	# 计算居中底部的坐标
	var x =(viewport_size.x - panel_size.x)/2 # 水平居中
	var y = viewport_size.y - panel_size.y - bottom_margin  # 底部位置
	
	# 设置面板位置
	panel_instance.position = Vector2(x, y)
