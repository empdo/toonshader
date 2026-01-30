# ForestGenerator.gd (Godot 4.0+)
@tool
extends Node3D
class_name ForestGenerator

@export_category("Prototype")
@export var prototype_scene: PackedScene
@export var parent_for_instances_path: NodePath = ^"Instances"

@export_category("Forest Area (X-Z plane)")
@export var area_size: Vector2 = Vector2(120.0, 120.0)

@export_category("Clearing (Rectangle, centered)")
@export var clearing_size: Vector2 = Vector2(30.0, 20.0)
@export var clearing_rotation_degrees: float = 0.0

@export_category("Placement")
@export var count: int = 600
@export var seed: int = 0
@export var max_attempts_per_instance: int = 20
@export var min_spacing: float = 0.0

@export_category("Rotation (degrees)")
@export var random_yaw: Vector2 = Vector2(0.0, 360.0)
@export var random_pitch: Vector2 = Vector2(0.0, 0.0)
@export var random_roll: Vector2 = Vector2(0.0, 0.0)

@export_category("Scale")
@export var uniform_scale: bool = true
@export var scale_uniform_range: Vector2 = Vector2(0.9, 1.2)
@export var scale_range_min: Vector3 = Vector3(0.9, 0.9, 0.9)
@export var scale_range_max: Vector3 = Vector3(1.2, 1.2, 1.2)

@export_category("Vertical Placement")
@export var y_offset: float = 0.0
@export var use_ray_cast_to_ground: bool = false
@export var ground_collision_mask: int = 1
@export var ray_height: float = 200.0
@export var ray_depth: float = 400.0

@export_category("Editor")
@export var clear_previous_on_generate: bool = true

# Inspector "buttons" (toggle true, it runs, then resets)
@export var editor_generate: bool = false : set = _set_editor_generate
@export var editor_clear: bool = false : set = _set_editor_clear

var _rng := RandomNumberGenerator.new()
var _placed_points: PackedVector2Array = PackedVector2Array()

func _set_editor_generate(v: bool) -> void:
	if not v:
		return
	# reset immediately so it behaves like a button
	editor_generate = false
	notify_property_list_changed()
	# defer so it runs after inspector updates finish
	call_deferred("generate")

func _set_editor_clear(v: bool) -> void:
	if not v:
		return
	editor_clear = false
	notify_property_list_changed()
	call_deferred("clear")

func generate() -> void:
	if prototype_scene == null:
		push_error("ForestGenerator: prototype_scene is not set.")
		return

	_seed_rng()

	var parent := _get_or_create_parent()
	if clear_previous_on_generate:
		_clear_children(parent)

	_placed_points.clear()

	var clearing_basis := Basis(Vector3.UP, deg_to_rad(clearing_rotation_degrees))

	var scene_owner := _get_scene_owner_for_persistence()
	if Engine.is_editor_hint() and scene_owner == null:
		push_error("ForestGenerator: edited_scene_root is null (open the scene in the editor).")
		return

	for i in count:
		var placed := false
		for attempt in max_attempts_per_instance:
			var p2 := _random_point_in_area()
			if _point_in_clearing(p2, clearing_basis):
				continue
			if min_spacing > 0.0 and _too_close(p2, min_spacing):
				continue

			var inst := prototype_scene.instantiate()
			parent.add_child(inst)

			if inst is Node3D:
				_position_instance(inst, p2)
				_rotate_instance(inst)
				_scale_instance(inst)

			# Make instances persist in the .tscn when generated in editor
			if scene_owner != null:
				_set_owner_recursive(inst, scene_owner)

			_placed_points.append(p2)
			placed = true
			break

		if not placed:
			continue

func clear() -> void:
	var parent := _get_or_create_parent()
	_clear_children(parent)
	_placed_points.clear()

func _seed_rng() -> void:
	if seed == 0:
		_rng.randomize()
	else:
		_rng.seed = seed

func _get_or_create_parent() -> Node:
	var node := get_node_or_null(parent_for_instances_path)
	if node == null:
		var created := Node3D.new()
		created.name = "Instances"
		add_child(created)
		parent_for_instances_path = created.get_path()

		var scene_owner := _get_scene_owner_for_persistence()
		if scene_owner != null:
			created.owner = scene_owner

		return created
	return node

func _clear_children(parent: Node) -> void:
	for c in parent.get_children():
		c.queue_free()

func _random_point_in_area() -> Vector2:
	var half := area_size * 0.5
	return Vector2(
		_rng.randf_range(-half.x, half.x),
		_rng.randf_range(-half.y, half.y)
	)

func _point_in_clearing(p: Vector2, clearing_basis: Basis) -> bool:
	var inv := clearing_basis.inverse()
	var v3 := inv * Vector3(p.x, 0.0, p.y)
	var half := clearing_size * 0.5
	return abs(v3.x) <= half.x and abs(v3.z) <= half.y

func _too_close(p: Vector2, spacing: float) -> bool:
	var s2 := spacing * spacing
	for q in _placed_points:
		if p.distance_squared_to(q) < s2:
			return true
	return false

func _position_instance(n: Node3D, p2: Vector2) -> void:
	var local_pos := Vector3(p2.x, y_offset, p2.y)

	if use_ray_cast_to_ground and is_inside_tree() and get_world_3d() != null:
		var hit := _ray_to_ground(local_pos)
		if hit.has("position"):
			local_pos.y = float(hit.position.y) + y_offset

	n.position = local_pos

func _ray_to_ground(local_pos: Vector3) -> Dictionary:
	var world_pos := to_global(local_pos)
	var from := world_pos + Vector3.UP * ray_height
	var to := world_pos - Vector3.UP * ray_depth
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, ground_collision_mask)
	query.exclude = [self]
	return space_state.intersect_ray(query)

func _rotate_instance(n: Node3D) -> void:
	var yaw := deg_to_rad(_rng.randf_range(random_yaw.x, random_yaw.y))
	var pitch := deg_to_rad(_rng.randf_range(random_pitch.x, random_pitch.y))
	var roll := deg_to_rad(_rng.randf_range(random_roll.x, random_roll.y))
	n.rotation = Vector3(pitch, yaw, roll)

func _scale_instance(n: Node3D) -> void:
	if uniform_scale:
		var s := _rng.randf_range(scale_uniform_range.x, scale_uniform_range.y)
		n.scale = Vector3(s, s, s)
	else:
		n.scale = Vector3(
			_rng.randf_range(scale_range_min.x, scale_range_max.x),
			_rng.randf_range(scale_range_min.y, scale_range_max.y),
			_rng.randf_range(scale_range_min.z, scale_range_max.z)
		)

func _get_scene_owner_for_persistence() -> Node:
	if Engine.is_editor_hint():
		return get_tree().edited_scene_root
	return null

func _set_owner_recursive(n: Node, new_owner: Node) -> void:
	n.owner = new_owner
	for c in n.get_children():
		_set_owner_recursive(c, new_owner)
