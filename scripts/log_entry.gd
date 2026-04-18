extends Control

const STEP_SCENES := {
	"filter": preload("res://scenes/steps/FilterStep.tscn"),
	"modulation": preload("res://scenes/steps/ModulationStep.tscn"),
	"decode": preload("res://scenes/steps/DecodeStep.tscn"),
	"decoded": preload("res://scenes/steps/DecodedMessage.tscn"),
}

@onready var _title: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
@onready var _close: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton
@onready var _step_container: Control = $Panel/MarginContainer/VBoxContainer/StepContainer

var _current_signal: SignalData = null

func _ready() -> void:
	GameManager.signal_loaded.connect(_on_signal_loaded)
	_close.pressed.connect(_on_close_pressed)

func _on_signal_loaded(data: SignalData) -> void:
	_current_signal = data
	_title.text = data.name
	_load_step()
	show()

func _load_step() -> void:
	for child in _step_container.get_children():
		child.queue_free()

	var scene_key: String
	if not _current_signal.is_filtered:
		scene_key = "filter"
	elif not _current_signal.is_modulated:
		scene_key = "modulation"
	elif not _current_signal.is_decoded:
		scene_key = "decode"
	else:
		scene_key = "decoded"

	var step: Control = STEP_SCENES[scene_key].instantiate()
	step.signal_data = _current_signal
	if step.has_signal("step_completed"):
		step.step_completed.connect(_on_step_completed)
	_step_container.add_child(step)

func _on_step_completed() -> void:
	_load_step()

func _on_close_pressed() -> void:
	GameManager.unload_signal()
	hide()
