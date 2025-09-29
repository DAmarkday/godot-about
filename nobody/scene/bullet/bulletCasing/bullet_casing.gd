extends GPUParticles2D

var _tick = 0
func _physics_process(delta):
	_tick+=delta
	if _tick>=0.5:
		#speed_scale = 0
		speed_scale = 0
		process_material.gravity = Vector3(process_material.gravity.x,-process_material.gravity.y,process_material.gravity.z)
		if _tick>=1:
			speed_scale = 0
		pass
