extends Node3D

@export var card_images: CardImages

var hidden = true
var card_type_id = -1

func _ready():
	$area/Label3D.text = str(card_type_id)
	$area/Label3D2.text = $area/Label3D.text
	
	var material = $area/Bottom.get_active_material(0)
	print("e")
	if material is StandardMaterial3D:
		var data = card_images.get_data(card_type_id)
		material.albedo_texture = data.image
		
	Globals.see_through_cards.connect(on_see_through_cards)
	
func on_see_through_cards(see: bool):
	$area/Top.visible = not see


func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not Globals.let_player_show_cards:
		return
	
	var mouse_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if mouse_click:
		if hidden:
			if Globals.cards_currently_showing.size() < Globals.MAX_SHOWABLE_CARDS:
				hidden = false
				show_card()
				if Globals.cards_currently_showing.size() == Globals.MAX_SHOWABLE_CARDS:
					Globals.player_showed_chosen_cards.emit()
				#var time = $AnimationPlayer.get_animation("show_card").length
				#await get_tree().create_timer(time).timeout
				#hidden = true
				#hide_card()
				

func show_card_then_hide_it():
	hidden = false
	show_card()
	var time = $AnimationPlayer.get_animation("show_card").length
	await get_tree().create_timer(time).timeout
	hidden = true
	hide_card()
	
func show_card():
	Globals.cards_currently_showing[self] = true
	$AnimationPlayer.play("show_card")

func hide_card():
	Globals.cards_currently_showing.erase(self)
	$AnimationPlayer.play("show_card", -1.0, -5.0, true)

func _on_area_mouse_exited() -> void:
	pass

func _on_area_mouse_entered() -> void:
	pass
