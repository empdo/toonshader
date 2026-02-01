extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("continue_restart"):
		get_tree().change_scene_to_file("res://mainscene.tscn")
