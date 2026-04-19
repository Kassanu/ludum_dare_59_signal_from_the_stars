extends Sprite2D

var t: float = 0.0

func _process(delta: float) -> void:
	t += delta
	modulate.a = 0.15 + 0.1 * sin(t * 2.0)
