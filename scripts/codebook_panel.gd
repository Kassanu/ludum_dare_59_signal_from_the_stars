extends Control

var _symbol_list: VBoxContainer
var _word_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	GameManager.codebook_updated.connect(_refresh_symbols)
	GameManager.word_bank_updated.connect(_refresh_words)

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220.0
	panel.offset_top = -200.0
	panel.offset_right = 220.0
	panel.offset_bottom = 200.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	var title := Label.new()
	title.text = "Codebook"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(_on_close_pressed)
	hbox.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)

	var sym_header := Label.new()
	sym_header.text = "Known Symbols"
	scroll_vbox.add_child(sym_header)

	_symbol_list = VBoxContainer.new()
	scroll_vbox.add_child(_symbol_list)

	scroll_vbox.add_child(HSeparator.new())

	var word_header := Label.new()
	word_header.text = "Word Bank"
	scroll_vbox.add_child(word_header)

	_word_list = VBoxContainer.new()
	scroll_vbox.add_child(_word_list)

func open() -> void:
	_refresh_symbols()
	_refresh_words()
	GameManager.panel_opened.emit()
	show()

func _on_close_pressed() -> void:
	GameManager.panel_closed.emit()
	hide()

func _refresh_symbols() -> void:
	for child in _symbol_list.get_children():
		child.queue_free()
	for symbol in GameManager.codebook:
		var label := Label.new()
		label.text = "%s  →  %s" % [symbol, GameManager.codebook[symbol]]
		_symbol_list.add_child(label)

func _refresh_words() -> void:
	for child in _word_list.get_children():
		child.queue_free()
	for word in GameManager.word_bank:
		var label := Label.new()
		label.text = word
		_word_list.add_child(label)
