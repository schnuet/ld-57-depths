class_name Jumper
extends CharacterBody2D

# This is a CharacterController for a 2D platformer character with a lot of movement abilities.
# The set is comparable to the Hollow Knight character.
# It has the following abilities:
# - Jump
# - Dash down
# - Dash side
# - Wall slide
# - Slash (melee attack)
# - Air slash (melee attack)
# - Ground slash (melee attack)
# - 

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	#DASH_DOWN,
	DASH_SIDE,
	WALL_SLIDE,
	SLASH_AIR_SIDE,
	SLASH_AIR_DOWN,
	SLASH_AIR_UP,
	SLASH_GROUND,
	GROUND_ATTACK_PREPARE,
	SMASH,
	DEAD
}
var state: State = State.IDLE;

var enabled = true;

@onready var hurtbox_collision = $HurtBox2D/CollisionShape2D;

signal hurt(amount: int);

# ========================================
# LOOP

func _physics_process(delta: float) -> void:
	if enabled:
		handle_state(delta)
	else:
		apply_gravity(delta);

	process_timers(delta)

	# Move the character.
	move_and_slide()
	update_animation_side()


# ========================================
# IDLE

func enter_state_idle(_state_before: State):
	friction = GROUND_FRICTION
	remaining_mid_air_jumps = MID_AIR_JUMPS;
	set_animation("idle")

func handle_state_idle(delta: float):
	if Input.is_action_just_pressed("jump") or jump_buffer_timer > 0:
		enter_state(State.JUMP)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("left"):
		dash_to_side(Vector2.LEFT)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("right"):
		dash_to_side(Vector2.RIGHT)
		return
	
	if Input.is_action_just_pressed("slash") and Input.is_action_pressed("slash") and slash_cooldown_timer <= 0:
		print("idle -> slash");
		ground_slash()
		return
	
	apply_gravity(delta)
	apply_horizontal_movement(delta)

	if not is_on_floor():
		start_coyote_time()
		enter_state(State.FALL)
		return
	
	if velocity.x != 0:
		enter_state(State.RUN)
		return


# ========================================
# RUN

@export var RUN_SPEED: float = 400.0

var last_side: Vector2 = Vector2.RIGHT

func enter_state_run(_state_before: State):
	friction = GROUND_FRICTION
	remaining_mid_air_jumps = MID_AIR_JUMPS;
	set_animation("run")

func handle_state_run(delta: float):
	if Input.is_action_just_pressed("jump") or jump_buffer_timer > 0:
		enter_state(State.JUMP)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("left"):
		dash_to_side(Vector2.LEFT)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("right"):
		dash_to_side(Vector2.RIGHT)
		return
	
	if Input.is_action_just_pressed("slash") and Input.is_action_pressed("slash") and slash_cooldown_timer <= 0:
		print("idle -> slash");
		ground_slash();
		return
	
	if not is_on_floor():
		start_coyote_time()
		enter_state(State.FALL)
		return
	
	apply_gravity(delta)
	apply_horizontal_movement(delta)
	
	if velocity.x == 0:
		enter_state(State.IDLE)
		return


# ========================================
# JUMP

@export_category("Jump")

@export var can_jump: bool = true;
@export var JUMP_VELOCITY: float = -1000.0

@export var COYOTE_TIME: float = 0.15;
var coyote_timer: float = 0.0

@export var JUMP_BUFFER_TIME: float = 0.1
var jump_buffer_timer = 0.0

@export var MID_AIR_JUMPS: int = 1;
var remaining_mid_air_jumps = MID_AIR_JUMPS;

@onready var double_jump_tentacles = $double_jump_tentacles;

func enter_state_jump(_state_before: State):
	coyote_timer = 0;
	velocity.y = JUMP_VELOCITY;
	friction = AIR_FRICTION
	jump_buffer_timer = 0
	set_animation("jump")

