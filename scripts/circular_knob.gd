extends Control
class_name CircularKnob

signal value_changed(value: float)

var value: float = 180.0:
	set(v):
		var new_val := fmod(v, 360.0)
		if new_val < 0.0:
			new_val += 360.0
		if abs(new_val - value) > 0.001:
			value = new_val
			value_changed.emit(value)
			queue_redraw()

var editable: bool = true

var _dragging := false
var _last_angle := 0.0

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 4.0
	draw_circle(center, radius, Color(0.15, 0.15, 0.2))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.5, 0.5, 0.65), 2.0)
	var tick_inner := center + Vector2(0.0, -(radius - 2.0))
	var tick_outer := center + Vector2(0.0, -radius)
	# 12 o'clock tick mark
	draw_line(tick_inner, tick_outer, Color(0.5, 0.5, 0.65), 2.0)
	var angle := deg_to_rad(value - 90.0)
	var tip := center + Vector2(cos(angle), sin(angle)) * (radius * 0.7)
	draw_line(center, tip, Color(0.3, 0.6, 1.0), 3.0)
	draw_circle(tip, 5.0, Color(0.5, 0.75, 1.0))

func _gui_input(event: InputEvent) -> void:
	if not editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_last_angle = _angle_from(event.position)
	elif event is InputEventMouseMotion and _dragging:
		var cur := _angle_from(event.position)
		var delta := _wrap_diff(cur - _last_angle)
		_last_angle = cur
		value = value + rad_to_deg(delta)

func _angle_from(pos: Vector2) -> float:
	return (pos - size / 2.0).angle()

func _wrap_diff(a: float) -> float:
	while a > PI:
		a -= TAU
	while a < -PI:
		a += TAU
	return a
