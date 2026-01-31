extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var camera = $SpringArmPivot/SpringArm3D/Camera3D
@onready var armature = $barn/Armature
@onready var animation_tree = $barn/AnimationTree
const SPEED = 8.0
const LERP_VAL = .15
var focused = false

var prevent_move = false

const camera_move_to_table_duration = 1 

var camera_local_when_entered: Transform3D

@onready var cam = $SpringArmPivot/SpringArm3D/Camera3D
var moving_camera: Camera3D
@onready var cam_return = $Camreturn
@onready var player_return: Transform3D

func _ready():
	Globals.player_entered_table_area_with_targets.connect(on_player_entered_table_area_with_targets)
	Globals.player_leaving_table_game.connect(on_player_leaving_table_game)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
func on_player_leaving_table_game():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
	prevent_move = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

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

	#player_return = global_transform
	position = player_target.position
	rotation = player_target.rotation
	

func _unhandled_input(event: InputEvent) -> void:
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
		velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_VAL)
		velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_VAL)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)
	
	animation_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED)

	move_and_slide()