func handle_state_jump(delta: float):
	if Input.is_action_just_released("jump"):
		velocity.y = 0
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("left"):
		dash_to_side(Vector2.LEFT)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("right"):
		dash_to_side(Vector2.RIGHT)
		return
	
	if Input.is_action_just_pressed("slash") and slash_cooldown_timer <= 0:
		air_slash();
		return

	apply_gravity(delta)
	apply_horizontal_movement(delta)

	if velocity.y >= 0:
		enter_state(State.FALL)
		return


func enter_state_fall(_state_before: State):
	friction = AIR_FRICTION
	set_animation("fall")

func handle_state_fall(delta: float):
	apply_gravity(delta)
	apply_horizontal_movement(delta)

	if Input.is_action_just_pressed("jump"):
		if wall_jump_timer > 0:
			wall_jump()
			return
		if coyote_timer > 0:
			enter_state(State.JUMP)
			return
		if remaining_mid_air_jumps > 0:
			remaining_mid_air_jumps -= 1;
			show_double_jump_effect();
			enter_state(State.JUMP);
			return
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("left"):
		dash_to_side(Vector2.LEFT)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("right"):
		dash_to_side(Vector2.RIGHT)
		return
	
	if Input.is_action_just_pressed("slash") and slash_cooldown_timer <= 0:
		air_slash();
		return

	if can_wall_slide and is_on_wall():
		enter_state(State.WALL_SLIDE)
		return
	
	if is_on_floor():
		enter_state(State.IDLE)
		return


func start_coyote_time():
	coyote_timer = COYOTE_TIME


func activate_double_jump():
	MID_AIR_JUMPS = 1;


func _on_double_jump_tentacles_animation_finished() -> void:
	double_jump_tentacles.hide();


func show_double_jump_effect():
	double_jump_tentacles.show();
	double_jump_tentacles.play();

# ========================================
# WALL SLIDE

@export var can_wall_slide: bool = true;

const WALL_SLIDE_HORIZONTAL_JUMP_SPEED = 800.0
var wall_slide_side = Vector2.RIGHT;

const WALL_JUMP_TIME = 0.1
var wall_jump_timer = 0.0

func enter_state_wall_slide(_state_before: State):
	var wall_normal = get_wall_normal()
	print("wall slide ", wall_normal)
	if wall_normal.x > 0:
		wall_slide_side = Vector2.LEFT
	else:
		wall_slide_side = Vector2.RIGHT
	
	remaining_mid_air_jumps = MID_AIR_JUMPS;
	set_animation("wall_slide")

func handle_state_wall_slide(delta: float):
	velocity.x = wall_slide_side.x * 10.0

	# apply half gravity
	var gravity = get_gravity()
	velocity += gravity / 4 * delta

	# limit the fall speed
	if velocity.y > 0:
		velocity.y = min(velocity.y, 200.0)


	if is_on_floor():
		enter_state(State.IDLE)
		return

	var horizontal_move_direction = get_horizontal_direction_vector()
	
	if Input.is_action_just_pressed("jump"):
		wall_jump()
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("left"):
		dash_to_side(Vector2.LEFT)
		return
	
	if Input.is_action_just_pressed("dash") and Input.is_action_pressed("right"):
		dash_to_side(Vector2.RIGHT)
		return
	
	if horizontal_move_direction == Vector2.ZERO:
		pass
	elif horizontal_move_direction != wall_slide_side:
		# leave wall
		velocity.x = 0
		start_wall_jump_timer()
		enter_state(State.FALL)
		return
	
	if Input.is_action_just_pressed("slash"):
		enter_state(State.SLASH_AIR_SIDE)
		return

	# as soon as there is no wall anymore, we fall
	if not is_on_wall():
		print("not on wall ", horizontal_move_direction, wall_slide_side)
		velocity.x = 0
		start_wall_jump_timer()
		enter_state(State.FALL)
		return

