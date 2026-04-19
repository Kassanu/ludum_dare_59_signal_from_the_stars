extends Node2D

const TILE_SIZE := 256
const MAP_RADIUS := 10
const CLICK_MAX_DRIFT := 5.0
const SAMPLE_RATE := 44100.0
const BEEP_FREQUENCY := 880.0
const PROXIMITY_FREQUENCY := 440.0
const LOW_VOLUME_DB := -80.0
const NOISE_VOLUME_DB := -30.0
const TONE_VOLUME_DB := -10.0

@onready var _camera: Camera2D = $Camera2D
@onready var _markers: Node2D = $SignalMarkers
@onready var _noise_player: AudioStreamPlayer = $NoisePlayer
@onready var _tone_player: AudioStreamPlayer = $TonePlayer

const _marker_scene := preload("res://scenes/SignalMarker.tscn")

var _dragging := false
var _drag_start := Vector2.ZERO
var _cam_start := Vector2.ZERO
var _input_enabled := true

var _noise_playback: AudioStreamGeneratorPlayback
var _tone_playback: AudioStreamGeneratorPlayback
var _tone_phase := 0.0
var _tone_frequency := PROXIMITY_FREQUENCY
var _tone_volume := 0.0

const SCAN_PING_DURATION := 1.5
const SCAN_PING_RADIUS := 80.0
const SCAN_ARC_HALF_ANGLE := 0.45  # radians, ~26 degrees each side

class ScanPing:
	var world_pos: Vector2
	var direction: Vector2  # zero if no signal within proximity radius
	var proximity_strength: float  # 0..1, how close the nearest signal is
	var age: float

var _scan_pings: Array = []

func _ready() -> void:
	var edge := int((MAP_RADIUS + 0.5) * TILE_SIZE)  # camera limits include the half-tile border
	_camera.limit_left = -edge
	_camera.limit_right = edge
	_camera.limit_top = -edge
	_camera.limit_bottom = edge

	GameManager.signal_loaded.connect(_on_signal_loaded)
	GameManager.signal_unloaded.connect(_on_signal_unloaded)
	GameManager.panel_opened.connect(_on_panel_opened)
	GameManager.panel_closed.connect(_on_panel_closed)

	for sig in GameManager.signals:
		if sig.is_found:
			_spawn_marker(sig)

	_setup_audio()

func _setup_audio() -> void:
	for player in [_noise_player, _tone_player]:
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = SAMPLE_RATE
		stream.buffer_length = 0.1
		player.stream = stream
		player.play()
	_noise_playback = _noise_player.get_stream_playback()
	_tone_playback = _tone_player.get_stream_playback()
	_noise_player.volume_db = LOW_VOLUME_DB
	_tone_player.volume_db = LOW_VOLUME_DB

func _process(delta: float) -> void:
	_fill_noise_buffer()
	_fill_tone_buffer()
	if _scan_pings.size() > 0:
		for ping in _scan_pings:
			ping.age += delta
		_scan_pings = _scan_pings.filter(func(p): return p.age < SCAN_PING_DURATION)
		queue_redraw()

func _fill_noise_buffer() -> void:
	var frames := _noise_playback.get_frames_available()
	for i in frames:
		var s := randf_range(-1.0, 1.0)
		_noise_playback.push_frame(Vector2(s, s))

func _fill_tone_buffer() -> void:
	var frames := _tone_playback.get_frames_available()
	for i in frames:
		var s := sin(_tone_phase) * _tone_volume
		_tone_playback.push_frame(Vector2(s, s))
		_tone_phase += TAU * _tone_frequency / SAMPLE_RATE
	_tone_phase = fmod(_tone_phase, TAU)

func _play_scan_audio(found: bool, proximity_dist: float) -> void:
	if found:
		_tone_frequency = BEEP_FREQUENCY
		_tone_volume = 1.0
		_noise_player.volume_db = LOW_VOLUME_DB
		_tone_player.volume_db = TONE_VOLUME_DB
		await get_tree().create_timer(0.6).timeout
		_tone_player.volume_db = LOW_VOLUME_DB
	else:
		_noise_player.volume_db = NOISE_VOLUME_DB
		if proximity_dist < GameManager.PROXIMITY_RADIUS:
			_tone_frequency = PROXIMITY_FREQUENCY
			_tone_volume = 1.0 - (proximity_dist / GameManager.PROXIMITY_RADIUS)
			_tone_player.volume_db = TONE_VOLUME_DB
		else:
			_tone_player.volume_db = LOW_VOLUME_DB
		await get_tree().create_timer(1.5).timeout
		_noise_player.volume_db = LOW_VOLUME_DB
		_tone_player.volume_db = LOW_VOLUME_DB

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
	if max(abs(tile.x), abs(tile.y)) > GameManager.telescope_level:
		return
	var found := GameManager.try_load_nearest_signal(world_pos)
	if found:
		_spawn_marker(found)
		_play_scan_audio(true, 0.0)
	else:
		var dist := GameManager.get_nearest_unscanned_distance(world_pos)
		_play_scan_audio(false, dist)
		_spawn_scan_ping(world_pos, dist)

func _spawn_scan_ping(world_pos: Vector2, proximity_dist: float) -> void:
	var ping := ScanPing.new()
	ping.world_pos = world_pos
	ping.age = 0.0
	if proximity_dist < GameManager.PROXIMITY_RADIUS:
		ping.direction = GameManager.get_nearest_unscanned_direction(world_pos)
		ping.proximity_strength = 1.0 - (proximity_dist / GameManager.PROXIMITY_RADIUS)
	else:
		ping.direction = Vector2.ZERO
		ping.proximity_strength = 0.0
	_scan_pings.append(ping)
	queue_redraw()

func _draw() -> void:
	for ping in _scan_pings:
		var t :float= ping.age / SCAN_PING_DURATION
		var alpha := 1.0 - t
		var radius := SCAN_PING_RADIUS * (0.5 + 0.5 * t)
		if ping.direction != Vector2.ZERO:
			var arc_alpha :float= alpha * ping.proximity_strength * 0.75
			var center_angle :float= ping.direction.angle()
			var arc_color := Color(0.4, 0.8, 1.0, arc_alpha)
			draw_arc(ping.world_pos, radius, center_angle - SCAN_ARC_HALF_ANGLE, center_angle + SCAN_ARC_HALF_ANGLE, 16, arc_color, 2.5)

func _spawn_marker(data: SignalData) -> void:
	var marker: SignalMarker = _marker_scene.instantiate()
	marker.position = data.map_position
	marker.signal_data = data
	marker.clicked.connect(GameManager.load_signal)
	_markers.add_child(marker)

func _set_blocked(blocked: bool) -> void:
	_input_enabled = !blocked
	_dragging = false

func _on_signal_loaded(_data: SignalData) -> void:
	_set_blocked(true)

func _on_signal_unloaded() -> void:
	_set_blocked(false)

func _on_panel_opened() -> void:
	_set_blocked(true)

func _on_panel_closed() -> void:
	_set_blocked(false)
