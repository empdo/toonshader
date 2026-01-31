extends Area3D

@export var player_target: Node3D
@export var camera_target: Node3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("ENTERRRR!!")
		Globals.player_entered_table_area.emit(player_target, camera_target)
