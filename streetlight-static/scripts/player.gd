extends CharacterBody3D

const TURN_SPEED = 2.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const BOARD_MAX_SPEED = 13.0
const PUSH_STRENGTH = 2
const BOARD_FRICTION = 0.5
const BRAKE_STRENGTH = 3.5
var on_board := true
var board_speed := 0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if on_board:
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			board_speed += PUSH_STRENGTH
		board_speed = move_toward(board_speed, 0, BOARD_FRICTION * delta)
		if Input.is_action_pressed("ui_down") and is_on_floor():
			board_speed = move_toward(board_speed, 0, BRAKE_STRENGTH * delta)
		board_speed = clamp(board_speed, 0, BOARD_MAX_SPEED)
		var turn := Input.get_axis("ui_right", "ui_left")
		rotate_y(turn * TURN_SPEED * delta)
		var forward := -transform.basis.z
		velocity.x = forward.x * board_speed
		velocity.z = forward.z * board_speed

	else:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
