extends Resource
class_name CardImages

@export var cards: Array[CardData] = []

func get_data(i: int):
	return cards[i]

func get_set_of_ids(size: int) -> Array[int]:
	var o: Array[int] = []
	for i in range(len(cards)):
		o.append(i)
	for i in range(size - len(cards)):
		o.append(randi_range(0, len(cards)-1))
	
	return o
