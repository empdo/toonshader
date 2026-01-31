extends Node3D


func _ready():
	Globals.highlight_card.connect(on_highlight_card)
	Globals.say_card_type.connect(on_say_card_type)

func on_highlight_card(card: Node3D):
	visible = true
	global_position = card.global_position
	await get_tree().create_timer(2).timeout
	visible = false
	
func on_say_card_type(type: int):
	$Label3D.text = str(type)
