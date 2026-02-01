extends Resource
class_name CardImages

@export var cards: Array[CardData] = []

func get_data(id: int) -> CardData:
	if id >= len(cards):
		return cards[0]
	return cards[id]
