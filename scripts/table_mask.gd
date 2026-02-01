extends Node3D

var seeing = false

func _ready():
	$see.visible = not seeing
	$normal.visible = seeing


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if mouse_click:
		seeing = not seeing
		$see.visible = not seeing
		$normal.visible = seeing
		Globals.see_through_cards.emit(seeing)
