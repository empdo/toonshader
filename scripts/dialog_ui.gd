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
	
	# Start displaying dialog lines
	_display_dialog_lines()

func _display_dialog_lines():
	if not current_dialog:
		return
	
	# Display each line
	for line_index in range(current_dialog.lines.size()):
		var line = current_dialog.lines[line_index]
		
		# Check for pause marker @X (e.g. @12 means 12 second pause)
		var pause_time = _parse_pause_marker(line)
		if pause_time > 0:
			# This line is a pause marker, wait and continue
			await get_tree().create_timer(pause_time).timeout
			continue
		
		label.text = ""
		
		# Get audio for this line (if available)
		var line_audio: AudioStream = null
		if line_index < current_dialog.line_audio.size():
			line_audio = current_dialog.line_audio[line_index]
		
		# Calculate time per character based on audio length or default
		var time_per_char: float
		if line_audio and line_audio.get_length() > 0:
			# Use audio length to determine typing speed
			var audio_length = line_audio.get_length()
			time_per_char = audio_length / float(line.length()) if line.length() > 0 else 0.0
			
			# Play the audio for this line
			audio_player.stream = line_audio
			audio_player.play()
		else:
			# No audio - use default characters per second
			time_per_char = 1.0 / Globals.DEFAULT_CHARS_PER_SECOND
		
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

# Parse pause marker like @12 and return the pause duration in seconds
# Returns 0 if not a valid pause marker
func _parse_pause_marker(line: String) -> float:
	var trimmed = line.strip_edges()
	if not trimmed.begins_with("@"):
		return 0.0
	
	var number_part = trimmed.substr(1)
	if number_part.is_valid_float():
		return number_part.to_float()
	elif number_part.is_valid_int():
		return float(number_part.to_int())
	
	return 0.0

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
