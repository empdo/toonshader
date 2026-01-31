extends Control

@onready var label: Label = $Label
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var current_dialog: DialogResource = null
var is_playing: bool = false

func _ready():
	label.text = ""
	visible = false
	DialogManager.dialog_requested.connect(_on_dialog_requested)
	DialogManager.dialog_stop_requested.connect(_stop)
	DialogManager.ui_ready()

func _on_dialog_requested(dialog: DialogResource):
	if is_playing:
		_stop()
	current_dialog = dialog
	is_playing = true
	visible = true
	_display_lines()

func _display_lines():
	for i in range(current_dialog.lines.size()):
		var line = current_dialog.lines[i]
		
		# Pause marker (@2 = 2 sek paus)
		var pause = _parse_pause(line)
		if pause > 0:
			await get_tree().create_timer(pause).timeout
			continue
		
		label.text = ""
		
		# Audio för denna rad
		var line_audio: AudioStream = null
		if i < current_dialog.line_audio.size():
			line_audio = current_dialog.line_audio[i]
		
		# Beräkna tid per tecken
		var time_per_char: float
		if line_audio and line_audio.get_length() > 0:
			time_per_char = line_audio.get_length() / float(line.length()) if line.length() > 0 else 0.0
			audio_player.stream = line_audio
			audio_player.play()
		else:
			time_per_char = 1.0 / DialogManager.DEFAULT_CHARS_PER_SECOND
		
		# Typewriter-effekt
		for c in range(line.length() + 1):
			if not is_playing:
				return
			label.text = line.substr(0, c)
			await get_tree().create_timer(time_per_char).timeout
		
		if i < current_dialog.lines.size() - 1:
			await get_tree().create_timer(0.5).timeout
	
	await get_tree().create_timer(1.5).timeout
	_finish()

func _parse_pause(line: String) -> float:
	var t = line.strip_edges()
	if not t.begins_with("@"):
		return 0.0
	var num = t.substr(1)
	if num.is_valid_float():
		return num.to_float()
	return 0.0

func _stop():
	is_playing = false
	visible = false
	label.text = ""
	current_dialog = null
	if audio_player.playing:
		audio_player.stop()

func _finish():
	_stop()
	DialogManager._on_finished()
