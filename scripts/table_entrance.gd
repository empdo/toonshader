extends Area3D

@export var player_target: Node3D
@export var camera_target: Node3D

var last_entered = 0

func _ready():
	Globals.won_game.connect(on_won)

func on_won():
	monitoring = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Globals.player_entered_table_area_with_targets.emit(player_target, camera_target)
		Globals.player_entered_table_area.emit()
