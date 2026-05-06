## MovementSystem.gd
## 移动系统，负责计算棋子可移动范围、校验移动合法性并执行移动动画。
## 继承 Node，作为场景树中的无渲染系统节点使用。
## 设计原则：不持有 UnitManager 或 MapData 的引用，通过参数传入以保持解耦。
class_name MovementSystem extends Node


# ─── 公共方法 ────────────────────────────────────────────────

## 计算棋子本回合可到达的所有格子。
## 收集所有其他棋子的位置作为障碍，委托 MovementRangeCalculator 执行 BFS，
## 并从结果中排除棋子自身所在格子。
##
## 参数：
##   unit:         要计算的棋子
##   map_data:     地图数据（提供地形成本和边界信息）
##   unit_manager: 棋子管理器（用于获取已占据格子列表）
##
## 返回：可达格子坐标列表（不含起点）
func calculate_reachable_cells(unit: Unit, map_data: MapData, unit_manager: UnitManager) -> Array[Vector2i]:
	# 防御性检查：参数不能为空
	if unit == null or map_data == null or unit_manager == null:
		push_warning("MovementSystem.calculate_reachable_cells: 参数不能为 null。")
		return []

	# 防御性检查：棋子必须存活
	if not unit.is_alive:
		return []

	# 收集所有其他棋子的格子坐标作为障碍
	var occupied_cells: Array[Vector2i] = _get_occupied_cells(unit, unit_manager)

	# 使用 MovementRangeCalculator 计算可达格子
	var calculator := MovementRangeCalculator.new(map_data)
	var reachable := calculator.calculate_movement_range(
		unit.grid_position,
		unit.movement,
		occupied_cells
	)

	# 排除棋子自身位置（calculate_movement_range 通常不包含起点，但做双重保险）
	reachable.erase(unit.grid_position)

	return reachable


## 尝试将棋子移动到目标格子（含完整合法性校验）。
## 校验顺序：棋子存活 → 本回合未移动 → 目标在可达范围内 → 目标未被其他棋子占据。
## 任一校验失败则立即返回 false，不修改任何状态。
##
## 参数：
##   unit:         要移动的棋子
##   target_cell:  目标格子坐标
##   map_data:     地图数据
##   unit_manager: 棋子管理器
##   layer: 基准layer
##
## 返回：移动成功返回 true，失败返回 false
func try_move(unit: Unit, target_cell: Vector2i, map_data: MapData, unit_manager: UnitManager,layer:TileMapLayer) -> bool:
	# 防御性检查：参数不能为空
	if unit == null or map_data == null or unit_manager == null:
		push_warning("MovementSystem.try_move: 参数不能为 null。")
		return false
#
	# 校验 1：棋子必须存活
	#if not unit.is_alive:
		#return false
#
	## 校验 2：本回合未移动
	#if unit.has_moved:
		#return false
	# 校验 3：目标格子在可达范围内
	var reachable := calculate_reachable_cells(unit, map_data, unit_manager)
	if not reachable.has(target_cell):
		return false

	## 校验 4：目标格子未被其他棋子占据
	var occupant := unit_manager.get_unit_at(target_cell)
	if occupant != null and occupant != unit:
		return false
#
	# ── 所有校验通过，执行移动 ──────────────────────────────
#
	# 记录起始格子（update_unit_position 会修改 unit.grid_position，需提前保存）
	var from_cell: Vector2i = unit.grid_position
#
	# 更新棋子管理器中的位置记录（同时更新 unit.grid_position）
	# 在修改数据前存临时备份
	var temp_cell_pos = unit.grid_position
	
	unit_manager.update_unit_position(unit, target_cell)
	# 标记本回合已移动
	#unit.has_moved = true
#
	## 发出移动完成信号
	##EventBus.unit_moved.emit(unit, from_cell, target_cell)
#
	# 计算移动路径并异步执行动画（不等待，不阻塞逻辑）
	var occupied_cells: Array[Vector2i] = _get_occupied_cells(unit, unit_manager)
	var calculator := MovementRangeCalculator.new(map_data)
	var path := calculator.calculate_path(from_cell, target_cell, occupied_cells)
#
	if path.size() > 0:
		unit.face_direction_tweened(target_cell,temp_cell_pos,0.12,
		func ():
			animate_movement.call_deferred(unit, path,layer))
			
	return true




## 执行棋子移动动画，使用 Tween 逐格平滑移动。
## 跳过路径第一个格子（起点），从第二个格子开始依次移动。
## 每格移动时间为 0.15 秒，格子坐标转像素坐标公式：Vector2(cell.x * cell_size, cell.y * cell_size)。
##
## 参数：
##   unit:      要移动的棋子节点
##   path:      移动路径（格子坐标列表，含起点）
##   cell_size: 每个格子的像素大小（默认 64）
func animate_movement(unit: Unit, path: Array[Vector2i],layer:TileMapLayer, cell_size: int = 64) -> void:
	# 防御性检查：棋子节点必须有效
	if not is_instance_valid(unit):
		return

	# 路径至少需要两个格子（起点 + 至少一个目标格子）才需要动画
	if path.size() < 2:
		return
	
	# 移动前：强制切回站立（防止上一次移动动画残留）
	unit.idle()
	
	# 开始行走动画
	unit.walk()

	# 创建 Tween，绑定到棋子节点（棋子销毁时自动停止）
	var tween := unit.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	# 从第二个格子开始（跳过起点）
	for i in range(1, path.size()):
		var cell := path[i]
		# 格子坐标转像素坐标
		# 将每个格子坐标转化为对应的格子中点的全局坐标
		var target_pos :=GridUtils.cell_to_world(layer,cell)
		tween.tween_property(unit, "position", target_pos, 0.5)
		
	# ── 关键：移动结束后强制回到站立 ─────────────────────
	# 方法一（推荐）：用 callback，最干净
	tween.tween_callback(unit.idle)
	
	# 方法二（额外保险）：连接 finished 信号（防止 callback 失效）
	#tween.finished.connect(func():
		#if is_instance_valid(unit):
			#unit.idle()
	#, CONNECT_ONE_SHOT)   # 只触发一次，防止内存泄漏


# ─── 私有辅助方法 ────────────────────────────────────────────

## 获取除指定棋子以外所有棋子的格子坐标列表（用作障碍集合）。
##
## 参数：
##   exclude_unit: 要排除的棋子（通常是正在移动的棋子自身）
##   unit_manager: 棋子管理器
##
## 返回：其他棋子占据的格子坐标列表
func _get_occupied_cells(exclude_unit: Unit, unit_manager: UnitManager) -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []

	# 合并玩家棋子和敌方棋子
	var all_units: Array[Unit] = []
	all_units.append_array(unit_manager.get_player_units())
	all_units.append_array(unit_manager.get_enemy_units())

	for u in all_units:
		# 排除自身
		if u == exclude_unit:
			continue
		occupied.append(u.grid_position)

	return occupied
