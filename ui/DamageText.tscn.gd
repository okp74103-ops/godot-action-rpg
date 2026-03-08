extends Label

var velocity := Vector2(0, -40)
var lifetime := 0.8

func _ready():
	modulate = Color(1, 0.2, 0.2)
	scale = Vector2.ONE

func _process(delta):
	position += velocity * delta
	modulate.a -= delta / lifetime

	if modulate.a <= 0:
		queue_free()
