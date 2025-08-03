extends Area2D

# 敌人脚本

var speed: float = 100.0
var target: Vector2 = Vector2(960, 540)  # 玩家位置（屏幕中心）

func _ready():
	# 将敌人加入组
	add_to_group("enemies")

func _physics_process(delta):
	# 朝玩家移动
	var direction = (target - position).normalized()
	position += direction * speed * delta
