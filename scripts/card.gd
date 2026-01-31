extends Node3D

var hidden = true
var card_type_id = -1

func _ready():
	$area/Label3D.text = str(card_type_id)
	$area/Label3D2.text = $area/Label3D.text
	
	Globals.see_through_cards.connect(on_see_through_cards)
	
func on_see_through_cards(see: bool):
	$area/Top.visible = not see


func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#var mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	#if mouse_click:
	#	if hidden:
	#		if Globals.number_of_cards_showed < Globals.MAX_SHOWABLE_CARDS:
	#			hidden = false
	#			show_card()
	#			var time = $AnimationPlayer.get_animation("show_card").length
	#			await get_tree().create_timer(time).timeout
	#			hidden = true
	#			hide_card()
	pass

func show_card_then_hide_it():
	hidden = false
	show_card()
	var time = $AnimationPlayer.get_animation("show_card").length
	await get_tree().create_timer(time).timeout
	hidden = true
	hide_card()
	
func show_card():
	Globals.number_of_cards_showed += 1
	$AnimationPlayer.play("show_card")

func hide_card():
	Globals.number_of_cards_showed -= 1
	$AnimationPlayer.play("show_card", -1.0, -5.0, true)

func _on_area_mouse_exited() -> void:
	pass

func _on_area_mouse_entered() -> void:
	pass