func start_wall_jump_timer():
	wall_jump_timer = WALL_JUMP_TIME

func wall_jump():
	velocity.x = wall_slide_side.x * -WALL_SLIDE_HORIZONTAL_JUMP_SPEED
	enter_state(State.JUMP)

# ========================================
# DASH

@export_category("Dash")

#@export var DASH_DOWN_VELOCITY = 1600.0
@export var DASH_SIDE_VELOCITY = 1600.0
@export var DASH_UP_VELOCITY = 1600.0

@onready var dash_tentacles = $dash_tentacles;

const DASH_TIME = 0.2
var dash_timer = 0.0

func enter_state_dash_side(_state_before: State):
	dash_timer = DASH_TIME
	set_animation("dash_side");
	dash_tentacles.show();
	dash_tentacles.play();

func handle_state_dash_side(_delta: float):
	if dash_timer <= 0:
		velocity.x = RUN_SPEED * sign(velocity.x);
		enter_state(State.FALL);
		hurtbox_collision.disabled = false;
		return

func dash_to_side(side: Vector2):
	velocity.x = side.x * DASH_SIDE_VELOCITY
	velocity.y = 0
	dash_tentacles.scale.y = side.x * 2;
	enter_state(State.DASH_SIDE);
	hurtbox_collision.disabled = true;


func _on_dash_tentacles_animation_finished() -> void:
	dash_tentacles.hide();

#func enter_state_dash_down(_state_before: State):
	#velocity.x = 0
	#velocity.y = DASH_DOWN_VELOCITY
	#set_animation("dash_down")
#
#func handle_state_dash_down(delta: float):
#
	#if is_on_floor():
		#enter_state(State.IDLE)
		#return
#
	#apply_gravity(delta)

#
#func enter_state_dash_up(_state_before: State):
	#velocity.x = 0
	#velocity.y = -DASH_UP_VELOCITY
	#set_animation("dash_up")
#
#func handle_state_dash_up(_delta: float):
#
	#if is_on_floor():
		#enter_state(State.IDLE)
		#return


# ========================================
# ATTACKS

@export_category("Attacks")

const SLASH_MOVE_SPEED = 300.0

const SLASH_TIME = 0.1
var slash_timer = 0.0
var has_hit_hurtbox = false;

var slash_direction = Vector2.RIGHT;

var SLASH_COOLDOWN = 0.25;
var slash_cooldown_timer = 0;

@onready var hitbox_slash_right = $hitbox_slash_right;
@onready var hitbox_slash_left = $hitbox_slash_left;
@onready var hitbox_slash_up = $hitbox_slash_up;
@onready var hitbox_slash_down = $hitbox_slash_down;

func air_slash():
	var direction = get_main_input_direction()
	if direction == Vector2.ZERO:
		direction = last_side
	slash_direction = direction
	#if direction == Vector2.DOWN:
		#enter_state(State.SLASH_AIR_DOWN)
	#elif direction == Vector2.UP:
		#enter_state(State.SLASH_AIR_UP)
	#else:
	enter_state(State.SLASH_AIR_SIDE)


func enter_state_slash_air_side(_state_before: State):
	velocity.x = sign(last_side.x) * SLASH_MOVE_SPEED
	velocity.y = 0
	slash_timer = SLASH_TIME
	set_animation("attack_air");
	has_hit_hurtbox = false;
	slash_cooldown_timer = SLASH_COOLDOWN;
	enable_slash_hitbox()

func handle_state_slash_air_side(delta: float):
	velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	if slash_timer <= 0:
		enter_state(State.FALL)
		return


func enter_state_slash_air_down(_state_before: State):
	velocity.x = 0
	velocity.y = SLASH_MOVE_SPEED
	slash_timer = SLASH_TIME
	has_hit_hurtbox = false;
	slash_cooldown_timer = SLASH_COOLDOWN;
	set_animation("attack_air")
	enable_slash_hitbox()

