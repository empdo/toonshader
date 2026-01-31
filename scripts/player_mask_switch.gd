extends Skeleton3D


func _ready():
	Globals.see_through_cards.connect(on_see_through_cards)
	
func on_see_through_cards(see: bool):
	$mask2.visible = not see
	$skulleyes.visible = not see
	$skullnose.visible = not see
	
	$mask1.visible = see
	$mask1eye.visible = see
	$mask1pupil.visible = see
		
