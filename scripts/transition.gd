extends Control

func fade_in():
	$TextureRect.show()
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	$TextureRect.hide()
	

func fade_out():
	$TextureRect.show()
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	$TextureRect.hide()