func handle_state_slash_air_down(delta: float):
	apply_gravity(delta)

	if slash_timer <= 0:
		enter_state(State.FALL)
		return


func enter_state_slash_air_up(_state_before: State):
	velocity.x = 0
	velocity.y = -SLASH_MOVE_SPEED
	slash_timer = SLASH_TIME
	slash_cooldown_timer = SLASH_COOLDOWN;
	has_hit_hurtbox = false;
	set_animation("attack_air")
	enable_slash_hitbox()

func handle_state_slash_air_up(delta: float):
	apply_gravity(delta)

	if slash_timer <= 0:
		enter_state(State.FALL)
		return


# GROUND ATTACK PREPARE

@export var SMASH_PREPARE_TIME = 0.5
var ground_attack_prepare_timer = 0.0

func enter_state_ground_attack_prepare(_state_before: State):
	velocity.x = 0
	velocity.y = 0
	ground_attack_prepare_timer = 0;
	set_animation("attack_ground_prepare")

func handle_state_ground_attack_prepare(delta: float):
	ground_attack_prepare_timer += delta
	# end attack prepare
	if ground_attack_prepare_timer >= SMASH_PREPARE_TIME:
		enter_state(State.SMASH);
	if not Input.is_action_pressed("slash"):
		enter_state(State.IDLE)
		return
	

# SLASH GROUND

var slash_still_pressed = false;

func ground_slash():
	var direction = get_main_input_direction()
	if direction == Vector2.ZERO:
		direction = last_side
	slash_direction = direction
	if direction == Vector2.UP:
		enter_state(State.SLASH_AIR_UP)
	else:
		enter_state(State.SLASH_GROUND)

func enter_state_slash_ground_side(_state_before: State):
	print("START GROUND SLASH");
	velocity.x = 0
	velocity.y = 0
	slash_timer = SLASH_TIME
	slash_cooldown_timer = SLASH_COOLDOWN;
	has_hit_hurtbox = false;
	set_animation("attack_ground")
	slash_still_pressed = true;
	enable_slash_hitbox()

func handle_state_slash_ground_side(_delta: float):
	if not Input.is_action_pressed("slash"):
		slash_still_pressed = false;
	
	if has_hit_hurtbox:
		velocity.x = -slash_direction.x * SLASH_MOVE_SPEED;
		has_hit_hurtbox = false;
	
	if slash_timer <= 0:
		if slash_still_pressed:
			enter_state(State.GROUND_ATTACK_PREPARE);
		else:
			enter_state(State.IDLE)
		return


# SLASH hitboxes

func enable_slash_hitbox():
	var hitbox;
	if slash_direction == Vector2.LEFT:
		hitbox = hitbox_slash_left
	elif slash_direction == Vector2.RIGHT:
		hitbox = hitbox_slash_right
	elif slash_direction == Vector2.UP:
		hitbox = hitbox_slash_up
	elif slash_direction == Vector2.DOWN:
		hitbox = hitbox_slash_down
	
	var hit_box_collisions = hitbox.get_node("CollisionShape2D")
	hit_box_collisions.disabled = false;
	hitbox.visible = true;
	await get_tree().physics_frame
	hit_box_collisions.disabled = true;
	hitbox.visible = false;

# SMASH

var SMASH_DURATION = 0.5
var smash_timer = 0.0

var smash_direction: Vector2 = Vector2.RIGHT;

func enter_state_smash(_state_before: State):
	velocity.x = 0
	velocity.y = 0
	smash_timer = 0
	smash_direction = last_side
	has_hit_hurtbox = false;
	slash_cooldown_timer = SLASH_COOLDOWN;
	set_animation("attack_smash")
	enable_smash_hitbox()

func handle_state_smash(delta: float):
	smash_timer += delta
	velocity.x = move_toward(velocity.x, 0, 1000 * delta)

	if smash_timer >= SMASH_DURATION:
		enter_state(State.IDLE)
		return


