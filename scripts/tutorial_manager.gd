class_name TutorialManager
extends CanvasLayer

enum State {
	WELCOME,
	SCAN_PROMPT,
	SIGNAL_OPEN,
	FILTER_ACTIVE,
	DECODE_PROMPT,
	WAITING_DECODE,
	REWARD_DIALOG,
	UPGRADE_PROMPT,
	WAITING_TELESCOPE,
	FINISH,
	COMPLETE,
}

const DIALOG_MARGIN := 12
const DIALOG_HEIGHT_MIN := 80

var _state: State = State.WELCOME
var _dialog_pages: Array[String] = []
var _current_page: int = 0
var _final_label := "Continue"
var _tutorial_signal: SignalData = null

var _blocker: ColorRect
var _dialog_panel: Panel
var _dialog_text: RichTextLabel
var _continue_btn: Button

@onready var _scan_arrow: Node2D = $"../StarMap/TutorialScanArrow"
@onready var _upgrade_arrow: Control = $"../SignalPanel/TutorialUpgradeArrow"

func _ready() -> void:
	layer = 10
	_build_dialog_ui()

	_scan_arrow.visible = false
	_upgrade_arrow.visible = false

	GameManager.signal_found.connect(_on_signal_found)
	GameManager.signal_loaded.connect(_on_signal_loaded)
	GameManager.signal_unloaded.connect(_on_signal_unloaded)
	GameManager.decode_step_started.connect(_on_decode_step_started)
	GameManager.telescope_upgraded.connect(_on_telescope_upgraded)

	_start_state(State.WELCOME)

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

	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)

	var skip_btn := Button.new()
	skip_btn.text = "Skip Tutorial"
	skip_btn.flat = true
	skip_btn.custom_minimum_size = Vector2(120, 32)
	skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_btn.pressed.connect(_skip_tutorial)
	btn_row.add_child(skip_btn)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(140, 32)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_btn.pressed.connect(_on_continue_pressed)
	btn_row.add_child(_continue_btn)

	_dialog_panel.hide()

func _show_pages(pages: Array[String], final_label: String = "Continue") -> void:
	_dialog_pages = pages
	_current_page = 0
	_final_label = final_label
	_update_dialog_page()
	_blocker.show()
	_dialog_panel.show()

func _update_dialog_page() -> void:
	_dialog_text.text = _dialog_pages[_current_page]
	if _current_page >= _dialog_pages.size() - 1:
		_continue_btn.text = _final_label
	else:
		_continue_btn.text = "Next"
	call_deferred("_fit_dialog")

func _fit_dialog() -> void:
	var text_h := _dialog_text.get_content_height()
	var total_h := 24 + text_h + 8 + 32 + 24  # top margin + text + spacing + button row + bottom margin
	_dialog_panel.offset_bottom = DIALOG_MARGIN + maxf(total_h, float(DIALOG_HEIGHT_MIN))

func _on_continue_pressed() -> void:
	_current_page += 1
	if _current_page < _dialog_pages.size():
		_update_dialog_page()
	else:
		_blocker.hide()
		_dialog_panel.hide()
		_on_dialog_finished()

func _on_dialog_finished() -> void:
	match _state:
		State.WELCOME:
			_start_state(State.SCAN_PROMPT)
		State.SIGNAL_OPEN:
			_start_state(State.FILTER_ACTIVE)
		State.DECODE_PROMPT:
			_start_state(State.WAITING_DECODE)
		State.REWARD_DIALOG:
			_start_state(State.UPGRADE_PROMPT)
		State.UPGRADE_PROMPT:
			_start_state(State.WAITING_TELESCOPE)
		State.FINISH:
			_start_state(State.COMPLETE)

func _start_state(new_state: State) -> void:
	_state = new_state
	match new_state:
		State.WELCOME:
			_show_pages([
				"Welcome to the Deep Space Signal Detection Unit!\n\nStrange signals have been detected from beyond the stars. Your mission: find and decode them.",
				"Clicking on the star map scans for signals in that area.\n\nThere's something near the [b]Moon[/b] — try clicking it now!",
			])
		State.SCAN_PROMPT:
			_scan_arrow.visible = true
		State.SIGNAL_OPEN:
			_scan_arrow.visible = false
			_show_pages([
				"This is the [b]Signal Log[/b] — where you process and decode incoming transmissions.\n\nBefore you can read the message, you need to [b]clean up the signal[/b]. Rotate the filter knobs until the waveform locks on.",
			])
		State.FILTER_ACTIVE:
			pass
		State.DECODE_PROMPT:
			_show_pages([
				"Signal locked! Now it's time to [b]decode the message[/b].\n\nClick an [b]unknown symbol[/b] to select it (it highlights yellow), then click a [b]word[/b] from the list to assign it. Fill every symbol and hit [b]Transmit[/b]!",
			])
		State.WAITING_DECODE:
			pass
		State.REWARD_DIALOG:
			_show_pages([
				"Signal decoded!\n\nUnknown symbols have been logged in your [b]Codebook[/b]. Whenever you see the same markers again, they'll auto-fill — no need to re-assign.\n\nKeep scanning. There are more transmissions out there.",
			])
		State.UPGRADE_PROMPT:
			_upgrade_arrow.visible = true
			_show_pages([
				"That signal rewarded you with [b]50 credits[/b].\n\nOpen the [b]Upgrades[/b] panel and buy the [b]Telescope[/b] upgrade — it'll expand your scan range so you can reach more distant signals.",
			], "Got it")
		State.WAITING_TELESCOPE:
			_upgrade_arrow.visible = true
		State.FINISH:
			_upgrade_arrow.visible = false
			_show_pages([
				"Telescope upgraded!\n\nYou can now scan a wider region of space. Keep scanning — there are more transmissions out there. Good luck, Signal Analyst!",
			], "Let's go")
		State.COMPLETE:
			GameManager.tutorial_active = false

func _skip_tutorial() -> void:
	_blocker.hide()
	_dialog_panel.hide()
	_scan_arrow.visible = false
	_upgrade_arrow.visible = false
	_start_state(State.COMPLETE)

func _on_signal_found(data: SignalData) -> void:
	if data.id == "test_signal":
		_tutorial_signal = data

func _on_signal_loaded(_data: SignalData) -> void:
	if _state == State.SCAN_PROMPT:
		_start_state(State.SIGNAL_OPEN)

func _on_decode_step_started() -> void:
	if _state == State.FILTER_ACTIVE:
		_start_state(State.DECODE_PROMPT)

func _on_signal_unloaded() -> void:
	if _state == State.WAITING_DECODE and _tutorial_signal != null and _tutorial_signal.is_decoded:
		_start_state(State.REWARD_DIALOG)

func _on_telescope_upgraded(_level: int) -> void:
	if _state == State.WAITING_TELESCOPE:
		_start_state(State.FINISH)
