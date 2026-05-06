extends TileMapLayer
class_name HighlightLayer



#func show_movement_range(move_range: Array[Vector2i]):
	#clear()  # 清掉上一次高亮
	#if move_range.is_empty():
		#return
	## 一行代码搞定内外自动区分！
	#set_cells_terrain_connect(move_range, 0, 0,false)  

# ==================== 常量定义 ====================
const BORDER_NONE = 0
const BORDER_UP    = 1 << 0   # 1
const BORDER_RIGHT = 1 << 1   # 2
const BORDER_DOWN  = 1 << 2   # 4
const BORDER_LEFT  = 1 << 3   # 8

const ROT_0   = 0
const ROT_90  = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const ROT_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const ROT_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V

# ==================== 高亮函数 ====================
func show_move_range(cells: Array[Vector2i]):
	clear()
	if cells.is_empty(): return
	
	for cell in cells:
		var mask = 0
		if not cells.has(cell + Vector2i.UP):    mask |= BORDER_UP
		if not cells.has(cell + Vector2i.RIGHT): mask |= BORDER_RIGHT
		if not cells.has(cell + Vector2i.DOWN):  mask |= BORDER_DOWN
		if not cells.has(cell + Vector2i.LEFT):  mask |= BORDER_LEFT
		
		var atlas_coords: Vector2i
		var alt: int = ROT_0
		
		match mask:
			# 0 条边 → 内部
			0:
				atlas_coords = Vector2i(0, 0)   # ← 改成你的内部瓦片位置
			
			# 1 条边（只有1张，用旋转）
			BORDER_UP:    
				atlas_coords = Vector2i(1, 1)   # 你的单边瓦片（默认朝上）
				alt = ROT_0
			BORDER_RIGHT: 
				atlas_coords = Vector2i(1, 1)
				alt = ROT_90
			BORDER_DOWN:  
				atlas_coords = Vector2i(1, 1)
				alt = ROT_180
			BORDER_LEFT:  
				atlas_coords = Vector2i(1, 1)
				alt = ROT_270
			
			# 2 条边
			BORDER_UP | BORDER_RIGHT, \
			BORDER_RIGHT | BORDER_DOWN, \
			BORDER_DOWN | BORDER_LEFT, \
			BORDER_LEFT | BORDER_UP:
				atlas_coords = Vector2i(2, 2)   # ← 你的 L型瓦片（默认左上角）
				# 根据具体组合旋转
				if mask == (BORDER_UP | BORDER_RIGHT):
					alt = ROT_90
				elif mask == (BORDER_RIGHT | BORDER_DOWN):
					alt = ROT_180
				elif mask == (BORDER_DOWN | BORDER_LEFT):
					alt = ROT_270
				elif mask == (BORDER_LEFT | BORDER_UP):
					alt = ROT_0
			
			# 2 条相对边（直线）
			BORDER_UP | BORDER_DOWN:
				atlas_coords = Vector2i(3, 3)   # ← 你的直线型瓦片（默认竖直）
				alt = ROT_90
			BORDER_LEFT | BORDER_RIGHT:
				atlas_coords = Vector2i(3, 3)
				alt = ROT_0   # 横向
			
			# 3 条边（只有1张，用旋转）
			BORDER_UP | BORDER_RIGHT | BORDER_DOWN, \
			BORDER_RIGHT | BORDER_DOWN | BORDER_LEFT, \
			BORDER_DOWN | BORDER_LEFT | BORDER_UP, \
			BORDER_LEFT | BORDER_UP | BORDER_RIGHT:
				atlas_coords = Vector2i(4, 4)   # ← 你的三边瓦片（默认缺左边）
				match mask:
					BORDER_UP | BORDER_RIGHT | BORDER_DOWN: alt = ROT_90   # 缺左
					BORDER_RIGHT | BORDER_DOWN | BORDER_LEFT: alt = ROT_180 # 缺上
					BORDER_DOWN | BORDER_LEFT | BORDER_UP: alt = ROT_270   # 缺右
					BORDER_LEFT | BORDER_UP | BORDER_RIGHT: alt = ROT_0    # 缺下
			
			# 4 条边
			15:
				atlas_coords = Vector2i(5, 5)   # ← 你的四边瓦片
			
			_:
				atlas_coords = Vector2i(-1, -1)   # 兜底
		
		set_cell(cell, 0, atlas_coords, alt)


