extends Node2D

const TILE_SIZE := 256
const MAP_RADIUS := 10
const CLICK_MAX_DRIFT := 5.0

@onready var _camera: Camera2D = $Camera2D
@onready var _fog: Node2D = $FogOfWar
@onready var _markers: Node2D = $SignalMarkers

const _marker_scene := preload("res://scenes/SignalMarker.tscn")

var _dragging := false
var _drag_start := Vector2.ZERO
var _cam_start := Vector2.ZERO
var _input_enabled := true

func _ready() -> void:
	var edge := int((MAP_RADIUS + 0.5) * TILE_SIZE)  # camera limits include the half-tile border
	_camera.limit_left = -edge
	_camera.limit_right = edge
	_camera.limit_top = -edge
	_camera.limit_bottom = edge

	GameManager.signal_loaded.connect(_on_signal_loaded)
	GameManager.signal_unloaded.connect(_on_signal_unloaded)

	for sig in GameManager.signals:
		if sig.is_found:
			_spawn_marker(sig)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start = event.position
			_cam_start = _camera.position
		else:
			if _dragging and event.position.distance_to(_drag_start) < CLICK_MAX_DRIFT:
				_handle_click()
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		_camera.position = _cam_start - (event.position - _drag_start)

func _handle_click() -> void:
	var world_pos := get_global_mouse_position()
	var tile := (world_pos / TILE_SIZE).round()
	if max(abs(tile.x), abs(tile.y)) > _fog.telescope_level:
		return
	var found := GameManager.try_load_nearest_signal(world_pos)
	if found:
		_spawn_marker(found)

func _spawn_marker(data: SignalData) -> void:
	var marker: SignalMarker = _marker_scene.instantiate()
	marker.position = data.map_position
	marker.signal_data = data
	marker.clicked.connect(GameManager.load_signal)
	_markers.add_child(marker)

func _on_signal_loaded(_data: SignalData) -> void:
	_input_enabled = false
	_dragging = false

func _on_signal_unloaded() -> void:
	_input_enabled = true
