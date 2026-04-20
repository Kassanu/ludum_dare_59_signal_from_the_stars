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
	var used := _slot_assignments.values()
	for word in GameManager.word_bank:
		if word in used:
			continue
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
	var total_slots := _slot_buttons.size()
	var correct_symbols: Array[String] = []
	var wrong_symbols: Array[String] = []
	for symbol in _slot_buttons:
		var assigned: String = _slot_assignments[symbol]
		if GameManager.SYMBOL_ANSWERS.get(symbol, assigned) == assigned:
			correct_symbols.append(symbol)
		else:
			wrong_symbols.append(symbol)

	# 1-2 slots: all or nothing, no partial locking
	if total_slots <= 2:
		if wrong_symbols.is_empty():
			_complete_decode()
		else:
			_flash_failure()
		return

	# 3+ slots: if everything wrong just flash and reset
	if correct_symbols.is_empty():
		_flash_failure()
		return

	# Lock in the correct slots
	for symbol in correct_symbols:
		GameManager.record_assignment(symbol, _slot_assignments[symbol])
		_slot_buttons[symbol].disabled = true
		_slot_buttons[symbol].modulate = Color(0.6, 1.0, 0.6)
		_slot_buttons.erase(symbol)

	if wrong_symbols.is_empty():
		_complete_decode()
		return

	# Flash wrong ones red then reset them
	for symbol in wrong_symbols:
		_slot_buttons[symbol].modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.6).timeout
	for symbol in wrong_symbols:
		_slot_buttons[symbol].modulate = Color.WHITE
		_slot_buttons[symbol].text = symbol
		_slot_assignments[symbol] = ""
	_transmit_btn.disabled = true
	_rebuild_word_bank()

func _complete_decode() -> void:
	GameManager.add_word_rewards(signal_data.decode_word_rewards)
	GameManager.receive_money(signal_data.money_reward)
	signal_data.is_decoded = true
	GameManager.signal_decoded.emit(signal_data)
	step_completed.emit()

func _flash_failure() -> void:
	for sym in _slot_buttons:
		_slot_buttons[sym].modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.6).timeout
	for sym in _slot_buttons:
		_slot_buttons[sym].modulate = Color.WHITE
		_slot_buttons[sym].text = sym
		_slot_assignments[sym] = ""
	_transmit_btn.disabled = true
	_rebuild_word_bank()

func _is_symbol(s: String) -> bool:
	if s.is_empty():
		return false
	var code := s.unicode_at(0)
	return code >= 0x30A0 and code <= 0x30FF
