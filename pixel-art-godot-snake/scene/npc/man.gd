extends CharacterBody2D
enum State{
	peasant,
	fisher,
}

@export var SPEED = 50.0                # 速度
@export var belongedHouseNode = null    # 所属房屋
@export var workerType = State.peasant  # npc类型
@export var damage = 5                  # 伤害


func _physics_process(delta: float) -> void:
	pass
