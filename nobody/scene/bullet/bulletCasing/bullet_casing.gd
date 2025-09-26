extends GPUParticles2D

var _tick = 0
func _physics_process(delta):
	_tick+=delta
	if _tick>=0.5:
		speed_scale = 0
		pass
