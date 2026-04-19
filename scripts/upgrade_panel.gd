extends Control

var _money_label: Label
var _upgrade_rows: Array = []

func _ready() -> void:
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.telescope_upgraded.connect(func(_l): _refresh_all())
	GameManager.filter_upgraded.connect(func(_l): _refresh_all())
	GameManager.modulator_upgraded.connect(func(_l): _refresh_all())

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300.0
	panel.offset_top = -180.0
	panel.offset_right = 300.0
	panel.offset_bottom = 180.0
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

	var title_hbox := HBoxContainer.new()
	vbox.add_child(title_hbox)

	var title := Label.new()
	title.text = "Upgrades"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title)

	_money_label = Label.new()
	_money_label.text = "Credits: 0"
	title_hbox.add_child(_money_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(_on_close_pressed)
	title_hbox.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var upgrades_hbox := HBoxContainer.new()
	upgrades_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrades_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(upgrades_hbox)

	_add_upgrade_column(upgrades_hbox, "Telescope",
		GameManager.TELESCOPE_UPGRADE_COSTS, GameManager.telescope_level,
		GameManager.purchase_telescope_upgrade)
	_add_upgrade_column(upgrades_hbox, "Filter",
		GameManager.FILTER_UPGRADE_COSTS, GameManager.filter_level,
		GameManager.purchase_filter_upgrade)
	_add_upgrade_column(upgrades_hbox, "Modulator",
		GameManager.MODULATOR_UPGRADE_COSTS, GameManager.modulator_level,
		GameManager.purchase_modulator_upgrade)

func _add_upgrade_column(parent: HBoxContainer, upgrade_name: String, costs: Array, _initial_level: int, purchase_fn: Callable) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(col)

	var name_label := Label.new()
	name_label.text = upgrade_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_label)

	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_normal = load("res://icon.svg")
	btn.pressed.connect(func():
		purchase_fn.call()
	)
	col.add_child(btn)

	var segments_hbox := HBoxContainer.new()
	segments_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	segments_hbox.add_theme_constant_override("separation", 4)
	col.add_child(segments_hbox)

	var max_level := costs.size()
	var segments: Array[ColorRect] = []
	for i in max_level:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(24, 12)
		seg.color = Color(0.25, 0.25, 0.25)
		segments_hbox.add_child(seg)
		segments.append(seg)

	var cost_label := Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cost_label)

	_upgrade_rows.append({
		"name": upgrade_name,
		"segments": segments,
		"cost_label": cost_label,
		"costs": costs,
	})

func _get_current_level(upgrade_name: String) -> int:
	match upgrade_name:
		"Telescope": return GameManager.telescope_level
		"Filter": return GameManager.filter_level
		"Modulator": return GameManager.modulator_level
	return 0

func _refresh_all() -> void:
	for row in _upgrade_rows:
		var level := _get_current_level(row["name"])
		var segments: Array = row["segments"]
		var costs: Array = row["costs"]

		for i in segments.size():
			segments[i].color = Color(0.8, 0.7, 0.2) if i < level else Color(0.25, 0.25, 0.25)

		var cost_label: Label = row["cost_label"]
		if level >= costs.size():
			cost_label.text = "MAX"
		else:
			cost_label.text = "%d credits" % costs[level]

func open() -> void:
	_refresh_all()
	_on_money_changed(GameManager.player_money)
	GameManager.panel_opened.emit()
	show()

func _on_close_pressed() -> void:
	GameManager.panel_closed.emit()
	hide()

func _on_money_changed(amount: int) -> void:
	_money_label.text = "Credits: %d" % amount
