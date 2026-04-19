extends Sprite2D

## Baseline alpha (the dimmest the sprite gets)
@export var alpha_base: float = 0.15
## How much the alpha pulses above/below the base
@export var alpha_amplitude: float = 0.1
## Pulses per second
@export var blink_speed: float = 2.0
## Phase offset in seconds — stagger multiple instances so they don't all pulse together
@export var time_offset: float = 0.0
## Color to blend toward at the peak of each pulse (white = no tint)
@export var pulse_color: Color = Color.WHITE
## How strongly the pulse color is mixed in at peak (0 = no color shift, 1 = full color)
@export_range(0.0, 1.0) var color_mix: float = 0.0

var t: float = 0.0

func _process(delta: float) -> void:
	t += delta
	var wave := (sin((t + time_offset) * blink_speed) + 1.0) * 0.5
	var a := alpha_base + alpha_amplitude * (wave * 2.0 - 1.0)
	modulate = Color.WHITE.lerp(pulse_color, wave * color_mix)
	modulate.a = a
