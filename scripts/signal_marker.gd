class_name SignalMarker
extends Node2D

signal clicked(data: SignalData)

const COLOR_DECODED := Color(0.2, 1.0, 0.4)
const COLOR_PENDING := Color(0.6, 0.8, 1.0)

@export
var signal_data: SignalData:
	set(value):
		signal_data = value
		_refresh()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _tooltip: Label = $Tooltip
@onready var _area: Area2D = $Area2D

func _ready() -> void:
	_area.input_event.connect(_on_area_input_event)
	_area.mouse_entered.connect(_tooltip.show)
	_area.mouse_exited.connect(_tooltip.hide)
	_refresh()

func _refresh() -> void:
	if not is_node_ready() or signal_data == null:
		return
	_sprite.modulate = COLOR_DECODED if signal_data.is_decoded else COLOR_PENDING
	_tooltip.text = "%s\n%s" % [signal_data.name, _status_text()]
	_tooltip.hide()

func _status_text() -> String:
	if signal_data.is_decoded:
		return "Decoded"
	return "Found"

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(signal_data)
