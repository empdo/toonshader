extends Node3D

@export var card_images: CardImages

var hidden = true
var card_type_id = -1

var data: CardData

func _ready():
	$area/Label3D.text = str(card_type_id)
	$area/Label3D2.text = $area/Label3D.text
	data = card_images.get_data(card_type_id)

	var material = $area/Bottom.material_override.duplicate()
	if material is StandardMaterial3D:
		material.albedo_texture = data.image
		$area/Bottom.material_override = material
		$area/Middle.material_override = material.duplicate()
		$area/Middle.material_override.uv1_scale.x = -1
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
				# Check if this is the first card click
				if not Globals.first_card_clicked:
					Globals.first_card_clicked = true
					Globals.first_card_clicked_dialog_requested.emit()
				
				hidden = false
				show_card()
				if Globals.cards_currently_showing.size() == Globals.MAX_SHOWABLE_CARDS:
					Globals.player_showed_chosen_cards.emit()
				#var time = $AnimationPlayer.get_animation("show_card").length
				#await get_tree().create_timer(time).timeout
				#hidden = true
				#hide_card()
				

func show_card_then_hide_it(time_shown):
	hidden = false
	show_card()
	await get_tree().create_timer(time_shown).timeout
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
