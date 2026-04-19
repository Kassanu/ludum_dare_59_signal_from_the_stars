extends Node2D

const MAP_RADIUS := 10
const TILE_SIZE := 256

const LAYERS := [
	[600, 0.5, 1.2, 0.15, 0.45],
	[250, 1.0, 2.0, 0.25, 0.65],
	[80,  1.5, 3.0, 0.50, 0.90],
]

var _stars: Array = []

func _ready() -> void:
	_generate()

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var half := (MAP_RADIUS + 1) * TILE_SIZE
	_stars.clear()

	for layer in LAYERS:
		var count: int = layer[0]
		var r_min: float = layer[1]
		var r_max: float = layer[2]
		var a_min: float = layer[3]
		var a_max: float = layer[4]
		for _i in count:
			_stars.append({
				"pos": Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half)),
				"radius": rng.randf_range(r_min, r_max),
				"alpha": rng.randf_range(a_min, a_max),
			})

	queue_redraw()

func _draw() -> void:
	for star in _stars:
		var color := Color(1.0, 1.0, 1.0, star["alpha"])
		draw_circle(star["pos"], star["radius"], color)
