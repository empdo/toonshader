extends Node3D

var seeing = false
var heartbeat_player: AudioStreamPlayer

func _ready():
	$see.visible = not seeing
	$normal.visible = seeing
	
	# Create heartbeat audio player
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.stream = load("res://sounds/heartbeat.wav")
	heartbeat_player.bus = "Master"
	add_child(heartbeat_player)
	heartbeat_player.finished.connect(_on_heartbeat_finished)

func _on_heartbeat_finished():
	# Loop the heartbeat sound while seeing through cards
	if seeing:
		heartbeat_player.play()

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if mouse_click:
		seeing = not seeing
		$see.visible = not seeing
		$normal.visible = seeing
		Globals.see_through_cards.emit(seeing)
		
		if seeing:
			heartbeat_player.play()
		else:
			heartbeat_player.stop()
