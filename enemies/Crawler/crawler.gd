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

func _ready() -> void:
	change_direction(dir);

func _physics_process(delta: float) -> void:
	if not is_ready:
		return;
		
	if dir == DIR.RIGHT:
		if floor_side == DIR.UP:
			if not arrived_on_side and raycast_up_left.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_up_left.is_colliding():
				change_direction(DIR.UP);
				floor_side = DIR.LEFT;
				position.x = round(position.x / 64) * 64 + 1;
				return;
		elif floor_side == DIR.DOWN:
			if not arrived_on_side and raycast_down_left.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_down_left.is_colliding():
				change_direction(DIR.DOWN);
				floor_side = DIR.LEFT;
				position.x = round(position.x / 64) * 64 + 1;
				print("pos", position.x);
				return;
		velocity = Vector2(speed, 0);
	elif dir == DIR.LEFT:
		if floor_side == DIR.UP:
			if not arrived_on_side and raycast_up_right.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_up_right.is_colliding():
				change_direction(DIR.UP);
				floor_side = DIR.RIGHT;
				position.x = round(position.x / 64) * 64 - 1;
				return;
		elif floor_side == DIR.DOWN:
			if not arrived_on_side and raycast_down_right.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_down_right.is_colliding():
				change_direction(DIR.DOWN);
				floor_side = DIR.RIGHT;
				position.x = round(position.x / 64) * 64 - 1;
				return;
		velocity = Vector2(-speed, 0);
	elif dir == DIR.UP:
		if floor_side == DIR.LEFT:
			if not arrived_on_side and raycast_left_bottom.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_left_bottom.is_colliding():
				change_direction(DIR.LEFT);
				floor_side = DIR.DOWN;
				position.y = round(position.y / 64) * 64 - 1;
				return;
		elif floor_side == DIR.RIGHT:
			if not arrived_on_side and raycast_right_bottom.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_right_bottom.is_colliding():
				change_direction(DIR.RIGHT);
				floor_side = DIR.DOWN;
				position.y = round(position.y / 64) * 64 - 1;
				return;
		velocity = Vector2(0, -speed);
	elif dir == DIR.DOWN:
		velocity = Vector2(0, speed);
		if floor_side == DIR.LEFT:
			if not arrived_on_side and raycast_left_top.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_left_top.is_colliding():
				change_direction(DIR.LEFT);
				floor_side = DIR.UP;
				position.y = round(position.y / 64) * 64 + 1;
				return;
		elif floor_side == DIR.RIGHT:
			if not arrived_on_side and raycast_right_top.is_colliding():
				arrived_on_side = true;
			if arrived_on_side and not raycast_right_top.is_colliding():
				change_direction(DIR.RIGHT);
				floor_side = DIR.UP;
				position.y = round(position.y / 64) * 64 + 1;
				return;
	move_and_slide()


func change_direction(new_dir: DIR):
	var old_dir = dir;
	arrived_on_side = false;
	dir = new_dir;
	dir_label.text = DIR.keys()[new_dir];


func _on_ready_timer_timeout() -> void:
	is_ready = true;


func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, _applied: int) -> void:
	pass # Replace with function body.


func _on_health_died(entity: Node) -> void:
	queue_free()
