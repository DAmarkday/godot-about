extends Area2D
class_name VillageArea
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


#func _calculate_normal(collision_point):
	#var shape = $CollisionShape2D.shape as RectangleShape2D
	#var shape_pos = $CollisionShape2D.global_position
	#var extents = shape.extents
	#var left = shape_pos.x - extents.x
	#var right = shape_pos.x + extents.x
	#var top = shape_pos.y - extents.y
	#var bottom = shape_pos.y + extents.y
#
	## 根据碰撞点判断法线
	#if abs(collision_point.x - left) < 10:
		#return Vector2(1, 0) # 左墙，法线向右
	#elif abs(collision_point.x - right) < 10:
		#return Vector2(-1, 0) # 右墙，法线向左
	#elif abs(collision_point.y - top) < 10:
		#return Vector2(0, 1) # 上墙，法线向下
	#elif abs(collision_point.y - bottom) < 10:
		#return Vector2(0, -1) # 下墙，法线向上
	#return Vector2(0, 0) # 默认（避免错误）

# 调试代码
#var draw_normal: Vector2
#var draw_reflection: Vector2
#var draw_position: Vector2
#func _draw() -> void:
	#if draw_normal:
		#draw_line(to_local(draw_position), to_local(draw_position + draw_normal * 50), Color.RED, 2.0)
		#draw_line(to_local(draw_position), to_local(draw_position + draw_reflection * 50), Color.GREEN, 2.0)
		
func _on_area_entered(area: Area2D) -> void:
	# 如果在反弹点有时存在重叠可能是误差导致的问题
	if area is BaseBulletArea:
		var bullet = area.get_parent() as BaseBullet
		#var collision_point = node.global_position
		#var normal = _calculate_normal(collision_point)
		# 计算子弹的反弹速度
		#node.velocity = node.velocity.bounce(normal).normalized() * node.speed
		bullet.visible =false
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
		bullet.global_position - bullet.velocity.normalized() * 20,
		bullet.global_position + bullet.velocity.normalized() * 20
		)
		query.exclude = [bullet]
		query.collision_mask = collision_mask
		var collision = space_state.intersect_ray(query)
			
		if collision:
			var normal = collision.normal
			var incident = bullet.velocity.normalized()
			# 计算反射方向：R = I - 2 * (I · N) * N
			var reflection = incident - 2 * incident.dot(normal) * normal
			#print("bullet is ",bullet.position,collision.position)
			#pivot_offset
			await get_tree().process_frame
			# 找到镜像反射的点
			var w=bullet.find_symmetric_point(bullet.global_position,normal,collision.position)
			bullet.set_direction(reflection)
			bullet.global_position = w
			bullet.visible = true
			
			#调试：绘制法线和反射方向
			#queue_redraw()
			#draw_normal = normal
			#draw_reflection = reflection
			#draw_position = collision.position
			#await get_tree().create_timer(0.1).timeout
			#queue_redraw()
		else:
			print("No collision detected")
	pass # Replace with function body.
	
