## Unit.gd
## 棋子节点脚本，继承 CharacterBody2D。
## 负责存储棋子运行时状态，并响应伤害、死亡等事件。
class_name Unit extends CharacterBody2D

# ─── 从 UnitData 加载的属性 ──────────────────────────────────

# 单位名称
var unit_name: String = "士兵"
# 最大血量
var max_hp: int = 10
# 当前血量
var current_hp: int = 10
# 移动力（每回合最多移动的格子数）
var movement: int = 3
# 攻击力
var attack_power: int = 3
# 防御力（减少受到的伤害）
var defense: int = 1
# 攻击范围（曼哈顿距离，1=近战，2+=远程）
var attack_range: int = 1
# 所属阵营（0=玩家，1=敌方）
var team: int = 0

# ─── 运行时状态 ──────────────────────────────────────────────

# 当前所在格子坐标
var grid_position: Vector2i = Vector2i.ZERO
# 本回合是否已移动
var has_moved: bool = false
# 本回合是否已攻击
var has_attacked: bool = false
# 是否存活
var is_alive: bool = true


# ─── 初始化 ──────────────────────────────────────────────────

## 从 UnitData 资源加载所有属性。
## 若 data 为 null，则使用默认值并打印警告。
func setup(data: UnitData) -> void:
	if data == null:
		push_warning("Unit.setup: 传入的 UnitData 为 null，将使用默认属性值。")
		current_hp = max_hp
		return

	unit_name    = data.unit_name
	max_hp       = data.max_hp
	movement     = data.movement
	attack_power = data.attack_power
	defense      = data.defense
	attack_range = data.attack_range
	team         = data.team
	current_hp   = max_hp

	# 若资源携带动画帧，则赋给子节点 AnimatedSprite2D
	if data.sprite_frames != null:
		var sprite := get_node_or_null("Sprite") as AnimatedSprite2D
		if sprite:
			sprite.sprite_frames = data.sprite_frames
			sprite.play("default")


# ─── 战斗方法 ────────────────────────────────────────────────

## 受到伤害。
## 扣除血量（不低于 0），发出 unit_damaged 信号；
## 若血量归零则设置 is_alive = false 并发出 unit_died 信号。
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	EventBus.unit_damaged.emit(self, amount, current_hp)

	if current_hp <= 0:
		is_alive = false
		EventBus.unit_died.emit(self, team)


# ─── 回合方法 ────────────────────────────────────────────────

## 重置本回合行动状态（由 TurnManager 在每回合开始时调用）。
func reset_actions() -> void:
	has_moved   = false
	has_attacked = false


# ─── 工具方法 ────────────────────────────────────────────────

## 返回单位名称，方便调试输出。
func get_display_name() -> String:
	return unit_name
