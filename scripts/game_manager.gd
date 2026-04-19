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
var telescope_level: int = 0
var filter_level: int = 1
var modulator_level: int = 0
var player_money: int = 0
var tutorial_active: bool = true

const TELESCOPE_UPGRADE_COSTS: Array[int] = [50, 100, 275, 550]
const FILTER_UPGRADE_COSTS: Array[int] = [0, 150]
const MODULATOR_UPGRADE_COSTS: Array[int] = [75, 200, 400]

const FIND_RADIUS := 96.0
const PROXIMITY_RADIUS := FIND_RADIUS * 4

const SYMBOL_ANSWERS: Dictionary = {
	"ア": "ELPIS",
	"イ": "HOME",
	"ウ": "FIRE",
	"エ": "SILENCE",
	"オ": "JOURNEY",
	"カ": "DEEP",
	"キ": "DARK",
	"ク": "HOLLOW",
	"ケ": "BEYOND",
	"コ": "ECHO",
	"サ": "REFUGE",
	"シ": "WAKE",
	"ス": "VOICE",
	"セ": "END",
	"ソ": "BIRTH",
	"タ": "SEEN",
	"チ": "HUNGER",
	"ツ": "VAST",
	"テ": "AWAKE",
	"ト": "WAITING",
}

var signals: Array[SignalData] = []
var codebook: Dictionary = {}
var word_bank: Array[String] = ["ELPIS", "FIRE"]

func _ready() -> void:
	_load_signals()

const _SIGNAL_RESOURCES: Array[String] = [
	"res://resources/signals/test_signal.tres",
	"res://resources/signals/story_s1.tres",
	"res://resources/signals/story_s2a.tres",
	"res://resources/signals/story_s2b.tres",
	"res://resources/signals/story_s3.tres",
	"res://resources/signals/story_s4.tres",
	"res://resources/signals/story_s5.tres",
	"res://resources/signals/story_s6.tres",
	"res://resources/signals/flavor_accretion.tres",
	"res://resources/signals/flavor_asteroid.tres",
	"res://resources/signals/flavor_binary.tres",
	"res://resources/signals/flavor_brokenhalo.tres",
	"res://resources/signals/flavor_browndwarf.tres",
	"res://resources/signals/flavor_coldvoid.tres",
	"res://resources/signals/flavor_drift.tres",
	"res://resources/signals/flavor_dyson.tres",
	"res://resources/signals/flavor_gamma.tres",
	"res://resources/signals/flavor_gas.tres",
	"res://resources/signals/flavor_gravlens.tres",
	"res://resources/signals/flavor_magnetic.tres",
	"res://resources/signals/flavor_magnetar.tres",
	"res://resources/signals/flavor_microwave.tres",
	"res://resources/signals/flavor_neutron.tres",
	"res://resources/signals/flavor_nursery.tres",
	"res://resources/signals/flavor_pilgrim.tres",
	"res://resources/signals/flavor_pulsar.tres",
	"res://resources/signals/flavor_quasar.tres",
	"res://resources/signals/flavor_supernova.tres",
	"res://resources/signals/flavor_void2.tres",
	"res://resources/signals/flavor_volcanic.tres",
	"res://resources/signals/flavor_maelstrom.tres",
	"res://resources/signals/flavor_debris_alpha.tres",
	"res://resources/signals/flavor_debris_beta.tres",
	"res://resources/signals/flavor_hollow_eye.tres",
	"res://resources/signals/flavor_void_whisper.tres",
	"res://resources/signals/flavor_sword.tres",
	"res://resources/signals/flavor_frost_veil.tres",
	"res://resources/signals/flavor_comet_train.tres",
	"res://resources/signals/flavor_pale_drifter.tres",
	"res://resources/signals/flavor_iron_curtain.tres",
	"res://resources/signals/flavor_echo_burst.tres",
	"res://resources/signals/flavor_reliquary.tres",
	"res://resources/signals/flavor_amber_cloud.tres",
	"res://resources/signals/flavor_stone_garden.tres",
	"res://resources/signals/flavor_tidal_wake.tres",
	"res://resources/signals/flavor_solar_graveyard.tres",
	"res://resources/signals/flavor_drift_current.tres",
	"res://resources/signals/flavor_tear_ne.tres",
	"res://resources/signals/flavor_tear_se.tres",
	"res://resources/signals/flavor_tear_s.tres",
	"res://resources/signals/flavor_tear_w.tres",
	"res://resources/signals/flavor_tear_sw.tres",
]

func _load_signals() -> void:
	for path in _SIGNAL_RESOURCES:
		var data := load(path) as SignalData
		if data:
			data.generate_targets()
			signals.append(data)

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
