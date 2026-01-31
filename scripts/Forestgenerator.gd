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
		
		# 1. ADD CHILD FIRST
		# This ensures the node runs its _ready() and registers with the engine
		add_child(inst)
		
		# 2. Set Owner (Required for the editor to save the nodes)
		if owner_node:
			inst.owner = owner_node

		# 3. Apply Transform safely
		var pos := Vector3(
			rng.randf_range(-half.x, half.x),
			0,
			rng.randf_range(-half.y, half.y)
		)
		
		var rand_y_rot := rng.randf_range(0, TAU)
		
		# Use global_transform to avoid local parent weirdness
		# Construct Basis: Axis, Angle
		var basis := Basis(Vector3.UP, rand_y_rot)
		
		var s := rng.randf_range(scale_range.x, scale_range.y)
		if s < 0.001: s = 1.0 # Extra safety floor
		
		# Apply scale to the basis
		basis = basis.scaled(Vector3(s, s, s))
		
		inst.global_transform = Transform3D(basis, pos)

func _clear() -> void:
	for child in get_children():
		child.free()
