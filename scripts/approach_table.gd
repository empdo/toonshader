extends Area3D

var has_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		# Skip dialog in debug mode
		if not Globals.DEBUG_SKIP_TO_GAME:
			Globals.approach_table_dialog_requested.emit()
