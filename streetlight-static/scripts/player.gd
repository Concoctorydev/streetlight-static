extends CharacterBody3D

const TURN_SPEED = 2.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const BOARD_MAX_SPEED = 13.0
const PUSH_STRENGTH = 2.0
const BOARD_FRICTION = 0.5
const BRAKE_STRENGTH = 3.5
const GRASS_FRICTION = 13.0
const PUSH_INTERVAL = 0.7
var on_board := true
var board_speed := 0.0
var on_grass := false
var push_timer := 0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if on_board:
		if Input.is_action_pressed("push") and is_on_floor():
			push_timer -= delta
			if push_timer <= 0:
				board_speed += PUSH_STRENGTH
				push_timer = PUSH_INTERVAL
		else:
			push_timer = 0
		board_speed = move_toward(board_speed, 0, BOARD_FRICTION * delta)
		if Input.is_action_pressed("brake") and is_on_floor():
			board_speed = move_toward(board_speed, 0, BRAKE_STRENGTH * delta)
		if on_grass and is_on_floor():
			board_speed = move_toward(board_speed, 0, GRASS_FRICTION * delta)
		board_speed = clamp(board_speed, 0, BOARD_MAX_SPEED)
		var turn := Input.get_axis("turn_right", "turn_left")
		rotate_y(turn * TURN_SPEED * delta)
		var forward := -transform.basis.z
		velocity.x = forward.x * board_speed
		velocity.z = forward.z * board_speed

	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	on_grass = $groundRay.is_colliding() and $groundRay.get_collider().is_in_group("grass")
