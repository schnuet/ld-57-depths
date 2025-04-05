class_name Player

extends CharacterBody2D

@export var SPEED = 300.0
@export var horizontal_decel = 4000
@export var horizontal_accel = 2000
@export var JUMP_VELOCITY = -800.0
@export var max_fall_speed = 800.0
@export var jump_break_factor = 0.5
@export var jump_gravity_factor = 2.0
@export var fall_gravity_factor = 4.0
@export var coyote_time = 0.1

signal deactivated
signal activated


@onready var animation: AnimatedSprite2D = get_node("Animation")

enum State { GROUNDED, JUMPING, FALLING, COYOTE_TIME_FALLING }

var state: State = State.GROUNDED

var coyote_timer: SceneTreeTimer

func _ready() -> void:
	switch_to_falling()
	

func _physics_process(delta: float) -> void:
	if is_on_floor():
		state = State.GROUNDED
	elif state == State.GROUNDED:
		state = State.COYOTE_TIME_FALLING
		animation.play("fall")
		coyote_timer = get_tree().create_timer(coyote_time)

	if state == State.GROUNDED:
		handle_horizontal_movement(delta)
		if absf(velocity.x) > 0:
			animation.play("move")
		else:
			animation.play("idle")
		handle_jump()

		move_and_slide()
	
	elif state == State.JUMPING:
		handle_gravity(delta, jump_gravity_factor)
		handle_horizontal_movement(delta)
		if Input.is_action_just_released("jump"):
			velocity.y *= jump_break_factor

		move_and_slide()

	elif state == State.FALLING or state == State.COYOTE_TIME_FALLING:
		if state == State.COYOTE_TIME_FALLING and coyote_timer and coyote_timer.time_left > 0:
			if Input.is_action_just_pressed("jump"):
				velocity.y = JUMP_VELOCITY
				switch_to_jumping()
			else:
				handle_gravity(delta, fall_gravity_factor)
		else:
			handle_gravity(delta, fall_gravity_factor)

		handle_horizontal_movement(delta)

		move_and_slide()

func switch_to_grounded():
	state = State.GROUNDED
	animation.play("idle")

func switch_to_falling():
	state = State.FALLING
	animation.play("fall")

func switch_to_jumping():
	if not state == State.JUMPING:
		SoundsManager.play_snd("snd_jump", 0.1);
	state = State.JUMPING
	animation.play("jump")

func is_on_ground():
	return is_on_floor()

func handle_gravity(delta: float, modifier: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * modifier
		if velocity.y > 0:
			if state != State.COYOTE_TIME_FALLING:
				switch_to_falling()
			velocity.y = minf(velocity.y, max_fall_speed)

func handle_jump():
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		switch_to_jumping()

func handle_horizontal_movement(delta: float):
	# Get the input direction and handle the movement/deceleration.
	var input_x = Input.get_axis("move_left", "move_right")
	velocity.x = calc_horizontal_velocity(velocity.x, input_x, delta)

func activate():
	activated.emit()
	z_index = 10

func deactivate():
	deactivated.emit()
	z_index = 0

func calc_horizontal_velocity(current_x: float, input_x: float, delta):
	var result = current_x
	if input_x != 0:
		if signf(input_x) != signf(current_x) and current_x != 0:
			result = brake_horizontal(current_x, delta)
		else:
			if absf(result) < SPEED:
				result = current_x + signf(input_x) * horizontal_accel * delta

			result = clampf(result, -SPEED, SPEED)
	else:
		result = brake_horizontal(current_x, delta)

	
	return result

func brake_horizontal(current_x: float, delta: float):
	var result = current_x - signf(current_x) * horizontal_decel * delta

	if signf(result) != signf(current_x):
		return 0

	return result

