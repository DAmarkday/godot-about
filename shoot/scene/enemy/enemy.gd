extends Node2D

# 敌人脚本

var speed: float = 100.0
var target: Vector2 = Game.player_position  # 玩家位置（屏幕中心）

func _ready():
	# 将敌人加入组
	add_to_group("enemies")
	# 设置敌人为1x1像素白色方块
	#$Sprite2D.texture = preload("res://pixel.png")

func _physics_process(delta):
	# 朝玩家移动
	var direction = (target - position).normalized()
	position += direction * speed * delta

func is_facing_target():
	var dir_to_target = (Game.player_position - global_position).normalized()
	var facing_dir = transform.x.normalized()
	
	var dot = facing_dir.dot(dir_to_target)
	return dot >= (1-0.7)
