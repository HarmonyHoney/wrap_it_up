extends Node

func _ready():
	yield(get_tree(), "idle_frame")
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(1.25), "timeout")
	Shared.change_scene(Shared.arcade_path)
