extends CharacterBody2D

@export var speed: float = 100;

@onready var raycast_right_top = $raycast_right_top;
@onready var raycast_left_top = $raycast_left_top;
@onready var raycast_right_bottom = $raycast_right_bottom;
@onready var raycast_left_bottom = $raycast_left_bottom;
@onready var raycast_up_right = $raycast_up_right;
@onready var raycast_up_left = $raycast_up_left;
@onready var raycast_down_right = $raycast_down_right;
@onready var raycast_down_left = $raycast_down_left;
@onready var dir_label = $dir_label;
@onready var hurt_timer = $hurt_timer;
@onready var ready_timer = $ready_timer;
@onready var animated_sprite = $AnimatedSprite2D;

enum DIR {
	UP,
	RIGHT,
	DOWN,
	LEFT
}
@export var dir: DIR = DIR.RIGHT;
@export var floor_side: DIR = DIR.DOWN;

var is_ready: bool = false;
var arrived_on_side: bool = false;

var hit_tween: Tween = null;

func _ready() -> void:
	change_direction(dir);

func _physics_process(_delta: float) -> void:
	if not is_ready:
		return;
	
	if not hurt_timer.is_stopped():
		return
		
	if dir == DIR.RIGHT:
		if floor_side == DIR.UP:
			if not arrived_on_side and raycast_up_left.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_up_left.is_colliding():
				change_direction(DIR.UP, DIR.LEFT);
				position.x = round(position.x / 64) * 64;
				return;
			if velocity.x == 0:
				change_direction(DIR.DOWN, DIR.RIGHT);
				return;
		elif floor_side == DIR.DOWN:
			if not arrived_on_side and raycast_down_left.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_down_left.is_colliding():
				change_direction(DIR.DOWN, DIR.LEFT);
				position.x = round(position.x / 64) * 64;
				return;
			if velocity.x == 0:
				change_direction(DIR.UP, DIR.RIGHT);
				return;
		velocity = Vector2(speed, 0);
	elif dir == DIR.LEFT:
		if floor_side == DIR.UP:
			if not arrived_on_side and raycast_up_right.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_up_right.is_colliding():
				change_direction(DIR.UP, DIR.RIGHT);
				position.x = round(position.x / 64) * 64;
				return;
			if velocity.x == 0:
				change_direction(DIR.DOWN, DIR.LEFT);
				return;
		elif floor_side == DIR.DOWN:
			if not arrived_on_side and raycast_down_right.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_down_right.is_colliding():
				change_direction(DIR.DOWN, DIR.RIGHT);
				position.x = round(position.x / 64) * 64;
				return;
			if velocity.x == 0:
				change_direction(DIR.UP, DIR.LEFT);
				return;
	elif dir == DIR.UP:
		if floor_side == DIR.LEFT:
			if not arrived_on_side and raycast_left_bottom.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_left_bottom.is_colliding():
				change_direction(DIR.LEFT, DIR.DOWN);
				position.y = round(position.y / 64) * 64;
				return;
			if velocity.y == 0:
				change_direction(DIR.RIGHT, DIR.UP);
				return;
		elif floor_side == DIR.RIGHT:
			if not arrived_on_side and raycast_right_bottom.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_right_bottom.is_colliding():
				change_direction(DIR.RIGHT, DIR.DOWN);
				position.y = round(position.y / 64) * 64;
				return;
			if velocity.y == 0:
				change_direction(DIR.LEFT, DIR.UP);
				return;
	elif dir == DIR.DOWN:
		if floor_side == DIR.LEFT:
			if not arrived_on_side and raycast_left_top.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_left_top.is_colliding():
				change_direction(DIR.LEFT, DIR.UP);
				position.y = round(position.y / 64) * 64;
				return;
			if velocity.y == 0:
				change_direction(DIR.RIGHT, DIR.DOWN);
				return;
		elif floor_side == DIR.RIGHT:
			if not arrived_on_side and raycast_right_top.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_right_top.is_colliding():
				change_direction(DIR.RIGHT, DIR.UP);
				position.y = round(position.y / 64) * 64;
				return;
			if velocity.y == 0:
				change_direction(DIR.LEFT, DIR.DOWN);
				return;
	move_and_slide()


func change_direction(new_dir: DIR, new_floor_side: DIR = floor_side) -> void:
	#var old_dir = dir;
	arrived_on_side = false;
	dir = new_dir;
	dir_label.text = DIR.keys()[new_dir];

	if dir == DIR.LEFT:
		velocity = Vector2(-speed, 0);
	elif dir == DIR.RIGHT:
		velocity = Vector2(speed, 0);
	if dir == DIR.UP:
		velocity = Vector2(0, -speed);
	if dir == DIR.DOWN:
		velocity = Vector2(0, speed);
	
	set_floor_side(new_floor_side);

func set_floor_side(new_floor_side: DIR) -> void:
	floor_side = new_floor_side;
	if floor_side == DIR.LEFT:
		animated_sprite.rotation_degrees = 90;
	if floor_side == DIR.RIGHT:
		animated_sprite.rotation_degrees = 270;
	if floor_side == DIR.UP:
		animated_sprite.rotation_degrees = 180;
	if floor_side == DIR.DOWN:
		animated_sprite.rotation_degrees = 0;

func _on_ready_timer_timeout() -> void:
	print("ready_timer timeout");
	awaken();

func awaken():
	is_ready = true;
	animated_sprite.material.set_shader_parameter("flash_value", 0.0);
	animated_sprite.play();
	change_direction(dir);
	process_mode = Node.PROCESS_MODE_INHERIT;
	print("awaken crawler");

func sleep():
	process_mode = Node.PROCESS_MODE_DISABLED;

func start_timers():
	ready_timer.start();

func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, _applied: int) -> void:
	hurt_timer.start(0.125);
	animated_sprite.material.set_shader_parameter("flash_value", 1.0);
	print("damaged crawler");
	if hit_tween and hit_tween.is_running():
		hit_tween.stop();
	hit_tween = get_tree().create_tween();
	hit_tween.tween_property(animated_sprite, "material:shader_parameter/flash_value", 0.0, 0.5);

func _on_health_died(_entity: Node) -> void:
	if hit_tween and hit_tween.is_running():
		hit_tween.stop();
	animated_sprite.material.set_shader_parameter("flash_value", 0.0);
	queue_free()
