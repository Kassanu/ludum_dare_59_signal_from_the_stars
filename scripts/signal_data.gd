class_name SignalData
extends Resource

# --- Identity ---
@export var id: String = ""
@export var name: String = ""
@export var map_position: Vector2 = Vector2.ZERO
@export var message: String = ""
@export var money_reward: int = 0

# --- Progress ---
@export var is_found: bool = false
@export var is_filtered: bool = false
@export var is_modulated: bool = false
@export var is_decoded: bool = false

# --- Filter Step ---
@export_range(0.0, 360.0) var filter_knob_a_target: float = 0.0
@export_range(0.0, 360.0) var filter_knob_b_target: float = 0.0
@export var filter_has_slider: bool = false
@export var filter_slider_min: float = -1.0
@export var filter_slider_max: float = 1.0
@export var filter_slider_target: float = 0.0

# --- Modulation Step ---
@export var mod_uses_amplitude: bool = false
@export var mod_amplitude_target: float = 0.0

@export var mod_uses_frequency: bool = false
@export var mod_frequency_target: float = 0.0

@export var mod_uses_phase: bool = false
@export var mod_phase_target: float = 0.0

# --- Decode Step ---
@export var decode_template: Array[String] = []
@export var decode_word_rewards: Array[String] = []

# --- Waveform Display ---
@export_range(1.0, 5.0) var visual_frequency: float = 2.0
@export var wave_seed: int = 0

# --- Randomization ---
@export var randomize_targets: bool = true

func generate_targets() -> void:
	if not randomize_targets:
		return
	wave_seed = randi()
	filter_knob_a_target = randf_range(0.0, 360.0)
	filter_knob_b_target = randf_range(0.0, 360.0)
	if filter_has_slider:
		filter_slider_target = randf_range(filter_slider_min, filter_slider_max)
	if mod_uses_amplitude:
		mod_amplitude_target = randf_range(0.1, 1.0)
	if mod_uses_frequency:
		mod_frequency_target = randf_range(0.0, 1.0)
	if mod_uses_phase:
		mod_phase_target = randf_range(0.0, 1.0)
