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
const BAIL_SPEED = 4.0
const GRASS_BAIL_SPEED = 6.0
const BAIL_RECOVERY = 1.5
const HEAD_TURN_SPEED = 2.5
const HEAD_MAX_TURN = 1.5
const HEAD_RETURN_SPEED = 3.0
var on_board := true
var board_speed := 0.0
var on_grass := false
var push_timer := 0.0
var bail_timer := 0.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if bail_timer > 0:
		bail_timer -= delta
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

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
		var look := Input.get_axis("look_right", "look_left")
		if look != 0:
			$firstPersonCamera.rotation.y += look * HEAD_TURN_SPEED * delta
		else:
			$firstPersonCamera.rotation.y = move_toward($firstPersonCamera.rotation.y, 0, HEAD_RETURN_SPEED * delta)
		$firstPersonCamera.rotation.y = clamp($firstPersonCamera.rotation.y, -HEAD_MAX_TURN, HEAD_MAX_TURN)
		var forward := -transform.basis.z
		velocity.x = forward.x * board_speed
		velocity.z = forward.z * board_speed

	else:
		$firstPersonCamera.rotation.y = 0
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var turn := Input.get_axis("look_right", "look_left")
		rotate_y(turn * TURN_SPEED * delta)
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	on_grass = $groundRay.is_colliding() and $groundRay.get_collider().is_in_group("grass")

	if on_board and on_grass and board_speed > GRASS_BAIL_SPEED:
		bail()

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var normal := col.get_normal()
		if is_on_floor() and on_board and abs(normal.y) < 0.3 and -transform.basis.z.dot(normal) < -0.7 and board_speed > BAIL_SPEED:
			bail()

func bail() -> void:
	on_board = false
	board_speed = 0.0
	bail_timer = BAIL_RECOVERY
