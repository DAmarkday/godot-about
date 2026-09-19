## UnitManager.gd
## 棋子管理器，负责棋子的注册、查询、位置更新和生命周期管理。
## 继承 Node，作为场景树中的系统节点使用。
class_name UnitManager extends Node

# ─── 内部数据结构 ────────────────────────────────────────────

# 以格子坐标（Vector2i）为键，棋子节点（Unit）为值，记录每个格子上的棋子
var _units_by_cell: Dictionary = {}

# 所有已注册的存活棋子列表
var _all_units: Array[Unit] = []


# ─── 生命周期 ────────────────────────────────────────────────

func _ready() -> void:
	# 监听棋子死亡信号，自动注销并检查胜负
	#EventBus.unit_died.connect(_on_unit_died)
	pass
	
# ─── 公共方法 ────────────────────────────────────────────────

## 注册棋子（在棋子加入场景时调用）。
## 将棋子加入 _all_units 列表，并以其 grid_position 为键写入 _units_by_cell。
## unit: 要注册的棋子节点
func register_unit(unit: Unit) -> void:
	if unit == null:
		push_warning("UnitManager.register_unit: 传入的 unit 为 null，已忽略。")
		return

	if _all_units.has(unit):
		push_warning("UnitManager.register_unit: 棋子 %s 已注册，跳过重复注册。" % unit.unit_name)
		return

	_all_units.append(unit)
	_units_by_cell[unit.grid_position] = unit
	
## 注销棋子（棋子死亡时调用，从管理器中移除）。
## 从 _all_units 列表和 _units_by_cell 字典中删除该棋子的所有记录。
## unit: 要注销的棋子节点
func unregister_unit(unit: Unit) -> void:
	if unit == null:
		push_warning("UnitManager.unregister_unit: 传入的 unit 为 null，已忽略。")
		return

	_all_units.erase(unit)

	# 遍历字典，删除所有指向该棋子的键（防止位置记录残留）
	var keys_to_remove: Array = []
	for cell in _units_by_cell:
		if _units_by_cell[cell] == unit:
			keys_to_remove.append(cell)
	for cell in keys_to_remove:
		_units_by_cell.erase(cell)
		
## 查询指定格子上的棋子，若无则返回 null。
## cell: 要查询的格子坐标
func get_unit_at(cell: Vector2i) -> Unit:
	return _units_by_cell.get(cell, null)
	
## 更新棋子的位置记录（移动后调用）。
## 先删除旧位置的记录，再写入新位置。
## unit:     要更新的棋子节点
## new_cell: 新的格子坐标
func update_unit_position(unit: Unit, new_cell: Vector2i) -> void:
	if unit == null:
		push_warning("UnitManager.update_unit_position: 传入的 unit 为 null，已忽略。")
		return

	# 删除旧位置记录
	var keys_to_remove: Array = []
	for cell in _units_by_cell:
		if _units_by_cell[cell] == unit:
			keys_to_remove.append(cell)
	for cell in keys_to_remove:
		_units_by_cell.erase(cell)

	# 写入新位置
	_units_by_cell[new_cell] = unit
	unit.grid_position = new_cell
	
## 获取所有存活的玩家棋子（team == 0）。
func get_player_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _all_units:
		if unit.team == MapData.TeamType.PLAYER:
			result.append(unit)
	return result
	
## 获取所有存活的敌方棋子（team == 1）。
func get_enemy_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _all_units:
		if unit.team == MapData.TeamType.ENEMY:
			result.append(unit)
	return result
	
## 检查胜负条件：
## - 若无存活敌方棋子，发出 EventBus.battle_won 信号
## - 若无存活玩家棋子，发出 EventBus.battle_lost 信号
#func check_battle_result() -> void:
	#if get_enemy_units().is_empty():
		#EventBus.battle_won.emit()
	#elif get_player_units().is_empty():
		#EventBus.battle_lost.emit()


# ─── 信号处理 ────────────────────────────────────────────────

## 响应 unit_died 信号：注销死亡棋子，从场景树移除，并检查胜负。
## unit: 死亡的棋子节点
## team: 所属阵营（未使用，保留以匹配信号签名）
#func _on_unit_died(unit: Unit, _team: int) -> void:
	#unregister_unit(unit)
	#if is_instance_valid(unit):
		#unit.queue_free()
	#check_battle_result()
