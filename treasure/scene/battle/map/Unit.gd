extends Node2D
class_name Unit

## 基础棋子类 - 所有棋子的父类

@export var unit_name: String = "士兵"
@export var movement_range: int = 5  # 移动力
@export var attack_range: int = 1    # 攻击范围
@export var max_hp: int = 100
@export var current_hp: int = 100

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var grid_position: Vector2i = Vector2i.ZERO
var team: int = 0  # 0=玩家, 1=敌人


func _ready() -> void:
	# 播放待机动画
	if sprite != null:
		sprite.play("idle")


## 受到伤害
func take_damage(damage: int) -> void:
	current_hp = max(0, current_hp - damage)
	
	if current_hp <= 0:
		die()


## 死亡
func die() -> void:
	# 播放死亡动画
	if sprite != null:
		sprite.play("death")
		await sprite.animation_finished
	
	queue_free()


## 移动到格子
func move_to_cell(cell: Vector2i, world_pos: Vector2) -> void:
	grid_position = cell
	
	# 使用 Tween 平滑移动
	var tween = create_tween()
	tween.tween_property(self, "position", world_pos, 0.3)


## 攻击目标
func attack(target: Unit) -> void:
	# 播放攻击动画
	if sprite != null:
		sprite.play("attack")
		await sprite.animation_finished
		sprite.play("idle")
	
	# 造成伤害（简化计算）
	var damage = 20
	target.take_damage(damage)
