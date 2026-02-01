extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var camera = $SpringArmPivot/SpringArm3D/Camera3D
@onready var armature = $barn/Armature
@onready var animation_tree = $barn/AnimationTree
const SPEED = 3.0
const LERP_VAL = .15
var focused = false

var prevent_move = false
var has_moved = false

const camera_move_to_table_duration = 1 

var camera_local_when_entered: Transform3D

var seeing_through_cards = false

@onready var cam = $SpringArmPivot/SpringArm3D/Camera3D
var moving_camera: Camera3D
@onready var cam_return = $Camreturn
@onready var player_return: Transform3D

var player_target2: Node3D

# Table camera look-around settings
var table_camera_base_transform: Transform3D
const TABLE_LOOK_MAX_X: float = deg_to_rad(30)  # 45 degrees horizontal
const TABLE_LOOK_MAX_Y: float = deg_to_rad(100)  # 100 degrees up
const TABLE_LOOK_SMOOTHING: float = 999999.0
var is_at_table: bool = false
var current_table_pitch: float = 0.0
var current_table_yaw: float = 0.0

func _ready():
	if Globals.will_respawn_at_table:
		position = player_target2.position
		rotation = player_target2.rotation
	
	Globals.player_entered_table_area_with_targets.connect(on_player_entered_table_area_with_targets)
	Globals.player_leaving_table_game.connect(on_player_leaving_table_game)
	Globals.won_game.connect(on_player_leaving_table_game)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.see_through_cards.connect(on_see_through_cards)

func on_see_through_cards(see: bool):
	seeing_through_cards = see
	if see:
		Globals.time_used_seeingmask += 1

func _process(delta: float):
	if seeing_through_cards:
		Globals.time_used_seeingmask += delta
		if Globals.time_used_seeingmask >= Globals.max_time_used_seeingmask_until_collapse:
			Globals.lost_game_by_mask.emit()
			# TODO: SHOW ANIMATION OF LOOSING CONTROL
			CardgameManager.reset()
			get_tree().change_scene_to_file("res://scenes/lost_by_mask.tscn")
	
	# Apply smooth table camera look-around based on mouse screen position
	if is_at_table and moving_camera:
		var viewport = get_viewport()
		var screen_size = viewport.get_visible_rect().size
		var mouse_pos = viewport.get_mouse_position()
		
		# Mouse position: 0-1 range
		var mx = mouse_pos.x / screen_size.x  # 0=left, 1=right
		var my = mouse_pos.y / screen_size.y  # 0=top, 1=bottom
		
		# Target angles
		var target_yaw = (mx - 0.5) * 2.0 * TABLE_LOOK_MAX_X  # -45 to +45 deg
		var target_pitch = (1.0 - my) * TABLE_LOOK_MAX_Y  # bottom=0, top=100 deg
		
		# Apply rotation: start from base, rotate by yaw (Y axis), then pitch (local X axis)
		moving_camera.global_transform = table_camera_base_transform
		moving_camera.rotate_y(-target_yaw)
		moving_camera.rotate_object_local(Vector3.RIGHT, target_pitch)

func on_player_leaving_table_game():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_at_table = false
	current_table_pitch = 0.0
	current_table_yaw = 0.0
	#global_transform = player_return
	#$CollisionShape3D.disabled = false
	#$SpringArmPivot/SpringArm3D.set_process(true)
	#$SpringArmPivot/SpringArm3D.set_physics_process(true)
	cam.reparent($SpringArmPivot/SpringArm3D)
	prevent_move = false
	cam.global_position = cam_return.global_position
	cam.global_rotation = cam_return.global_rotation
	cam.current = true

	moving_camera.current = false
	moving_camera.queue_free()

	
func on_player_entered_table_area_with_targets(player_target: Node3D, camera_target: Node3D):
	player_target2 = player_target
	prevent_move = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	moving_camera = cam.duplicate()
	add_child(moving_camera)
	moving_camera.set_as_top_level(true)
	moving_camera.global_transform = cam.global_transform
	moving_camera.current = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(moving_camera, "global_position", camera_target.global_position, camera_move_to_table_duration)
	tween.tween_property(moving_camera, "global_basis", camera_target.global_basis, camera_move_to_table_duration)
	
	await tween.finished
	
	# Store base transform and enable table look-around
	table_camera_base_transform = moving_camera.global_transform
	current_table_pitch = 0.0
	current_table_yaw = 0.0
	is_at_table = true
	
	# Trigger sit down dialog after camera movement completes
	Globals.sit_down_dialog_requested.emit()

	#player_return = global_transform
	position = player_target.position
	rotation = player_target.rotation
	

func _unhandled_input(event: InputEvent) -> void:
	# Handle table look-around when at table (position-based, not relative)
	if prevent_move and is_at_table:
		# We handle mouse position in _process instead
		return
	
	if prevent_move:
		return
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if focused else Input.MOUSE_MODE_VISIBLE
		focused = !focused
	
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI / 4, PI / 4)

func _physics_process(delta: float) -> void:
	if prevent_move:
		return
		
	cam_return.global_position = cam.global_position
	cam_return.global_rotation = cam.global_rotation
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	if direction:
		if not has_moved:
			has_moved = true
			_play_intro()
		velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_VAL)
		velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_VAL)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)
	
	animation_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED)

	move_and_slide()

func _play_intro():
	var intro = load("res://resources/a_intro.tres") as DialogResource
	if intro:
		DialogManager.play(intro)
