extends Node

signal signal_found(data: SignalData)
signal signal_loaded(data: SignalData)
signal signal_unloaded
signal decode_step_started
signal telescope_upgraded(level: int)
signal filter_upgraded(level: int)
signal modulator_upgraded(level: int)
signal money_changed(amount: int)
signal codebook_updated
signal word_bank_updated
signal panel_opened
signal panel_closed
signal signal_decoded(data: SignalData)

var _active_signal: SignalData = null
var telescope_level: int = 1
var filter_level: int = 1
var modulator_level: int = 0
var player_money: int = 0
var tutorial_active: bool = true

const TELESCOPE_UPGRADE_COSTS: Array[int] = [0, 150, 350, 700]
const FILTER_UPGRADE_COSTS: Array[int] = [0, 200]
const MODULATOR_UPGRADE_COSTS: Array[int] = [100, 250, 500]

const FIND_RADIUS := 96.0
const PROXIMITY_RADIUS := FIND_RADIUS * 3

const SYMBOL_ANSWERS: Dictionary = {
	"ア": "NOVA",
	"イ": "SECTOR-7",
	"ウ": "KEPLER-9",
}

var signals: Array[SignalData] = []
var codebook: Dictionary = {}
var word_bank: Array[String] = ["NOVA"]

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

func get_telescope_range(map_radius: int) -> int:
	var max_level := TELESCOPE_UPGRADE_COSTS.size()
	if telescope_level >= max_level:
		return map_radius
	return max(1, telescope_level * map_radius / max_level)

func get_nearest_unscanned_distance(world_pos: Vector2) -> float:
	var nearest := INF
	for sig in signals:
		if sig.is_found:
			continue
		if tutorial_active and sig.id != "test_signal":
			continue
		nearest = min(nearest, sig.map_position.distance_to(world_pos))
	return nearest

func get_nearest_unscanned_direction(world_pos: Vector2) -> Vector2:
	var nearest_sig: SignalData = null
	var nearest_dist := INF
	for sig in signals:
		if sig.is_found:
			continue
		if tutorial_active and sig.id != "test_signal":
			continue
		var dist := sig.map_position.distance_to(world_pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_sig = sig
	if nearest_sig == null:
		return Vector2.ZERO
	return world_pos.direction_to(nearest_sig.map_position)

func try_load_nearest_signal(world_pos: Vector2) -> SignalData:
	var nearest: SignalData = null
	var nearest_dist := FIND_RADIUS
	for sig in signals:
		if sig.is_found:
			continue
		if tutorial_active and sig.id != "test_signal":
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

func record_assignment(symbol: String, word: String) -> void:
	codebook[symbol] = word
	codebook_updated.emit()

func add_word_rewards(words: Array[String]) -> void:
	for word in words:
		if word not in word_bank:
			word_bank.append(word)
	if words.size() > 0:
		word_bank_updated.emit()

func receive_money(amount: int) -> void:
	player_money += amount
	money_changed.emit(player_money)

func _can_afford(cost: int) -> bool:
	return player_money >= cost

func _spend(cost: int) -> void:
	player_money -= cost
	money_changed.emit(player_money)

func purchase_telescope_upgrade() -> bool:
	if telescope_level >= TELESCOPE_UPGRADE_COSTS.size():
		return false
	var cost := TELESCOPE_UPGRADE_COSTS[telescope_level]
	if not _can_afford(cost):
		return false
	_spend(cost)
	telescope_level += 1
	telescope_upgraded.emit(telescope_level)
	return true

func purchase_filter_upgrade() -> bool:
	if filter_level >= FILTER_UPGRADE_COSTS.size():
		return false
	var cost := FILTER_UPGRADE_COSTS[filter_level]
	if not _can_afford(cost):
		return false
	_spend(cost)
	filter_level += 1
	filter_upgraded.emit(filter_level)
	return true

func purchase_modulator_upgrade() -> bool:
	if modulator_level >= MODULATOR_UPGRADE_COSTS.size():
		return false
	var cost := MODULATOR_UPGRADE_COSTS[modulator_level]
	if not _can_afford(cost):
		return false
	_spend(cost)
	modulator_level += 1
	modulator_upgraded.emit(modulator_level)
	return true
