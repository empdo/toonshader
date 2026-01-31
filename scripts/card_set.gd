@tool
extends Node3D

var card_scene = preload("res://scenes/card.tscn")
const nr_cards = Vector2(4, 3)
const cards_spacing = Vector3(0.5, 0, 0.5)
const cards_random_spacing = Vector3(0.03, 0, 0.03)

var cards: Array[Node3D] = []

@export var refresh: bool = false:
	set(value):
		if value:
			refresh_layout()
		refresh = false

@export var clear_childs_do_not_use_pls: bool = false:
	set(value):
		if value:
			for c in get_children():
				c.queue_free()
		clear_childs_do_not_use_pls = false

func refresh_layout():
	clear_cards()
	add_new_cards()

func clear_cards():
	for c in cards:
		c.queue_free()
	cards.clear()

func add_new_cards():
	var id_increment = 0
	var pos = Vector3.ZERO
	for y in range(nr_cards.y):
		for x in range(nr_cards.x):
			var random_x_add = randf_range(-cards_random_spacing.x, cards_random_spacing.x)
			var random_z_add = randf_range(-cards_random_spacing.z, cards_random_spacing.z)
			var p = pos + Vector3(random_x_add, 0, random_z_add)
			spawn_card(id_increment, p)
			id_increment += 1
			pos.x += cards_spacing.x
		pos.x = 0
		pos.z += cards_spacing.z

func spawn_card(id: int, pos: Vector3):
	var c: Node3D = card_scene.instantiate()
	c.position = pos
	c.set("card_type_id", id)
	cards.append(c)
	add_child(c)

func _ready():
	refresh_layout()


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
