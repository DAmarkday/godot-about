## Unit.gd
## 棋子节点脚本，继承 CharacterBody2D。
## 负责存储棋子运行时状态，并响应伤害、死亡等事件。
class_name Unit extends CharacterBody2D

@onready var HealthBar: PackedScene = preload("res://plugin/health/health.tscn")
@onready var VisualsNode:Node2D = $Visuals
@onready var SpriteNode:AnimatedSprite2D = $Visuals/Sprite

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

var sprite_frames:SpriteFrames

# ─── 运行时状态 ──────────────────────────────────────────────

# 当前所在格子坐标
var grid_position: Vector2i = Vector2i.ZERO
# 本回合是否已移动
var has_moved: bool = false
# 本回合是否已攻击
var has_attacked: bool = false
# 是否存活
var is_alive: bool = true
var health_bar_color = Color('#000000')


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
		sprite_frames =  data.sprite_frames
			
	if data.team == MapData.TeamType.PLAYER:
		health_bar_color = MapConfig.player_health_bar_color
	elif data.team == MapData.TeamType.ENEMY:
		health_bar_color = MapConfig.enemy_health_bar_color
	
	

func _ready() -> void:
	SpriteNode.sprite_frames = sprite_frames
	SpriteNode.play("idle")
	SpriteNode.autoplay = "idle"
	
	var child_instance = HealthBar.instantiate()
	child_instance.full_health_color =  health_bar_color
	child_instance.max_health = max_hp
	
	VisualsNode.material = MapConfig.outline_material  # 默认应用，但宽度=0无效果
	# 关键：duplicate 成唯一实例
	VisualsNode.material = VisualsNode.material.duplicate() as ShaderMaterial
	clear_outline_hight_light()
	
	add_child(child_instance)
# ─── 战斗方法 ────────────────────────────────────────────────

## 受到伤害。
## 扣除血量（不低于 0），发出 unit_damaged 信号；
## 若血量归零则设置 is_alive = false 并发出 unit_died 信号。
#func take_damage(amount: int) -> void:
	#current_hp = max(0, current_hp - amount)
	#EventBus.unit_damaged.emit(self, amount, current_hp)
#
	#if current_hp <= 0:
		#is_alive = false
		#EventBus.unit_died.emit(self, team)
#

# ─── 回合方法 ────────────────────────────────────────────────

## 重置本回合行动状态（由 TurnManager 在每回合开始时调用）。
#func reset_actions() -> void:
	#has_moved   = false
	#has_attacked = false
#
# ─── 动画方法 ────────────────────────────────────────────────
func walk():
	SpriteNode.play("walk")
	pass
func idle():
	SpriteNode.play("idle")
	pass
	

## 平滑翻转 Sprite（带 Tween 过渡 + 可选挤压效果）
func face_direction_tweened(to_cell:Vector2i,from_cell: Vector2i, duration: float = 0.12,on_complete: Callable = Callable()) -> void:	
	# 计算目标朝向：向左=-1，向右=1
	var dir_x := to_cell.x - from_cell.x
	print("to_cell → 当前: ", to_cell.x, " from_cell: ", from_cell.x)
	var target_scale_x: int = signi(dir_x) if dir_x != 0 else signi(VisualsNode.scale.x)
	
	var current_scale_x := signi(VisualsNode.scale.x)
	
	print("翻转调试 → 当前: ", current_scale_x, " 目标: ", target_scale_x)
	# 方向没变，不需要翻转
	if current_scale_x == target_scale_x:
		if on_complete.is_valid():
			on_complete.call()
		return
		
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	#
	## 可选：带一点 squash & stretch 的翻转动画（像素风非常推荐）
	tween.tween_property(VisualsNode, "scale:x", target_scale_x * 0.75, duration * 1.5)
	tween.tween_property(VisualsNode, "scale:x", target_scale_x, duration * 2)
	#
	## 完成后执行回调
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
	
	# 如果你只想要最简单的线性翻转，可以改成下面这行：
	# tween.tween_property(sprite, "scale:x", target_scale_x, duration)
# ─── 工具方法 ────────────────────────────────────────────────

## 返回单位名称，方便调试输出。
#func get_display_name() -> String:
	#return unit_name
#



#func _ready() -> void:
	#sprite2D.material = outline_material  # 默认应用，但宽度=0无效果
	## 关键：duplicate 成唯一实例
	#sprite2D.material = sprite2D.material.duplicate() as ShaderMaterial
	#clear_outline_hight_light(self)
	#
	##Events.piece_selected.connect(set_outline_hight_light)
	##Events.piece_deselected.connect(clear_outline_hight_light)
	#
	#add_to_group("pieces")
	#pass
# 高亮
func set_outline_hight_light():
	VisualsNode.material.set_shader_parameter("outline_width", MapConfig.outline_color_high_width)  # 显示描边
	VisualsNode.material.set_shader_parameter("line_color", MapConfig.outline_color_high_light)  # 黄色高亮
	pass
	
func clear_outline_hight_light():
	VisualsNode.material.set_shader_parameter("outline_width", 0)  # 显示描边
	pass
	
