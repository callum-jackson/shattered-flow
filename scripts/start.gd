extends Node

func _on_begin_area_entered(area: Area2D) -> void:
	await transition.fade_out()
	get_tree().change_scene_to_file("res://scenes/main.tscn")