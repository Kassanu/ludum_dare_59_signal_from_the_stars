@tool
extends Node2D

const SIGNAL_DIR := "res://resources/signals/"
const MARKER_RADIUS := 18.0
const FONT_SIZE := 14

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var dir := DirAccess.open(SIGNAL_DIR)
	if not dir:
		return
	var font := ThemeDB.fallback_font
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(SIGNAL_DIR + file_name)
			if res and res.get("map_position") != null:
				var pos: Vector2 = res.map_position
				var label: String = res.get("name") if res.get("name") else file_name
				var color := Color(1.0, 0.4, 0.1, 0.85) if file_name.begins_with("flavor_") else Color(0.2, 0.8, 1.0, 0.85)
				draw_circle(pos, MARKER_RADIUS, color)
				draw_arc(pos, MARKER_RADIUS, 0, TAU, 24, Color.WHITE, 1.5)
				draw_string(font, pos + Vector2(MARKER_RADIUS + 4, 5), label,
						HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		file_name = dir.get_next()
