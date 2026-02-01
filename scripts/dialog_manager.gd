extends Node

signal dialog_requested(dialog: DialogResource)
signal dialog_stop_requested
signal dialog_finished(dialog: DialogResource)

const DEFAULT_CHARS_PER_SECOND: float = 30.0

var queue: Array[DialogResource] = []
var current: DialogResource = null
var _ui_ready: bool = false

func _ready():
	# Connect to dialog trigger signals
	Globals.approach_table_dialog_requested.connect(_on_approach_table_dialog)
	Globals.sit_down_dialog_requested.connect(_on_sit_down_dialog)
	Globals.first_card_clicked_dialog_requested.connect(_on_first_card_clicked_dialog)
	Globals.your_turn_dialog_requested.connect(_on_your_turn_dialog)
	Globals.won_game.connect(_on_won_game_dialog)

func play(dialog: DialogResource) -> void:
	if dialog.prioritized:
		queue.clear()
		if current:
			dialog_stop_requested.emit()
		current = dialog
		if _ui_ready:
			dialog_requested.emit(dialog)
	else:
		queue.append(dialog)
		_next()

func stop() -> void:
	queue.clear()
	if current:
		dialog_stop_requested.emit()
		current = null

func _on_finished() -> void:
	var finished = current
	current = null
	dialog_finished.emit(finished)
	_next()

func _next() -> void:
	if current != null or queue.is_empty():
		return
	current = queue.pop_front()
	if _ui_ready:
		dialog_requested.emit(current)

# Anropas av DialogUI när den är redo
func ui_ready() -> void:
	_ui_ready = true
	if current:
		dialog_requested.emit(current)

# Dialog trigger handlers
func _on_approach_table_dialog():
	var dialog = load("res://resources/b_approach_table.tres") as DialogResource
	if dialog:
		play(dialog)

func _on_sit_down_dialog():
	var dialog = load("res://resources/c_sit_down.tres") as DialogResource
	if dialog:
		play(dialog)

func _on_first_card_clicked_dialog():
	var dialog = load("res://resources/e_first_card_flipped.tres") as DialogResource
	if dialog:
		play(dialog)

func _on_your_turn_dialog():
	var dialog = load("res://resources/f_your_turn.tres") as DialogResource
	if dialog:
		play(dialog)

func _on_won_game_dialog():
	var dialog = load("res://resources/g_you_win.tres") as DialogResource
	if dialog:
		play(dialog)
