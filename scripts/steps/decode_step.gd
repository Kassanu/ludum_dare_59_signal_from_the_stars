extends Control

signal step_completed

var signal_data: SignalData

var _slot_assignments: Dictionary = {}
var _slot_buttons: Dictionary = {}
var _selected_symbol: String = ""

@onready var _message_flow: HFlowContainer = $VBoxContainer/MessageFlow
@onready var _word_bank_label: Label = $VBoxContainer/WordBankLabel
@onready var _word_bank_container: GridContainer = $VBoxContainer/WordBankContainer
@onready var _transmit_btn: Button = $VBoxContainer/TransmitButton

func _ready() -> void:
	if signal_data.decode_template.is_empty():
		call_deferred("_auto_complete")
		return
	_word_bank_label.hide()
	_word_bank_container.hide()
	_transmit_btn.pressed.connect(_on_transmit)
	call_deferred("_build_ui")

func _auto_complete() -> void:
	GameManager.add_word_rewards(signal_data.decode_word_rewards)
	GameManager.receive_money(signal_data.money_reward)
	signal_data.is_decoded = true
	GameManager.signal_decoded.emit(signal_data)
	step_completed.emit()

func _build_ui() -> void:
	for part in signal_data.decode_template:
		if _is_symbol(part):
			if GameManager.codebook.has(part):
				var lbl := Label.new()
				lbl.text = GameManager.codebook[part]
				lbl.modulate = Color(0.6, 1.0, 0.6)
				_message_flow.add_child(lbl)
				_slot_assignments[part] = GameManager.codebook[part]
			else:
				var btn := Button.new()
				btn.text = part
				btn.pressed.connect(_on_slot_pressed.bind(part))
				_message_flow.add_child(btn)
				_slot_buttons[part] = btn
				_slot_assignments[part] = ""
		else:
			var lbl := Label.new()
			lbl.text = part
			_message_flow.add_child(lbl)

	_rebuild_word_bank()
	_check_all_slots_known()

func _rebuild_word_bank() -> void:
	for child in _word_bank_container.get_children():
		child.queue_free()
	for word in GameManager.word_bank:
		var btn := Button.new()
		btn.text = word
		btn.pressed.connect(_on_word_selected.bind(word))
		_word_bank_container.add_child(btn)

func _on_slot_pressed(symbol: String) -> void:
	_selected_symbol = symbol
	for sym in _slot_buttons:
		_slot_buttons[sym].modulate = Color.WHITE
	_slot_buttons[symbol].modulate = Color(1.0, 1.0, 0.4)
	_word_bank_label.show()
	_word_bank_container.show()

func _on_word_selected(word: String) -> void:
	if _selected_symbol.is_empty():
		return
	_slot_assignments[_selected_symbol] = word
	_slot_buttons[_selected_symbol].text = word
	_slot_buttons[_selected_symbol].modulate = Color(0.6, 1.0, 0.6)
	_selected_symbol = ""
	_word_bank_label.hide()
	_word_bank_container.hide()
	_check_all_slots_known()

func _check_all_slots_known() -> void:
	for sym in _slot_assignments:
		if _slot_assignments[sym].is_empty():
			_transmit_btn.disabled = true
			return
	_transmit_btn.disabled = false

func _on_transmit() -> void:
	var all_correct := true
	for symbol in _slot_buttons:
		var assigned: String = _slot_assignments[symbol]
		if GameManager.SYMBOL_ANSWERS.get(symbol, assigned) != assigned:
			_slot_buttons[symbol].modulate = Color(1.0, 0.4, 0.4)
			all_correct = false
		else:
			_slot_buttons[symbol].modulate = Color(0.6, 1.0, 0.6)
	if not all_correct:
		return
	for symbol in _slot_buttons:
		GameManager.record_assignment(symbol, _slot_assignments[symbol])
	GameManager.add_word_rewards(signal_data.decode_word_rewards)
	GameManager.receive_money(signal_data.money_reward)
	signal_data.is_decoded = true
	GameManager.signal_decoded.emit(signal_data)
	step_completed.emit()

func _is_symbol(s: String) -> bool:
	if s.is_empty():
		return false
	var code := s.unicode_at(0)
	return code >= 0x30A0 and code <= 0x30FF
