@tool
extends Node3D
class_name ForestGenerator

@export var scene: PackedScene
@export var count: int = 100
@export var area_size: Vector2 = Vector2(100.0, 100.0)
@export var scale_range: Vector2 = Vector2(0.8, 1.2)
@export var rng_seed: int = 0

@export var generate: bool = false:
	set(v):
		if v:
			_generate()

@export var clear: bool = false:
	set(v):
		if v:
			_clear()

func _generate() -> void:
	if scene == null:
		push_error("ForestGenerator: Ingen scene vald")
		return
	
	_clear()
	
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	
	var half := area_size * 0.5
	var owner_node: Node = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	
	for i in count:
		var inst: Node3D = scene.instantiate()
		
		# Sätt transform INNAN vi lägger till i scenen
		inst.position = Vector3(
			rng.randf_range(-half.x, half.x),
			0,
			rng.randf_range(-half.y, half.y)
		)
		inst.rotation.y = rng.randf_range(0, TAU)
		var s := rng.randf_range(scale_range.x, scale_range.y)
		if s < 0.01:
			s = 1.0
		inst.scale = Vector3(s, s, s)
		
		add_child(inst)
		
		if owner_node:
			_set_owner_recursive(inst, owner_node)

func _clear() -> void:
	for child in get_children():
		child.free()

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)