# SMASH hitboxes

@onready var smash_hitbox_right = $hitbox_smash_right;
@onready var smash_hitbox_left = $hitbox_smash_left;

func enable_smash_hitbox():
	var hitbox;
	if smash_direction == Vector2.LEFT:
		hitbox = smash_hitbox_left
	elif smash_direction == Vector2.RIGHT:
		hitbox = smash_hitbox_right
	
	var hit_box_collisions = hitbox.get_node("CollisionShape2D")
	hit_box_collisions.disabled = false;
	hitbox.visible = true;
	await get_tree().physics_frame
	hit_box_collisions.disabled = true;
	hitbox.visible = false;



func _on_hitbox_slash_right_hurt_box_entered(_hurt_box: HurtBox2D) -> void:
	has_hit_hurtbox = true;

func _on_hitbox_slash_left_hurt_box_entered(_hurt_box: HurtBox2D) -> void:
	has_hit_hurtbox = true;

func _on_hitbox_slash_up_hurt_box_entered(_hurt_box: HurtBox2D) -> void:
	has_hit_hurtbox = true;

func _on_hitbox_slash_down_hurt_box_entered(_hurt_box: HurtBox2D) -> void:
	has_hit_hurtbox = true;


# ========================================
# DEATH

func die():
	enter_state(State.DEAD)

func enter_state_dead(_state_before: State):
	set_animation("die")

func handle_state_dead(delta: float):
	apply_gravity(delta)


# ========================================
# MOVEMENT

const ACCELERATION: float = 4000.0
const GROUND_FRICTION: float = 8000.0
const AIR_FRICTION: float = 500.0

var friction: float = GROUND_FRICTION

func apply_horizontal_movement(delta):
	var move_direction = get_horizontal_input()

	var max_stop_power = max(ACCELERATION, friction)

	# update last side
	var target_velocity = move_direction * RUN_SPEED;
	if move_direction < 0:
		last_side = Vector2.LEFT
		if velocity.x > 0:
			velocity.x = move_toward(velocity.x, 0, max_stop_power * delta)
		elif velocity.x >= target_velocity:
			velocity.x = move_toward(velocity.x, target_velocity, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, target_velocity, friction * delta)
	elif move_direction > 0:
		last_side = Vector2.RIGHT
		if velocity.x < 0:
			velocity.x = move_toward(velocity.x, 0, max_stop_power * delta)
		elif velocity.x <= target_velocity:
			velocity.x = move_toward(velocity.x, target_velocity, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, target_velocity, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)



func get_horizontal_input() -> float:
	var input = Input.get_axis("left", "right")
	return input

func get_horizontal_direction_vector() -> Vector2:
	var input = get_horizontal_input()
	if input < 0:
		return Vector2.LEFT
	elif input > 0:
		return Vector2.RIGHT
	else:
		return Vector2.ZERO

func get_main_input_direction() -> Vector2:
	# top, right, down, left
	var strengths = {
		"right": Input.get_action_strength("right"),
		"left": Input.get_action_strength("left"),
		"up": Input.get_action_strength("up"),
		"down": Input.get_action_strength("down")
	}

	var max_strength = 0
	var max_direction = Vector2.ZERO
	for direction in strengths:
		if strengths[direction] > max_strength:
			max_strength = strengths[direction]
			if direction == "right":
				max_direction = Vector2.RIGHT
			elif direction == "left":
				max_direction = Vector2.LEFT
			elif direction == "up":
				max_direction = Vector2.UP
			elif direction == "down":
				max_direction = Vector2.DOWN
	
	return max_direction


func apply_gravity(delta):
	var gravity = get_gravity()
	velocity += gravity * delta


# ========================================
# STATES

