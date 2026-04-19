class_name WaveformDisplay
extends Control

const SAMPLE_COUNT := 200
const TIME_SPEED := 1.5

var _signal_data: SignalData = null
var _noise_amount: float = 1.0  # 0 = clean, 1 = max noise
var _current_amplitude: float = 0.5
var _current_frequency: float = 0.5  # normalized 0-1
var _current_phase: float = 0.5      # normalized 0-1
var _is_locked: bool = false
var _time: float = 0.0
var _seed_offset: float = 0.0
var _show_ghost: bool = false
var _ghost_amplitude: float = 0.5
var _ghost_frequency: float = 0.5
var _ghost_phase: float = 0.5

func setup(data: SignalData) -> void:
	_signal_data = data
	_seed_offset = float(data.wave_seed & 0xFFFF) * 0.0001
	_show_ghost = false

	if data.is_modulated or data.is_decoded:
		_noise_amount = 0.0
		_current_amplitude = data.mod_amplitude_target if data.mod_uses_amplitude else 0.65
		_current_frequency = data.mod_frequency_target if data.mod_uses_frequency else 0.5
		_current_phase = data.mod_phase_target if data.mod_uses_phase else 0.0
		_is_locked = true
	elif data.is_filtered:
		_noise_amount = 0.0
		_current_amplitude = 0.5
		_current_frequency = 0.5
		_current_phase = 0.5
		_is_locked = false
	else:
		_noise_amount = 1.0
		_current_amplitude = 0.5
		_current_frequency = 0.5
		_current_phase = 0.5
		_is_locked = false

func enable_mod_ghost(data: SignalData) -> void:
	_ghost_amplitude = data.mod_amplitude_target if data.mod_uses_amplitude else 0.65
	_ghost_frequency = data.mod_frequency_target if data.mod_uses_frequency else 0.5
	_ghost_phase = data.mod_phase_target if data.mod_uses_phase else 0.0
	_show_ghost = true

func set_filter_values(knob_a: float, knob_b: float, slider: float = 0.0) -> void:
	if _signal_data == null:
		return
	var total := _knob_dist(knob_a, _signal_data.filter_knob_a_target)
	total += _knob_dist(knob_b, _signal_data.filter_knob_b_target)
	var count := 2
	if _signal_data.filter_has_slider:
		var range_size := _signal_data.filter_slider_max - _signal_data.filter_slider_min
		if range_size > 0.0:
			total += abs(slider - _signal_data.filter_slider_target) / range_size
			count += 1
	_noise_amount = clampf(total / float(count), 0.0, 1.0)

func set_mod_values(amplitude: float, frequency: float, phase: float) -> void:
	_current_amplitude = amplitude
	_current_frequency = frequency
	_current_phase = phase

func set_locked(locked: bool) -> void:
	_is_locked = locked

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var mid_y := h * 0.5

	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.04, 0.06, 0.10))
	draw_line(Vector2(0.0, mid_y), Vector2(w, mid_y), Color(0.10, 0.15, 0.25, 0.5), 1.0)

	if _signal_data == null:
		return

	var vis_freq: float = _signal_data.visual_frequency

	var amplitude: float
	if _signal_data.mod_uses_amplitude:
		amplitude = _current_amplitude
	else:
		amplitude = 0.65

	var freq_cycles: float
	if _signal_data.mod_uses_frequency:
		freq_cycles = lerp(vis_freq * 0.4, vis_freq * 2.5, _current_frequency)
	else:
		freq_cycles = vis_freq

	var phase_rad: float
	if _signal_data.mod_uses_phase:
		phase_rad = _current_phase * TAU
	else:
		phase_rad = 0.0

	var wave_color: Color
	if _is_locked:
		wave_color = Color(0.2, 1.0, 0.45)
	else:
		var brightness :float= lerp(0.55, 1.0, 1.0 - _noise_amount * 0.6)
		wave_color = Color(0.25 * brightness, 0.6 * brightness, brightness)

	var amp_px := h * 0.38
	var scroll := _time * TIME_SPEED + _seed_offset
	var points := PackedVector2Array()
	points.resize(SAMPLE_COUNT)

	if _show_ghost and not _is_locked:
		var ghost_freq: float = lerp(vis_freq * 0.4, vis_freq * 2.5, _ghost_frequency) if _signal_data.mod_uses_frequency else vis_freq
		var ghost_phase: float = _ghost_phase * TAU if _signal_data.mod_uses_phase else 0.0
		var ghost_amp: float = _ghost_amplitude if _signal_data.mod_uses_amplitude else 0.65
		var ghost_points := PackedVector2Array()
		ghost_points.resize(SAMPLE_COUNT)
		for i in SAMPLE_COUNT:
			var t := float(i) / float(SAMPLE_COUNT - 1)
			var y := sin(TAU * ghost_freq * t + ghost_phase + scroll) * ghost_amp
			ghost_points[i] = Vector2(t * w, mid_y - y * amp_px)
		draw_polyline(ghost_points, Color(0.3, 0.7, 1.0, 0.2), 1.0, true)

	for i in SAMPLE_COUNT:
		var t := float(i) / float(SAMPLE_COUNT - 1)
		var y_wave := sin(TAU * freq_cycles * t + phase_rad + scroll) * amplitude
		var noise_y := 0.0
		if _noise_amount > 0.001:
			var s := _seed_offset
			var n := sin(t * 13.7 * TAU + _time * 7.3 + s * 3.1) * 0.45
			n += sin(t * 31.1 * TAU - _time * 11.9 + s * 7.7) * 0.30
			n += sin(t *  7.3 * TAU + _time * 23.1 + s * 1.3) * 0.25
			noise_y = n * _noise_amount
		points[i] = Vector2(t * w, mid_y - (y_wave + noise_y) * amp_px)

	draw_polyline(points, wave_color, 1.5, true)

func _knob_dist(a: float, b: float) -> float:
	var diff :float= abs(a - b)
	return min(diff, 360.0 - diff) / 180.0
