extends Node

var forest_music: AudioStreamPlayer
var intro_music: AudioStreamPlayer
var loop_music: AudioStreamPlayer

func _ready():
	# Get sibling nodes
	forest_music = get_parent().get_node_or_null("ForestMusic")
	intro_music = get_parent().get_node_or_null("IntroMusic")
	loop_music = get_parent().get_node_or_null("LoopMusic")
	
	print("MusicController: Ready")
	print("MusicController: forest_music = ", forest_music)
	print("MusicController: intro_music = ", intro_music)
	print("MusicController: loop_music = ", loop_music)
	
	Globals.player_entered_table_area.connect(_on_player_sat_down)
	
	# Connect finished signal for intro music
	if intro_music:
		intro_music.finished.connect(_on_intro_finished)

func _on_player_sat_down():
	print("MusicController: Player sat down - starting intro music")
	# Keep forest music playing in background
	
	if intro_music:
		intro_music.play()
		print("MusicController: Intro music playing, volume: ", intro_music.volume_db)
	else:
		print("MusicController: ERROR - intro_music is null!")

func _on_intro_finished():
	print("MusicController: Intro finished - starting loop music")
	# Start the loop music when intro finishes
	if loop_music:
		loop_music.play()
		print("MusicController: Loop music playing, volume: ", loop_music.volume_db)
	else:
		print("MusicController: ERROR - loop_music is null!")
