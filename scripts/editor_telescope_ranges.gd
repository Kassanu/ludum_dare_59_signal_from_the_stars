@tool
extends Node2D

# Draws telescope range outlines for each upgrade level in the editor.
# Add as a child of StarMap alongside FogOfWar.

const TILE_SIZE := 256
const MAP_RADIUS := 10
const UPGRADE_COSTS_COUNT := 4  # matches GameManager.TELESCOPE_UPGRADE_COSTS.size()

const RANGE_COLORS := [
	Color(1.0, 0.3, 0.3, 0.9),   # level 0 (starting)
	Color(1.0, 0.7, 0.2, 0.9),   # level 1
	Color(0.4, 1.0, 0.4, 0.9),   # level 2
	Color(0.2, 0.7, 1.0, 0.9),   # level 3
	Color(0.8, 0.4, 1.0, 0.9),   # level 4 (max / full map)
]

func _get_telescope_range(level: int) -> int:
	if level >= UPGRADE_COSTS_COUNT:
		return MAP_RADIUS
	return max(1, level * MAP_RADIUS / UPGRADE_COSTS_COUNT)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var font := ThemeDB.fallback_font
	var half := TILE_SIZE / 2.0
	for level in range(UPGRADE_COSTS_COUNT + 1):
		var r := _get_telescope_range(level)
		var color: Color = RANGE_COLORS[level]
		var size := (r * 2 + 1) * TILE_SIZE
		var top_left := Vector2(-r * TILE_SIZE - half, -r * TILE_SIZE - half)
		draw_rect(Rect2(top_left, Vector2(size, size)), color, false, 2.0)
		var label := "L%d (r=%d)" % [level, r]
		draw_string(font, top_left + Vector2(4, -4), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
