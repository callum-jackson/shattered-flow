extends Node

func _ready() -> void:
	$ScoreLabel.text = globals.final_time
	await transition.fade_in()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("confirm"):
		await transition.fade_out()
		get_tree().change_scene_to_file("res://scenes/main.tscn")