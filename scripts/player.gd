extends Area2D

signal hit

@export var max_speed := 240.0
@export var acceleration_rate := 8.0
@export var damping_rate := 1.5
@export var turn_rate := 20.0
@export var max_stretch := 0.20

@onready var sprite = $Sprite2D
@onready var sprite_shattered = $Sprite2DShattered
var screen_size
var base_scale = Vector2.ONE
var current_velocity = Vector2.ZERO
var input_locked = false

func _ready() -> void:
	screen_size = get_viewport_rect().size
	base_scale = sprite.scale
	sprite.show()
	sprite_shattered.hide()

func _physics_process(delta: float) -> void:
	var input_direction = Vector2.ZERO
	if not input_locked:
		input_direction = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
		)
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
		
	var target_velocity = input_direction * max_speed
	
	var acceleration_blend = clampf(acceleration_rate * delta, 0.0, 1.0)
	current_velocity = current_velocity.lerp(target_velocity, acceleration_blend)
	
	current_velocity -= current_velocity * (damping_rate * delta)
	
	position += current_velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	var speed = current_velocity.length()
	if speed > 0.5:
		var turn_blend = clampf(turn_rate * delta, 0.0, 1.0)
		var target_angle = current_velocity.angle()
		sprite.rotation = lerp_angle(sprite.rotation, target_angle, turn_blend)
		
	var speed_ratio = clampf(speed / max_speed, 0.0, 1.0)
	var stretch_amount = speed_ratio * max_stretch
	sprite.scale = base_scale * Vector2(1.0 + stretch_amount, 1.0 - stretch_amount)

func _on_body_entered(body: Node2D) -> void:
	input_locked = true
	sprite.hide()
	sprite_shattered.show()
	$ShatteredSound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	hit.emit()