extends Area3D

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		Globals.approach_table_dialog_requested.emit()
