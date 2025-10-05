extends Node

@export var shard_scene: PackedScene

var elapsed_time := 0.0
var time = "00:00:00"
var stop_time = false

func _ready() -> void:
	await transition.fade_in()
	$ShardStartTimer.start()

func _process(delta: float) -> void:
	if not stop_time:
		elapsed_time += delta
		var minutes = int(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		var centiseconds = int((elapsed_time - int(elapsed_time)) * 100)
		time = "%02d:%02d:%02d" % [minutes, seconds, centiseconds] 
		$ScoreTimerLabel.text = "Time: " + str(time)
		globals.final_time = "Time: " + str(time)

func _on_shard_start_timer_timeout() -> void:
	$ShardSpawnTimer.start()

func _on_shard_spawn_timer_timeout():
	var shard = shard_scene.instantiate()
	var shard_spawn_location = $ShardPath/ShardSpawnLocation
	shard_spawn_location.progress_ratio = randf()
	shard.position = shard_spawn_location.position
	var direction = shard_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	shard.rotation = direction
	var velocity = Vector2(randf_range(150.0, 220.0), 0.0)
	shard.linear_velocity = velocity.rotated(direction)
	add_child(shard)

func _on_player_hit() -> void:
	stop_time = true
	await get_tree().create_timer(2).timeout
	await transition.fade_out()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")