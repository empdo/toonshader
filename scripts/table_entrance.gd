extends Area3D

@export var player_target: Node3D
@export var camera_target: Node3D

var last_entered = 0
var player_in_area: Node3D = null
var waiting_for_approach_dialog: bool = true
var has_sat_down: bool = false

func _ready():
	Globals.won_game.connect(on_won)
	# Wait for approach_table dialog to finish before allowing sit down
	DialogManager.dialog_finished.connect(_on_dialog_finished)

func on_won():
	monitoring = false

func _on_dialog_finished(dialog: DialogResource) -> void:
	# Check if the finished dialog is the approach_table dialog
	if dialog.resource_path == "res://resources/b_approach_table.tres":
		waiting_for_approach_dialog = false
		# If player is already in the area, trigger sit down immediately
		if player_in_area and player_in_area.is_in_group("player"):
			_trigger_sit_down()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = body
		# Only trigger sit down if approach dialog has finished
		if not waiting_for_approach_dialog:
			_trigger_sit_down()

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_area:
		player_in_area = null

func _trigger_sit_down() -> void:
	if has_sat_down:
		return
	has_sat_down = true
	if player_target and camera_target:
		Globals.player_entered_table_area_with_targets.emit(player_target, camera_target)
		Globals.player_entered_table_area.emit()
	else:
		push_error("Player target or camera target is null in table_entrance")
