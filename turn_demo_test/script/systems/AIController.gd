## AIController.gd
## 敌方 AI 控制器，负责在敌方回合逐个驱动敌方棋子决策并执行行动。
## 继承 Node，作为场景树中的无渲染系统节点使用。
## 设计原则：不持有任何系统的引用，所有依赖通过参数传入以保持解耦。
class_name AIController extends Node


# ─── 公共方法 ────────────────────────────────────────────────

## 执行敌方回合（异步，逐个棋子行动）。
## 遍历所有存活的敌方棋子，依次调用 decide_action 执行决策，
## 每个棋子行动后等待 0.5 秒以提供视觉反馈，全部完成后通知回合管理器结束敌方回合。
##
## 参数：
##   enemy_units:      所有存活的敌方棋子列表
##   player_units:     所有存活的玩家棋子列表
##   map_data:         地图数据
##   movement_system:  移动系统
##   combat_system:    战斗系统
##   unit_manager:     棋子管理器
##   turn_manager:     回合管理器（完成后调用 end_enemy_turn）
func execute_enemy_turn(
	enemy_units: Array[Unit],
	player_units: Array[Unit],
	map_data: MapData,
	movement_system: MovementSystem,
	combat_system: CombatSystem,
	unit_manager: UnitManager,
	turn_manager: TurnManager
) -> void:
	# 逐个处理每个敌方棋子
	for enemy in enemy_units:
		# 跳过已死亡的棋子（可能在本回合被其他棋子消灭）
		if not enemy.is_alive:
			continue

		# 为当前棋子执行决策与行动
		await decide_action(enemy, player_units, map_data, movement_system, combat_system, unit_manager)

		# 等待 0.5 秒，给玩家提供视觉反馈
		await get_tree().create_timer(0.5).timeout

	# 所有棋子行动完成，通知回合管理器结束敌方回合
	turn_manager.end_enemy_turn()


## 为单个敌方棋子决策并执行行动。
## 策略：找到最近的玩家棋子，向其靠近，若进入攻击范围则发动攻击。
##
## 参数：
##   enemy:           当前行动的敌方棋子
##   player_units:    所有存活的玩家棋子列表
##   map_data:        地图数据
##   movement_system: 移动系统
##   combat_system:   战斗系统
##   unit_manager:    棋子管理器
func decide_action(
	enemy: Unit,
	player_units: Array[Unit],
	map_data: MapData,
	movement_system: MovementSystem,
	combat_system: CombatSystem,
	unit_manager: UnitManager
) -> void:
	# 若没有存活的玩家棋子，无需行动
	if player_units.is_empty():
		return

	# ── 第一步：找到距离最近的玩家棋子 ──────────────────────

	var nearest_player: Unit = null
	var min_dist: int = 999999

	for player in player_units:
		# 跳过已死亡的玩家棋子
		if not player.is_alive:
			continue
		var dist := _manhattan_distance(enemy.grid_position, player.grid_position)
		if dist < min_dist:
			min_dist = dist
			nearest_player = player

	# 若所有玩家棋子均已死亡，无需行动
	if nearest_player == null:
		return

	# ── 第二步：计算可达格子，向目标靠近 ────────────────────

	var reachable_cells := movement_system.calculate_reachable_cells(enemy, map_data, unit_manager)

	# 在可达格子中找到距离目标玩家棋子最近的格子
	var best_cell := _find_nearest_cell(reachable_cells, nearest_player.grid_position)

	# 若找到了合适的格子，执行移动
	if best_cell != Vector2i(-1, -1):
		movement_system.try_move(enemy, best_cell, map_data, unit_manager)

	# ── 第三步：检查攻击范围，若有目标则发动攻击 ─────────────

	var attack_cells := combat_system.calculate_attack_cells(enemy)

	# 收集攻击范围内所有存活的玩家棋子
	var targets_in_range: Array[Unit] = []
	for player in player_units:
		if not player.is_alive:
			continue
		if attack_cells.has(player.grid_position):
			targets_in_range.append(player)

	# 若攻击范围内有玩家棋子，攻击其中距离最近的一个
	if not targets_in_range.is_empty():
		var nearest_target: Unit = targets_in_range[0]
		var nearest_target_dist := _manhattan_distance(enemy.grid_position, nearest_target.grid_position)

		for target in targets_in_range:
			var d := _manhattan_distance(enemy.grid_position, target.grid_position)
			if d < nearest_target_dist:
				nearest_target_dist = d
				nearest_target = target

		# 对最近的玩家棋子发动攻击
		combat_system.try_attack(enemy, nearest_target.grid_position, unit_manager)


# ─── 私有辅助方法 ────────────────────────────────────────────

## 计算两个格子之间的曼哈顿距离。
## 公式：|a.x - b.x| + |a.y - b.y|
##
## 参数：
##   a: 起始格子坐标
##   b: 目标格子坐标
##
## 返回：曼哈顿距离（非负整数）
func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## 在格子列表中找到距离目标最近的格子。
## 若列表为空，返回 Vector2i(-1, -1) 作为无效标记。
##
## 参数：
##   cells:  候选格子坐标列表
##   target: 目标格子坐标
##
## 返回：距离目标最近的格子坐标，列表为空时返回 Vector2i(-1, -1)
func _find_nearest_cell(cells: Array[Vector2i], target: Vector2i) -> Vector2i:
	# 列表为空时返回无效标记
	if cells.is_empty():
		return Vector2i(-1, -1)

	var nearest := cells[0]
	var min_dist := _manhattan_distance(cells[0], target)

	for cell in cells:
		var d := _manhattan_distance(cell, target)
		if d < min_dist:
			min_dist = d
			nearest = cell

	return nearest
