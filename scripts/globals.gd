extends Node

const MAX_SHOWABLE_CARDS = 1
var number_of_cards_showed = 0

var allowed_to_use_mask

signal guess_button_clicked(bool)
signal see_through_cards(bool)
signal player_entered_table_area_with_targets(player_target: Node3D, camera_target: Node3D)
signal player_entered_table_area
signal player_leaving_table_game
signal highlight_card(Node3D)
signal say_card_type(int)

signal won_game
signal lost_game
signal lost_game_by_mask

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		player_leaving_table_game.emit()
