extends Control

signal step_completed
signal filter_changed(knob_a: float, knob_b: float, slider: float)

const LOCK_TOLERANCE := 0.08
const SOLVED_FREQUENCY := 880.0

var signal_data: SignalData

@onready var _knob_a: CircularKnob = $VBoxContainer/KnobsRow/KnobA
@onready var _knob_b: CircularKnob = $VBoxContainer/KnobsRow/KnobB
@onready var _filter_slider: HSlider = $VBoxContainer/SliderRow/FilterSlider
@onready var _slider_row: HBoxContainer = $VBoxContainer/SliderRow

var _audio_player: AudioStreamPlayer
var _locked := false

func _ready() -> void:
	_setup_audio()
	_slider_row.visible = signal_data.filter_has_slider and GameManager.filter_level >= 2
	_knob_a.value_changed.connect(func(_v): _on_values_changed())
	_knob_b.value_changed.connect(func(_v): _on_values_changed())
	_filter_slider.value_changed.connect(func(_v): _on_values_changed())
	_show_upgrade_hints()
	_emit_current()

func _show_upgrade_hints() -> void:
	if signal_data.filter_has_slider and GameManager.filter_level < 2:
		var label := Label.new()
		label.text = "Upgrade filter to unlock additional controls"
		label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		$VBoxContainer.add_child(label)

func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.volume_db = -14.0
	add_child(_audio_player)

func _play_tone(frequency: float, duration: float) -> void:
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var fade := int(sample_rate * 0.02)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / sample_rate
		var env := 1.0
		if i < fade:
			env = float(i) / fade
		elif i > samples - fade:
			env = float(samples - i) / fade
		var s := int(sin(TAU * frequency * t) * env * 0.25 * 32767.0)
		data.encode_s16(i * 2, clamp(s, -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	_audio_player.stream = wav
	_audio_player.play()

func _get_closeness() -> float:
	var dist_a := _knob_dist(_knob_a.value, signal_data.filter_knob_a_target)
	var dist_b := _knob_dist(_knob_b.value, signal_data.filter_knob_b_target)
	var worst :float= max(dist_a, dist_b)
	return clamp(1.0 - (worst / 0.5), 0.0, 1.0)

func _on_values_changed() -> void:
	_emit_current()
	_check_lock()
	if not _locked:
		_play_tone(lerp(220.0, 660.0, _get_closeness()), 0.15)

func _emit_current() -> void:
	filter_changed.emit(_knob_a.value, _knob_b.value, _filter_slider.value)

func _check_lock() -> void:
	if _knob_dist(_knob_a.value, signal_data.filter_knob_a_target) > LOCK_TOLERANCE:
		return
	if _knob_dist(_knob_b.value, signal_data.filter_knob_b_target) > LOCK_TOLERANCE:
		return
	if signal_data.filter_has_slider:
		if GameManager.filter_level < 2:
			return
		var range_size := signal_data.filter_slider_max - signal_data.filter_slider_min
		if range_size > 0.0 and abs(_filter_slider.value - signal_data.filter_slider_target) / range_size > LOCK_TOLERANCE:
			return
	_lock()

func _lock() -> void:
	_locked = true
	_knob_a.editable = false
	_knob_b.editable = false
	_filter_slider.editable = false
	signal_data.is_filtered = true
	_play_tone(SOLVED_FREQUENCY, 0.4)
	step_completed.emit()

func _knob_dist(a: float, b: float) -> float:
	var diff: float = abs(a - b)
	return min(diff, 360.0 - diff) / 180.0
