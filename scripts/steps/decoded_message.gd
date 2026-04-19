extends Control

signal step_completed

var signal_data: SignalData

func _ready() -> void:
	var vbox: VBoxContainer = $VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	call_deferred("_build_ui")

func _build_ui() -> void:
	var vbox: VBoxContainer = $VBoxContainer

	var title := Label.new()
	title.text = "Signal Decoded"
	vbox.add_child(title)

	if signal_data.decode_image:
		var img := TextureRect.new()
		img.texture = signal_data.decode_image
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(img)

	var message := Label.new()
	message.text = signal_data.message
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message)

	if signal_data.money_reward > 0:
		var money := Label.new()
		money.text = "+ %d credits" % signal_data.money_reward
		vbox.add_child(money)

	if signal_data.decode_word_rewards.size() > 0:
		var words := Label.new()
		words.text = "New words intercepted: %s" % ", ".join(signal_data.decode_word_rewards)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(words)
