extends CharacterBody2D

@onready var raycast = $RayCast2D;
@onready var animated_sprite = $AnimatedSprite2D;
@onready var direction_timer = $DirectionTimer;
@onready var hitbox_left = $hitbox_left;
@onready var hitbox_right = $hitbox_right;
@onready var state_label = $state_label;

@export var run_speed = 400;

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
			if is_on_wall():
				enter_state(State.IDLE);
			move_and_slide()
		State.ATTACK:
			if animated_sprite.frame == 5:
				attack();
			if not animated_sprite.is_playing():
				enter_state(State.IDLE);
		State.HURT:
			if not animated_sprite.is_playing():
				enter_state(State.IDLE);


func enter_state(new_state: State):
	leave_state(state);
	
	match state:
		State.CHASE:
			player = find_player();
			if player.global_position.x < global_position.x:
				chase_direction = DIR.LEFT;
				set_direction(DIR.LEFT);
				velocity.x = -run_speed;
			else:
				chase_direction = DIR.RIGHT;
				set_direction(DIR.RIGHT);
				velocity.x = run_speed;
		State.ATTACK:
			velocity.x = 0;
			pass
		
		
	state_label.text = State.keys()[new_state];
	state = new_state;


func leave_state(new_state: State):
	match new_state:
		State.ATTACK:
			attacked = false;


func attack():
	if attacked:
		return;
	attacked = true;
	if dir == DIR.RIGHT:
		hitbox_right.ignore_collisions = false;
		await get_tree().physics_frame
		hitbox_right.ignore_collisions = true;
	else:
		hitbox_left.ignore_collisions = false;
		await get_tree().physics_frame
		hitbox_left.ignore_collisions = true;


func find_player():
	get_tree().get_nodes_in_group("player");


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
