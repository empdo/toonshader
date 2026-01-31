extends Node3D

var hidden = true

func _ready():
	Globals.selected_card.connect(on_selected_card)

func on_selected_card(n: Node3D):
	pass

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	var mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if mouse_click:
		if hidden:
			if Globals.number_of_cards_showed < Globals.MAX_SHOWABLE_CARDS:
				hidden = false
				show_card()
		else:
			hidden = true
			hide_card()

func show_card():
	Globals.number_of_cards_showed += 1
	$AnimationPlayer.play("show_card")

func hide_card():
	Globals.number_of_cards_showed -= 1
	$AnimationPlayer.play("show_card", -1.0, -2.0, true)

func _on_area_mouse_exited() -> void:
	pass

func _on_area_mouse_entered() -> void:
	pass # Replace with function body.
