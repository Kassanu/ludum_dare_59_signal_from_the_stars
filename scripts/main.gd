extends Node2D

@onready var _codebook_panel = $SignalPanel/CodebookPanel
@onready var _upgrade_panel = $SignalPanel/UpgradePanel
@onready var _codebook_btn: Button = $SignalPanel/BottomBar/CodebookButton
@onready var _upgrade_btn: Button = $SignalPanel/BottomBar/UpgradeButton
@onready var _sound_btn: Button = $SignalPanel/BottomBar/SoundButton
@onready var _sound_popup = $SignalPanel/SoundPopup
@onready var _volume_slider: HSlider = $SignalPanel/SoundPopup/HSlider

func _ready() -> void:
	_codebook_btn.pressed.connect(_codebook_panel.open)
	_upgrade_btn.pressed.connect(_upgrade_panel.open)
	_sound_btn.pressed.connect(_on_sound_btn_pressed)
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	_volume_slider.value_changed.connect(_on_volume_changed)
	_sound_popup.visible = false
	GameManager.panel_opened.connect(_set_buttons_disabled.bind(true))
	GameManager.panel_closed.connect(_set_buttons_disabled.bind(false))
	GameManager.signal_loaded.connect(func(_d): _set_buttons_disabled(true))
	GameManager.signal_unloaded.connect(_set_buttons_disabled.bind(false))

func _on_sound_btn_pressed() -> void:
	_sound_popup.visible = not _sound_popup.visible

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _set_buttons_disabled(disabled: bool) -> void:
	_codebook_btn.disabled = disabled
	_upgrade_btn.disabled = disabled