#func show_movement_range(cells: Array[Vector2i]):
	#clear()
	#if cells.is_empty(): return
	#
	#for cell in cells:
		## 计算 4 个正交方向是否有邻居（菱形主要靠正交）
		#var right = cells.has(cell + Vector2i.RIGHT)
		#var left  = cells.has(cell + Vector2i.LEFT)
		#var down  = cells.has(cell + Vector2i.DOWN)
		#var up    = cells.has(cell + Vector2i.UP)
		#
		#var is_inner = right and left and down and up
		#
		#var is_tl = right and down and not left and not up
		#var is_tc = left and right and down and not up
		#var is_tr = left and down and not up and not right
		#var is_cl= up and down and right and not left
		#var is_cr = up and down and left and not right
		#var is_bl = up and right and not left and not down
		#var is_bc = up and left and right and not down
		#var is_br = up and left and not right and not down
		 #
		#
		#var atlas_coords: Vector2i
		#
		#if is_inner:
			#atlas_coords = Vector2i(2, 2)  # 你的内部半透明瓦片
		#else:
			## 根据缺少的方向选边缘瓦片（你需要提前准备好这些瓦片）
				#
			#if not right and not left and not down and not up:
				#atlas_coords = Vector2i(0, 0)  # 单格孤立
			#elif is_tl:
				## 左上
				#atlas_coords = Vector2i(1, 1)
			#elif is_tc:
				## 上中
				#atlas_coords = Vector2i(2, 1)
			#elif is_tr:
				## 上右
				#atlas_coords = Vector2i(3, 1)
			#elif is_cl:
				## 中左
				#atlas_coords = Vector2i(1, 2)
			#elif is_cr:
				## 中右
				#atlas_coords = Vector2i(3, 2)
			#elif is_bl:
				## 下左
				#atlas_coords = Vector2i(1, 3)
			#elif is_bc:
				## 下中
				#atlas_coords = Vector2i(2, 3)
			#elif is_br:
				## 下右
				#atlas_coords = Vector2i(3, 3)
			##elif not right:  atlas_coords = Vector2i(3, 1)  # 右边缘
			##elif not left:   atlas_coords = Vector2i(0, 1)  # 左边缘
			##elif not down:   atlas_coords = Vector2i(1, 2)  # 下边缘
			##elif not up:     atlas_coords = Vector2i(1, 0)  # 上边缘
			### ... 继续补 L型、拐角等组合（一共 9~15 种就够）
			#else:
				#atlas_coords = Vector2i(2, 2)  # 兜底用内部
		#set_cell(cell, 0, atlas_coords,0)  # source_id=0
#



## 高亮层：使用 _draw() 绘制移动/攻击范围的半透明矩形
## 不依赖 TileSet，直接用像素坐标绘制，更灵活
## 需要放在地图上方（z_index 较高）

# 格子大小（像素），需要与地图格子大小一致
#@export var cell_size: int = 64

# 移动范围高亮颜色（蓝色半透明）
#const MOVE_COLOR = Color(0.2, 0.5, 1.0, 0.4)

# 攻击范围高亮颜色（红色半透明）
#const ATTACK_COLOR = Color(1.0, 0.2, 0.2, 0.4)

# 当前显示的移动范围格子列表
#var _move_cells: Array[Vector2i] = []

# 当前显示的攻击范围格子列表
#var _attack_cells: Array[Vector2i] = []


## 显示移动范围高亮（蓝色半透明）
## cells: 要高亮的格子坐标列表
#func show_movement_range(cells: Array[Vector2i]) -> void:
	#_move_cells = cells


## 显示攻击范围高亮（红色半透明）
## cells: 要高亮的格子坐标列表
#func show_attack_range(cells: Array[Vector2i]) -> void:
	#_attack_cells = cells
	#queue_redraw()


## 清除所有高亮
func clear_highlights() -> void:
	clear()
	#_move_cells = []
	#_attack_cells = []
	#queue_redraw()


## 绘制高亮（由 Godot 自动调用）
#func _draw() -> void:
	#var size := Vector2(cell_size, cell_size)
#
	## 绘制移动范围（蓝色）
	#for cell in _move_cells:
		#var pos := Vector2(cell.x * cell_size, cell.y * cell_size)
		#draw_rect(Rect2(pos, size), MOVE_COLOR)
#
	## 绘制攻击范围（红色）
	#for cell in _attack_cells:
		#var pos := Vector2(cell.x * cell_size, cell.y * cell_size)
		#draw_rect(Rect2(pos, size), ATTACK_COLOR)
