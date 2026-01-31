extends Control

signal dialog_finished(dialog: DialogResource)

@onready var label: Label = $Label
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var current_dialog: DialogResource = null
var is_playing: bool = false

func _ready():
	label.text = ""
	visible = false
	add_to_group("dialog_ui")

func show_dialog(dialog: DialogResource):
	if is_playing:
		stop_dialog()
	
	current_dialog = dialog
	is_playing = true
	visible = true
	
	# Play audio if provided
	if dialog.audio:
		audio_player.stream = dialog.audio
		audio_player.play()
	
	# Start displaying dialog lines
	_display_dialog_lines()

func _display_dialog_lines():
	if not current_dialog:
		return
	
	# Calculate characters per second (use dialog override or default)
	var chars_per_second: float
	if current_dialog.characters_per_second > 0:
		chars_per_second = current_dialog.characters_per_second
	else:
		chars_per_second = Globals.DEFAULT_CHARS_PER_SECOND
	
	var time_per_char = 1.0 / chars_per_second
	
	# Display each line
	for line_index in range(current_dialog.lines.size()):
		var line = current_dialog.lines[line_index]
		label.text = ""
		
		# Typewriter effect for this line
		for char_index in range(line.length() + 1):
			if not is_playing:
				return  # Dialog was stopped
			label.text = line.substr(0, char_index)
			await get_tree().create_timer(time_per_char).timeout
		
		# Wait a moment before next line (except for last line)
		if line_index < current_dialog.lines.size() - 1:
			await get_tree().create_timer(0.5).timeout
	
	# Wait a bit after the last line before closing dialog
	await get_tree().create_timer(1.5).timeout
	
	# All lines complete
	finish_dialog()

func stop_dialog():
	is_playing = false
	visible = false
	label.text = ""
	current_dialog = null
	if audio_player.playing:
		audio_player.stop()

func finish_dialog():
	var finished_dialog = current_dialog
	stop_dialog()
	dialog_finished.emit(finished_dialog)
