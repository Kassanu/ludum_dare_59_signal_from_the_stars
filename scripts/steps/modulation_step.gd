extends Control

signal step_completed

var signal_data: SignalData

func _ready() -> void:
	$VBoxContainer/CompleteButton.pressed.connect(_on_complete)

func _on_complete() -> void:
	signal_data.is_modulated = true
	step_completed.emit()
