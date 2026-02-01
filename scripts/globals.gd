extends Node

var will_respawn_at_table = false

const MAX_SHOWABLE_CARDS = 1
var cards_currently_showing: Dictionary = {}
var let_player_show_cards = false
var first_card_clicked = false
signal player_showed_chosen_cards

var time_used_seeingmask = 0
const max_time_used_seeingmask_until_collapse = 6

func reset():
	time_used_seeingmask = 0
	let_player_show_cards = false
	cards_currently_showing = {}
	first_card_clicked = false
	
signal guess_button_clicked(bool)
signal see_through_cards(bool)
signal player_entered_table_area_with_targets(player_target: Node3D, camera_target: Node3D)
signal player_entered_table_area
signal player_leaving_table_game
signal highlight_card(Node3D)
signal say_card_type(Node3D)

signal won_game
signal lost_game
signal lost_game_by_mask

# Dialog triggers
signal approach_table_dialog_requested
signal sit_down_dialog_requested
signal first_card_clicked_dialog_requested


# Dialog system
const DEFAULT_CHARS_PER_SECOND = 30.0
var dialog_queue: Array[DialogResource] = []
var current_dialog: DialogResource = null
var dialog_ui: Control = null

signal dialog_finished(dialog: DialogResource)



func _ready():
	# Find DialogUI in the scene tree (deferred to ensure scene is loaded)
	call_deferred("_connect_dialog_ui")

func _process(delta: float) -> void:
	if time_used_seeingmask >= max_time_used_seeingmask_until_collapse:
		lost_game_by_mask.emit()
	
	if Input.is_action_just_pressed("ui_accept"):
		player_leaving_table_game.emit()

func _connect_dialog_ui():
	dialog_ui = get_tree().get_first_node_in_group("dialog_ui")
	if dialog_ui:
		dialog_ui.dialog_finished.connect(_on_dialog_finished)
		print("DialogUI connected successfully")
		# Process any dialogs that were queued before connection
		_process_dialog_queue()
		
		# TEST: Play intro dialog
		var intro = load("res://resources/a_intro.tres") as DialogResource
		if intro:
			queue_dialog(intro)
	else:
		push_warning("DialogUI not found in scene tree")

func queue_dialog(dialog: DialogResource):
	print("Queueing dialog with ", dialog.lines.size(), " lines")
	if dialog.prioritized:
		# Clear queue and stop current dialog
		dialog_queue.clear()
		if dialog_ui and current_dialog:
			dialog_ui.stop_dialog()
		current_dialog = dialog
		if dialog_ui:
			dialog_ui.show_dialog(dialog)
	else:
		# Add to queue
		dialog_queue.append(dialog)
		_process_dialog_queue()

func _process_dialog_queue():
	# Don't start new dialog if one is already playing
	if current_dialog != null or not dialog_ui:
		return
	
	# Process next dialog in queue
	if dialog_queue.size() > 0:
		current_dialog = dialog_queue.pop_front()
		dialog_ui.show_dialog(current_dialog)

func _on_dialog_finished(dialog: DialogResource):
	dialog_finished.emit(dialog)
	current_dialog = null
	_process_dialog_queue()
