extends CharacterBody2D

@onready var raycast = $RayCast2D;
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

func _process(delta: float) -> void:
	match state:
		State.IDLE:
			pass
		State.CHASE:
			pass
		State.ATTACK:
			pass
		State.HURT:
			pass

func enter_state(new_state: State):
	state = new_state;

func find_player():
	get_tree().get_nodes_in_group("player");

func set_direction(new_dir: DIR):
	dir = new_dir;
	if dir == DIR.RIGHT:
		raycast.target_position = Vector2(500, 0);
	else:
		raycast.target_position = Vector2(-500, 0);
