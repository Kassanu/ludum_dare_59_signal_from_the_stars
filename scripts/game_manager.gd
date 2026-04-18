extends Node

signal signal_found(data: SignalData)
signal signal_loaded(data: SignalData)
signal signal_unloaded

var _active_signal: SignalData = null

const FIND_RADIUS := 96.0

var signals: Array[SignalData] = []

func _ready() -> void:
	_load_signals()

func _load_signals() -> void:
	var dir := DirAccess.open("res://resources/signals/")
	if not dir:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".tres"):
			var data := load("res://resources/signals/" + file) as SignalData
			if data:
				data.generate_targets()
				signals.append(data)
		file = dir.get_next()

func try_load_nearest_signal(world_pos: Vector2) -> SignalData:
	var nearest: SignalData = null
	var nearest_dist := FIND_RADIUS
	for sig in signals:
		if sig.is_found:
			continue
		var dist := sig.map_position.distance_to(world_pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = sig
	if nearest:
		nearest.is_found = true
		signal_found.emit(nearest)
	return nearest

func load_signal(data: SignalData) -> void:
	_active_signal = data
	signal_loaded.emit(data)

func unload_signal() -> void:
	_active_signal = null
	signal_unloaded.emit()
