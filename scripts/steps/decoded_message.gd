extends Control

signal step_completed

var signal_data: SignalData

func _ready() -> void:
	$VBoxContainer/MessageLabel.text = signal_data.message
