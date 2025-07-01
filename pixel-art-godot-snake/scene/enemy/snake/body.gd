extends CharacterBody2D
class_name BossSnakeBody

@onready var sprite2D = $Sprite2D
var enemy_data:EnemyBossBodyData

@onready var materialD = sprite2D.material


func _ready():
	enemy_data = EnemyBossBodyData.new()
	#sprite2D.material = sprite2D.material.duplicate() # 确保材质独立
	#enemy_data.on_hit.connect(on_hit)
	#enemy_data.on_death.connect(on_death)
	
	pass



func on_hit(_damage):
	#current_state = State.HIT
	#
	#Game.show_label(self,'-%s' %_damage)
	#hit_audio.play()
	#
	#anim.play("hit")
	#await anim.animation_finished
	#current_state = State.IDLE
	flash()
	#var tween = create_tween()
	#tween.tween_property(sprite2D,'modulate',Color.WHITE,0.1)
	#tween.tween_property(sprite2D,'modulate',Color(1,1,1,1),0.1)
	pass
	
func flash():
	# 使用 Tween 动画控制 flash_amount
	var tween = sprite2D.create_tween()
	tween.tween_property(materialD, "shader_parameter/flash_amount", 1.0, 0.1) # 快速变白
	tween.tween_property(materialD, "shader_parameter/flash_amount", 0.0, 0.3) # 缓慢恢复


func on_death():
	pass
	#if current_state == State.DEATH:
		#return
	#current_state = State.DEATH
	#coll.call_deferred("set_disabled",true)
	#shadow.hide()
	#anim.play('death')
	#await anim.animation_finished
	#
	#EnemyManager.handleEnemyCounts.emit(-1)
	#queue_free()

	


#func _on_area_2d_area_entered(area: Area2D) -> void:
	##print("333333")
	#if area is BaseBulletArea:
		#print("1212")
		#set_physics_process(false)
		##queue_free()
		#area.clear()
		#pass
	#
	#pass # Replace with function body.
