extends Area2D

# 子弹脚本

var speed: float = 600.0
var velocity: Vector2

func _ready():
	# 初始化子弹方向
	velocity = Vector2(cos(rotation), sin(rotation)) * speed
	
	# 设置销毁定时器
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# 移动子弹
	position += velocity * delta

func _on_area_entered(area):
	# 击中敌人时销毁
	if area.is_in_group("enemies"):
		area.queue_free()
		queue_free()

func _on_timer_timeout():
	# 超时销毁
	queue_free()
