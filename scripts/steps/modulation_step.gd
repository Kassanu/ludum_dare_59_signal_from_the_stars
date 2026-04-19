extends Control

signal step_completed
signal modulation_changed(amplitude: float, frequency: float, phase: float)

const LOCK_TOLERANCE := 0.05
const SOLVED_FREQUENCY := 880.0

var signal_data: SignalData

@onready var _amp_col: VBoxContainer = $VBoxContainer/ColContainer/AmpCol
@onready var _freq_col: VBoxContainer = $VBoxContainer/ColContainer/FreqCol
@onready var _phase_col: VBoxContainer = $VBoxContainer/ColContainer/PhaseCol
@onready var _amp_slider: VSlider = $VBoxContainer/ColContainer/AmpCol/AmpSlider
@onready var _freq_slider: VSlider = $VBoxContainer/ColContainer/FreqCol/FreqSlider
@onready var _phase_slider: VSlider = $VBoxContainer/ColContainer/PhaseCol/PhaseSlider

var _audio_player: AudioStreamPlayer
var _locked := false

func _ready() -> void:
	_setup_audio()
	_amp_col.visible = signal_data.mod_uses_amplitude and GameManager.modulator_level >= 1
	_freq_col.visible = signal_data.mod_uses_frequency and GameManager.modulator_level >= 2
	_phase_col.visible = signal_data.mod_uses_phase and GameManager.modulator_level >= 3
	_amp_slider.value_changed.connect(func(_v): _on_values_changed())
	_freq_slider.value_changed.connect(func(_v): _on_values_changed())
	_phase_slider.value_changed.connect(func(_v): _on_values_changed())
	_emit_current()
	_check_lock()

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
	var dists: Array[float] = []
	if signal_data.mod_uses_amplitude and GameManager.modulator_level >= 1:
		dists.append(abs(_amp_slider.value - signal_data.mod_amplitude_target))
	if signal_data.mod_uses_frequency and GameManager.modulator_level >= 2:
		dists.append(abs(_freq_slider.value - signal_data.mod_frequency_target))
	if signal_data.mod_uses_phase and GameManager.modulator_level >= 3:
		dists.append(abs(_phase_slider.value - signal_data.mod_phase_target))
	if dists.is_empty():
		return 1.0
	return clamp(1.0 - (dists.max() / 0.5), 0.0, 1.0)

func _on_values_changed() -> void:
	_emit_current()
	_check_lock()
	if not _locked:
		_play_tone(lerp(220.0, 660.0, _get_closeness()), 0.15)

func _emit_current() -> void:
	modulation_changed.emit(_amp_slider.value, _freq_slider.value, _phase_slider.value)

func _check_lock() -> void:
	if signal_data.mod_uses_amplitude:
		if GameManager.modulator_level < 1 or abs(_amp_slider.value - signal_data.mod_amplitude_target) > LOCK_TOLERANCE:
			return
	if signal_data.mod_uses_frequency:
		if GameManager.modulator_level < 2 or abs(_freq_slider.value - signal_data.mod_frequency_target) > LOCK_TOLERANCE:
			return
	if signal_data.mod_uses_phase:
		if GameManager.modulator_level < 3 or abs(_phase_slider.value - signal_data.mod_phase_target) > LOCK_TOLERANCE:
			return
	_lock()

func _lock() -> void:
	_locked = true
	_amp_slider.editable = false
	_freq_slider.editable = false
	_phase_slider.editable = false
	signal_data.is_modulated = true
	_play_tone(SOLVED_FREQUENCY, 0.4)
	step_completed.emit()
