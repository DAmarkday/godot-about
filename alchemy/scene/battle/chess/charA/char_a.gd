extends PieceTemplate

func _ready():
	label = '车'
	super._ready()

func update_visual():
	pass
	#$Sprite.modulate = Color(1, 0, 0)  # 红色表示车
	# 实际项目中：$Sprite.texture = preload("res://assets/rook.png")

func is_valid_move(target: Vector2i) -> bool:
	var delta = target - pos
	# 车：直线移动，路径无阻挡
	if delta.x == 0 or delta.y == 0:
		return is_path_clear(pos, target)
	return false

func is_path_clear(from: Vector2i, to: Vector2i) -> bool:
	if from.x == to.x:
		var y_step = 1 if to.y > from.y else -1
		for y in range(from.y + y_step, to.y + y_step, y_step):
			if grid_pieces[from.x][y] != null:
				return false
	elif from.y == to.y:
		var x_step = 1 if to.x > from.x else -1
		for x in range(from.x + x_step, to.x + x_step, x_step):
			if grid_pieces[x][from.y] != null:
				return false
	return true
