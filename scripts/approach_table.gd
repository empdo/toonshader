extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Globals.approach_table_dialog_requested.emit()
