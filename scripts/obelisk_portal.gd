extends Node3D


func _ready():
	# TODO: connect to events for game won
	
	pass

func on_won():
	visible = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/end.tscn")
