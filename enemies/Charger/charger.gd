extends CharacterBody2D

@onready var raycast = $RayCast2D;
@onready var animated_sprite = $AnimatedSprite2D;
@onready var direction_timer = $DirectionTimer;
@onready var state_label = $state_label;

@onready var step_detector_right = $step_detector_right;
@onready var step_detector_left = $step_detector_left;

@onready var hitbox_left = $hitbox_left;
@onready var hitbox_right = $hitbox_right;
@onready var hitbox_right_collisions = $hitbox_right/CollisionShape2D;
@onready var hitbox_left_collisions = $hitbox_left/CollisionShape2D;
@onready var attack_area_right = $attack_area_right;
@onready var attack_area_left = $attack_area_left;
@onready var attack_timer = $attack_timer;

@export var run_speed = 500;

var player: Jumper;

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
}
var state: State = State.IDLE;

enum DIR {
	LEFT,
	RIGHT
}

var dir: DIR = DIR.LEFT;
var chase_direction: DIR = DIR.RIGHT;

var attacked: bool = false;

func _ready() -> void:
	enter_state(State.IDLE);

func _process(_delta: float) -> void:
	match state:
		State.IDLE:
			if player_in_sight():
				enter_state(State.CHASE);
		State.CHASE:
			move_and_slide()
			if velocity.x == 0:
				enter_state(State.IDLE);
			if velocity.x < 0:
				if attack_area_left.has_overlapping_areas():
					enter_state(State.ATTACK);
				if not step_detector_left.is_colliding():
					enter_state(State.IDLE);
			if velocity.x > 0:
				if attack_area_right.has_overlapping_areas():
					enter_state(State.ATTACK);
				if not step_detector_right.is_colliding():
					enter_state(State.IDLE);
		State.ATTACK:
			if attack_timer.time_left < 0.25:
				attack();
			if attack_timer.is_stopped():
				enter_state(State.IDLE);
			#if animated_sprite.frame == 5:
				#attack();
			#if not animated_sprite.is_playing():
				#enter_state(State.IDLE);
		State.HURT:
			if not animated_sprite.is_playing():
				enter_state(State.IDLE);


func enter_state(new_state: State):
	leave_state(state);
	
	match state:
		State.CHASE:
			player = find_player();
			if player:
				if player.global_position.x < global_position.x:
					chase_direction = DIR.LEFT;
					set_direction(DIR.LEFT);
				else:
					chase_direction = DIR.RIGHT;
					set_direction(DIR.RIGHT);
			else:
				print("no player!");
			if chase_direction == DIR.LEFT:
				velocity.x = -run_speed;
			else:
				velocity.x = run_speed;
		State.ATTACK:
			velocity.x = 0;
			attack_timer.start()
		
		
	state_label.text = State.keys()[new_state];
	state = new_state;


func leave_state(old_state: State):
	match old_state:
		State.CHASE:
			velocity.x = 0;
		State.ATTACK:
			attacked = false;


func attack():
	if attacked:
		return;
	attacked = true;
	if dir == DIR.RIGHT:
		hitbox_right_collisions.disabled = false;
		hitbox_right.show();
		await get_tree().physics_frame
		await get_tree().physics_frame
		hitbox_right_collisions.disabled = true;
		hitbox_right.hide();
	else:
		hitbox_left_collisions.disabled = false;
		hitbox_left.show();
		await get_tree().physics_frame
		await get_tree().physics_frame
		hitbox_left_collisions.disabled = true;
		hitbox_left.hide();


func find_player():
	var players = get_tree().get_nodes_in_group("player");
	if players.size() == 0:
		return null;
	return players[0];


func set_direction(new_dir: DIR):
	dir = new_dir;
	if dir == DIR.RIGHT:
		raycast.target_position = Vector2(500, 0);
		animated_sprite.flip_h = false;
	else:
		raycast.target_position = Vector2(-500, 0);
		animated_sprite.flip_h = true;


func player_in_sight():
	return raycast.is_colliding()


func _on_direction_timer_timeout() -> void:
	if state == State.IDLE:
		if dir == DIR.RIGHT:
			set_direction(DIR.LEFT);
		else:
			set_direction(DIR.RIGHT);
	direction_timer.wait_time = randi_range(4, 15);


func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, _applied: int) -> void:
	enter_state(State.HURT);