func handle_state(delta):
	match state:
		State.IDLE:
			handle_state_idle(delta)
		State.RUN:
			handle_state_run(delta)
		State.JUMP:
			handle_state_jump(delta)
		State.FALL:
			handle_state_fall(delta)
		#State.DASH_DOWN:
			#handle_state_dash_down(delta)
		State.DASH_SIDE:
			handle_state_dash_side(delta)
		State.WALL_SLIDE:
			handle_state_wall_slide(delta)
		State.SLASH_AIR_SIDE:
			handle_state_slash_air_side(delta)
		State.SLASH_AIR_DOWN:
			handle_state_slash_air_down(delta)
		State.SLASH_AIR_UP:
			handle_state_slash_air_up(delta)
		State.SLASH_GROUND:
			handle_state_slash_ground_side(delta)
		State.SMASH:
			handle_state_smash(delta)
		State.GROUND_ATTACK_PREPARE:
			handle_state_ground_attack_prepare(delta)
		State.DEAD:
			handle_state_dead(delta)

func enter_state(next_state: State):
	var state_before = self.state
	self.state = next_state

	$StateLabel.text = get_state_label(next_state)

	match state:
		State.IDLE:
			enter_state_idle(state_before)
		State.RUN:
			enter_state_run(state_before)
		State.JUMP:
			enter_state_jump(state_before)
		State.FALL:
			enter_state_fall(state_before)
		#State.DASH_DOWN:
			#enter_state_dash_down(state_before)
		State.DASH_SIDE:
			enter_state_dash_side(state_before)
		State.WALL_SLIDE:
			enter_state_wall_slide(state_before)
		State.SLASH_AIR_SIDE:
			enter_state_slash_air_side(state_before)
		State.SLASH_AIR_DOWN:
			enter_state_slash_air_down(state_before)
		State.SLASH_AIR_UP:
			enter_state_slash_air_up(state_before)
		State.SLASH_GROUND:
			enter_state_slash_ground_side(state_before)
		State.GROUND_ATTACK_PREPARE:
			enter_state_ground_attack_prepare(state_before)
		State.SMASH:
			enter_state_smash(state_before)
		State.DEAD:
			enter_state_dead(state_before)
		_:
			print("Unknown state: ", state)
		


func process_timers(delta: float):
	wall_jump_timer = move_toward(wall_jump_timer, 0, delta);
	coyote_timer = move_toward(coyote_timer, 0, delta);
	slash_timer = move_toward(slash_timer, 0, delta);
	dash_timer = move_toward(dash_timer, 0, delta);
	jump_buffer_timer = move_toward(jump_buffer_timer, 0, delta);
	slash_cooldown_timer = move_toward(slash_cooldown_timer, 0, delta);


# ========================================
# ANIMATION

@onready var sprite = $AnimatedSprite2D;

func set_animation(animation_name: String):
	if sprite.animation == animation_name:
		return
	sprite.stop()
	sprite.play(animation_name)

func update_animation_side():
	if last_side.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

# ========================================
# DEBUG

func get_state_label(s: State):
	var keys = State.keys()
	for key in keys:
		if State[key] == s:
			return key


# ========================================
# HEALTH

func _on_health_died(_entity: Node) -> void:
	print("player died")
	velocity.x = 0;
	enter_state(State.DEAD)
	$HurtBox2D.queue_free()

func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, applied: int) -> void:
	Engine.time_scale = 0.25;
	hurt.emit(-applied);
	var tween = get_tree().create_tween();
	tween.tween_property(Engine, "time_scale", 1, 0.5);
	tween.set_ease(Tween.EASE_OUT);


# =====================================
# CAMERA

signal camera_add_limit(side: String, pos: int);
signal camera_remove_limit(side: String);

func add_camera_limit(side: String, pos: int):
	#print("camera add limit ", side, " ", pos);
	camera_add_limit.emit(side, pos);

func remove_camera_limit(side: String):
	camera_remove_limit.emit(side);


func is_player():
	return true;
