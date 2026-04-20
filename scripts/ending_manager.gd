class_name EndingManager
extends CanvasLayer

const DIALOG_MARGIN := 12
const DIALOG_HEIGHT_MIN := 80
const ENDING_SIGNAL_ID := "story_s6"

var _dialog_pages: Array[String] = []
var _current_page: int = 0

var _blocker: ColorRect
var _dialog_panel: Panel
var _dialog_text: RichTextLabel
var _continue_btn: Button

func _ready() -> void:
	layer = 11
	_build_dialog_ui()
	GameManager.signal_unloaded.connect(_on_signal_unloaded)
	GameManager.signal_decoded.connect(_on_signal_decoded)

var _s6_decoded := false

func _on_signal_decoded(data: SignalData) -> void:
	if data.id == ENDING_SIGNAL_ID:
		_s6_decoded = true

func _on_signal_unloaded() -> void:
	if _s6_decoded:
		_s6_decoded = false
		_show_ending()

func _is_maelstrom_decoded() -> bool:
	for sig in GameManager.signals:
		if sig.id == "flavor_maelstrom":
			return sig.is_decoded
	return false

func _show_ending() -> void:
	_dialog_pages = [
		"[b]SIGNAL ELPIS — TRANSMISSION CLOSED[/b]\n\nThe loop ends here. Somewhere out there, a ghost ship circles a dead star, broadcasting into nothing.\n\nYou've traced the signal to its source. The message is logged. The silence that follows is its own kind of answer.",
	]
	if not _is_maelstrom_decoded():
		_dialog_pages.append("The map still has dark regions. Other signals may be waiting — harder to find, harder to read.\n\nKeep scanning.")
	_dialog_pages.append("Thanks for playing.")
	_current_page = 0
	_update_page()
	_blocker.show()
	_dialog_panel.show()

func _update_page() -> void:
	_dialog_text.text = _dialog_pages[_current_page]
	if _current_page >= _dialog_pages.size() - 1:
		_continue_btn.text = "Close"
	else:
		_continue_btn.text = "Next"
	call_deferred("_fit_dialog")

func _fit_dialog() -> void:
	var viewport_h := get_viewport().get_visible_rect().size.y
	var max_panel_h := viewport_h * 0.75
	var text_h := _dialog_text.get_content_height()
	var total_h := 24 + text_h + 8 + 32 + 24
	var panel_h := clampf(total_h, float(DIALOG_HEIGHT_MIN), max_panel_h)
	_dialog_panel.offset_bottom = DIALOG_MARGIN + panel_h
	_dialog_text.scroll_active = total_h > max_panel_h

func _on_continue_pressed() -> void:
	_current_page += 1
	if _current_page < _dialog_pages.size():
		_update_page()
	else:
		_blocker.hide()
		_dialog_panel.hide()

func _build_dialog_ui() -> void:
	_blocker = ColorRect.new()
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.color = Color(0, 0, 0, 0.75)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.hide()
	add_child(_blocker)

	_dialog_panel = Panel.new()
	_dialog_panel.layout_mode = 1
	_dialog_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_dialog_panel.offset_top = DIALOG_MARGIN
	_dialog_panel.offset_left = 80.0
	_dialog_panel.offset_right = -80.0
	_dialog_panel.offset_bottom = DIALOG_MARGIN + DIALOG_HEIGHT_MIN
	add_child(_dialog_panel)

	var margin := MarginContainer.new()
	margin.layout_mode = 1
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	_dialog_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	_dialog_text = RichTextLabel.new()
	_dialog_text.bbcode_enabled = true
	_dialog_text.fit_content = false
	_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialog_text.scroll_active = false
	vbox.add_child(_dialog_text)

	_continue_btn = Button.new()
	_continue_btn.text = "Next"
	_continue_btn.custom_minimum_size = Vector2(140, 32)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	_dialog_panel.hide()
