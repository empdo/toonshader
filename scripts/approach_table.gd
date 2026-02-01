extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Trigger approach table dialog
		var approach_dialog = load("res://resources/b_approach_table.tres") as DialogResource
		if approach_dialog:
			DialogManager.play(approach_dialog)
