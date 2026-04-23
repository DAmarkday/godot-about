## CombatSystem.gd
## 战斗系统，负责计算攻击范围、伤害值，以及校验并执行攻击行为。
## 继承 Node，作为场景树中的无渲染系统节点使用。
## 设计原则：不持有 UnitManager 的引用，通过参数传入以保持解耦。
class_name CombatSystem extends Node


# ─── 公共方法 ────────────────────────────────────────────────

## 计算棋子的攻击范围（返回可攻击格子列表）。
## 遍历以 unit.grid_position 为中心的矩形区域（范围 ±attack_range），
## 只保留曼哈顿距离（|dx| + |dy|）≤ attack_range 的格子，并排除棋子自身位置。
##
## 参数：
##   unit: 要计算攻击范围的棋子
##
## 返回：可攻击格子坐标列表（不含棋子自身所在格子）
func calculate_attack_cells(unit: Unit) -> Array[Vector2i]:
	# 防御性检查：棋子不能为 null
	if unit == null:
		push_warning("CombatSystem.calculate_attack_cells: 传入的 unit 为 null。")
		return []

	var result: Array[Vector2i] = []
	var center: Vector2i = unit.grid_position
	var range_val: int = unit.attack_range

	# 遍历以中心为原点的矩形区域
	for dx in range(-range_val, range_val + 1):
		for dy in range(-range_val, range_val + 1):
			# 排除棋子自身位置
			if dx == 0 and dy == 0:
				continue
			# 只保留曼哈顿距离 ≤ attack_range 的格子
			if abs(dx) + abs(dy) <= range_val:
				result.append(center + Vector2i(dx, dy))

	return result


## 计算攻击伤害值。
## 公式：max(1, 攻击力 - 目标防御力)，最小伤害为 1。
##
## 参数：
##   attacker: 攻击方棋子
##   target:   防御方棋子
##
## 返回：最终伤害值（最小为 1）
func calculate_damage(attacker: Unit, target: Unit) -> int:
	# 防御性检查：攻击方和防御方均不能为 null
	if attacker == null:
		push_warning("CombatSystem.calculate_damage: 传入的 attacker 为 null。")
		return 1
	if target == null:
		push_warning("CombatSystem.calculate_damage: 传入的 target 为 null。")
		return 1

	return max(1, attacker.attack_power - target.defense)


## 尝试攻击目标格子上的棋子（含合法性校验）。
## 校验顺序：攻击者存活 → 本回合未攻击 → 目标格子在攻击范围内 → 目标格子有敌方棋子。
## 任一校验失败则立即返回 false，不修改任何状态。
##
## 参数：
##   attacker:     发起攻击的棋子
##   target_cell:  目标格子坐标
##   unit_manager: 棋子管理器（用于查询目标格子上的棋子）
##
## 返回：攻击成功返回 true，失败返回 false
func try_attack(attacker: Unit, target_cell: Vector2i, unit_manager: UnitManager) -> bool:
	# 防御性检查：参数不能为 null
	if attacker == null or unit_manager == null:
		push_warning("CombatSystem.try_attack: 参数不能为 null。")
		return false

	# 校验 1：攻击者必须存活
	if not attacker.is_alive:
		return false

	# 校验 2：本回合未攻击
	if attacker.has_attacked:
		return false

	# 校验 3：目标格子在攻击范围内
	var attack_cells := calculate_attack_cells(attacker)
	if not attack_cells.has(target_cell):
		return false

	# 校验 4：目标格子有棋子，且必须是敌方棋子
	var target := unit_manager.get_unit_at(target_cell)
	if target == null:
		return false
	if target.team == attacker.team:
		return false

	# ── 所有校验通过，执行攻击 ──────────────────────────────

	# 计算伤害
	var damage: int = calculate_damage(attacker, target)

	# 对目标造成伤害
	target.take_damage(damage)

	# 标记攻击者本回合已攻击
	attacker.has_attacked = true

	# 发出攻击完成信号
	EventBus.attack_performed.emit(attacker, target, damage)

	return true
