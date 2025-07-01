extends PieceTemplate

func _ready():
	label = '马'
	super._ready()
	
	

func update_visual():
	pass
	#$Sprite.modulate = Color(0, 1, 0)  # 绿色表示马
	# 实际项目中：$Sprite.texture = preload("res://assets/knight.png")

func is_valid_move(target: Vector2i) -> bool:
	var delta = target - pos
	# 马：日字形（L形，|dx|=1,|dy|=2 或 |dx|=2,|dy|=1），检查蹩马腿
	if (abs(delta.x) == 1 and abs(delta.y) == 2) or (abs(delta.x) == 2 and abs(delta.y) == 1):
		var block_pos = pos
		if abs(delta.x) == 2:
			block_pos.x += delta.x / 2  # 蹩马腿位置
		else:
			block_pos.y += delta.y / 2
		return is_in_bounds(block_pos) and grid_pieces[block_pos.x][block_pos.y] == null
	return false
