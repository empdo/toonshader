extends Node

var cards: Array[Node3D]

const points_to_win = 3
var rounds_done = 0
var player_points = 0
var opponent_points = 0

var current_player_guess = false
var told_the_truth = false

var game_over = false

func reset():
	Globals.reset()
	rounds_done = 0
	player_points = 0
	opponent_points = 0

	current_player_guess = false
	told_the_truth = false

	game_over = false

func _ready():
	Globals.player_entered_table_area.connect(on_player_entered_table_area)
	Globals.guess_button_clicked.connect(on_guess_button_clicked)

func on_guess_button_clicked(guess: bool):
	current_player_guess = guess

func on_player_entered_table_area():
	reset()
	
	# Wait for the sit_down dialog to finish before starting the game
	await _wait_for_sit_down_dialog()
	
	# show all cards
	for c in cards:
		c.show_card_then_hide_it(8)
	
	while !game_over:
		await do_round()

func _wait_for_sit_down_dialog():
	# In debug mode, skip waiting for dialog
	if Globals.DEBUG_SKIP_TO_GAME:
		return
	
	# Wait for the sit_down dialog (c_sit_down.tres) to finish
	while true:
		var finished_dialog: DialogResource = await DialogManager.dialog_finished
		if finished_dialog.resource_path == "res://resources/c_sit_down.tres":
			break

##########################
# the important thing
func do_round():
	##### LET PLAYER CLICK CARD(s) TO PEEK AT
	Globals.let_player_show_cards = true
	await Globals.player_showed_chosen_cards
	
	# delay to let player actually see the cards
	await get_tree().create_timer(3).timeout
	Globals.let_player_show_cards = false
	
	# hide them again
	for c in Globals.cards_currently_showing:
		c.hide_card()
	await get_tree().create_timer(3).timeout
	#####
	
	##### OPPONENT POINTS
	var chosen_card = opponent_chooses_and_points()
	####
	
	##### WAIT FOR GUESS
	await Globals.guess_button_clicked
	####
	
	##### SHOW IF DID NOT AGREE
	if not current_player_guess:
		chosen_card.show_card_then_hide_it(2)
		await get_tree().create_timer(3).timeout
	####
	
	##### CALCULATE POINTS
	if current_player_guess == told_the_truth:
		player_points += 1
	else:
		opponent_points += 1
	rounds_done += 1
	if player_points == points_to_win:
		game_over = true
		print("WON")
		Globals.won_game.emit()
		Globals.see_through_cards.emit(false)
	elif opponent_points == points_to_win:
		print("LOST")
		game_over = true
		Globals.lost_game.emit()
		get_tree().change_scene_to_file("res://scenes/lost_by_game.tscn")
	####
##########################

func opponent_chooses_and_points():
	var chosen_card = choose_card_to_point_to()
	var will_tell_truth_for_sure = randi_range(0, 1) == 0 # 5050
	var card_type_id_to_say = -1
	if will_tell_truth_for_sure:
		card_type_id_to_say = chosen_card.card_type_id
	else:
		card_type_id_to_say = choose_card_id_to_say_another_is()
	
	told_the_truth = chosen_card.card_type_id == card_type_id_to_say
	
	Globals.highlight_card.emit(chosen_card)
	Globals.say_card_type.emit(chosen_card)
	# highlight chosen card
	# show card_type_id_to_say
	return chosen_card

# can be more sophisticated
func choose_card_to_point_to() -> Node3D:
	return cards.pick_random()

# can also be more sophisticated
func choose_card_id_to_say_another_is() -> int:
	return cards.pick_random().card_type_id
