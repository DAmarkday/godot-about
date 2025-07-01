extends PieceTemplate

func _ready():
	label = '象'
	super._ready()

func update_visual():
	#$Sprite.modulate = Color(0, 0, 1)  # 蓝色表示象
	pass
	# 实际项目中：$Sprite.texture = preload("res://assets/bishop.png")

#func is_valid_move(target: Vector2i) -> bool:
	#var delta = target - pos
	## 象：田字形（|dx|=2,|dy|=2），检查田中心
	#if abs(delta.x) == 2 and abs(delta.y) == 2:
		#var center = pos + delta / 2
		#return is_in_bounds(center) and grid_pieces[center.x][center.y] == null
	#return false
	
func is_valid_move(target: Vector2i) -> bool:
	var delta = target - pos
	# 象：沿对角线移动（|dx|=|dy|）
	if abs(delta.x) == abs(delta.y) and delta != Vector2i(0, 0):
		# 不过河
		#if is_red and target.y < 5:
			#return false
		#if not is_red and target.y > 4:
			#return false
		# 检查路径
		return is_path_clear(pos, target)
	return false

func is_path_clear(from: Vector2i, to: Vector2i) -> bool:
	var delta = to - from
	var steps = abs(delta.x)
	var x_step = delta.x / steps if delta.x != 0 else 0
	var y_step = delta.y / steps if delta.y != 0 else 0

	for i in range(1, steps):
		var check_pos = from + Vector2i(x_step * i, y_step * i)
		if not is_in_bounds(check_pos) or grid_pieces[check_pos.x][check_pos.y] != null:
			return false
	return true
