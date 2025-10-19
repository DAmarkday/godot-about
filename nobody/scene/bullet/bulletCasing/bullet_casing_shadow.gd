extends Sprite2D
# 由于影子都是直线移动
class_name BulletCasingShadow
var mapping_shell_instance:BulletCasing = null

var target_pos: Vector2 =  Vector2.ZERO

var k: float = 0.0
var b: float = 0.0
func caculate_Y(landPos: Vector2, initPos: Vector2, curX: float):
	if abs(landPos.x - initPos.x) < 0.0001:  # 避免除零
		if abs(curX - initPos.x) < 0.0001:  # curX 必须等于 initPos.x
			# 返回线上的点，y 可为任意值，这里返回 initPos.y
			return Vector2(initPos.x, initPos.y)
		else:
			print("Error: curX does not lie on vertical line")
			return Vector2.INF
	
	# 计算斜率和截距
	k = (landPos.y - initPos.y) / (landPos.x - initPos.x)
	b = initPos.y - k * initPos.x  # 截距 b = y1 - k * x1
	
	# 计算 curY
	#var curY: float = k * curX + b
	# 可选：更新 global_position（Node2D）
	#global_position = Vector2(curX, curY)
	#target_pos = Vector2(curX, curY)
	

# 计算直线上给定 x 坐标的点，并可选更新 global_position
# - initPos: 起始点
# - landPos: 结束点（例如抛物线着陆点）
# - curX: 目标 x 坐标
# - 返回 Vector2(curX, curY)，如果无效（例如垂直直线且 curX 不匹配），返回 Vector2.INF
func move(curX: float,init_shell_shadow_pos:Vector2):
	# 计算 curY
	var curY: float = k * curX + b
	if curY > init_shell_shadow_pos.y:
		global_position = init_shell_shadow_pos
	else:
		target_pos = Vector2(curX, curY)
		global_position = target_pos


#func _physics_process(_delta):
	# 平滑更新 x 坐标，y 固定
	#var current_pos = global_position
	#global_position = current_pos.lerp(target_pos, 1.0)  # 0.8 是插值因子（0.0~1.0），越大越快接近目标
	
func recycle_ani():
	var fade_time = 2
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 0.7), fade_time)
	tween.parallel().tween_property(self, "modulate:a", 0.0, fade_time)


#func _on_area_2d_body_entered(body: Node2D) -> void:
	##if body is BulletCasing:
	#if body is BulletCasing and mapping_shell_instance != null:
		#mapping_shell_instance.bound()
