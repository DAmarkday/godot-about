extends Node2D
@onready var battle_chess:Node2D =$BattleChess
@onready var canvas_layer:CanvasLayer =$CanvasLayer
@onready var turn_label:Control =$TurnLabel

#func _ready():
	##pass
	## 加载面板场景
	#var panel_scene = preload("res://plugin/turnBased/turnBased.tscn")
	#var panel_instance = panel_scene.instantiate()
	#
	#var turn_label = preload("res://plugin/turnsLabel/turnLabel.tscn")
	#var label_instance = turn_label.instantiate()
	#
	## 添加到场景树
	##panel_instance.canvas_layer = 1  # 设置到不同的 CanvasLayer
	#canvas_layer.add_child(panel_instance)
	#canvas_layer.add_child(label_instance)
	#
	## 获取窗口大小
	#var viewport_size = get_viewport_rect().size
	#
	## 设置面板位置
	#var panel_size = panel_instance.get_rect().size  # 获取面板的尺寸
	#var bottom_margin = 20  # 距离底部的边距，可调整
	#
	## 计算居中底部的坐标
	#var x =(viewport_size.x - panel_size.x)/2 # 水平居中
	#var y = viewport_size.y - panel_size.y - bottom_margin  # 底部位置
	#
	##var bs = battle_chess.  # 获取面板的尺寸
	##var xb =(viewport_size.x - bs.x)/2 # 水平居中
	##var yb = viewport_size.y - bs.y - bottom_margin  # 底部位置
	#
	#var label_size = label_instance.get_rect().size 
	#var xp =(viewport_size.x - label_size.x) - 10 
	#var yp = 10
	#
	#
	## 设置面板位置
	#panel_instance.position = Vector2(x, y)
	#label_instance.position = Vector2(xp, yp)
	#
	#var width= battle_chess.grid_chess.get_grid_center_position().x * 2
	#battle_chess.position = Vector2((viewport_size.x -  width) / 2,0)
