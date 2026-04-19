extends Node2D

const FOG_COLOR := Color(0.04, 0.04, 0.08)
const GRID_COLOR := Color(0.18, 0.22, 0.32, 0.5)

func _ready() -> void:
	GameManager.telescope_upgraded.connect(_on_telescope_upgraded)

func _on_telescope_upgraded(_level: int) -> void:
	queue_redraw()

func _draw() -> void:
	var tile_size: int = get_parent().TILE_SIZE
	var map_radius: int = get_parent().MAP_RADIUS
	var half := tile_size / 2.0
	var extent := (map_radius + 0.5) * tile_size

	for tx in range(-map_radius, map_radius + 1):
		for ty in range(-map_radius, map_radius + 1):
			if max(abs(tx), abs(ty)) > GameManager.get_telescope_range(map_radius):
				draw_rect(
					Rect2(tx * tile_size - half, ty * tile_size - half, tile_size, tile_size),
					FOG_COLOR
				)

	for n in range(-map_radius, map_radius + 2):
		var pos := n * tile_size - half
		draw_line(Vector2(pos, -extent), Vector2(pos, extent), GRID_COLOR, 1.0)
		draw_line(Vector2(-extent, pos), Vector2(extent, pos), GRID_COLOR, 1.0)
