extends Camera2D

@export var following: Jumper:
	set(value):
		following = value;
		connect_following(value);

@onready var target_position: Vector2 = Vector2.ZERO;
@onready var char_movement_zone: Rect2 = Rect2(0, 0, 0, 0);
@onready var shaker = $Shaker;

var last_side = Vector2.ZERO;

var limits = {
	"left": -1000000000,
	"right": 10000000000,
	"bottom": 1000000000,
	"top": -1000000000
};


func _process(delta: float) -> void:
	update_target_position(delta);
	
	#position.y = target_position.y;
#
	#var distance = target_position.x - position.x;
	#distance = min(abs(distance), 150) * sign(distance);
	#position.x += distance * (delta * 5)

	var limited_position = get_limited_position(target_position);
	var distance = limited_position - position;
	position += distance * (delta * 5);


func connect_following(body: Jumper):
	body.connect("hurt", _on_following_hurt);
	body.connect("camera_add_limit", _on_following_add_camera_limit);
	body.connect("camera_remove_limit", _on_following_remove_camera_limit);
	print("camera now following ", body);

func update_target_position(_delta: float) -> void:
	if following == null:
		target_position = position;
		return;

	var pos = following.global_position;

	if following.velocity.x > 0:
		last_side = Vector2.RIGHT;
	elif following.velocity.x < 0:
		last_side = Vector2.LEFT;

	if last_side.x > 0:
		pos.x += 100;
	elif last_side.x < 0:
		pos.x -= 100;
	
	target_position = pos;


# ===================================================
# SHAKE

func _on_following_hurt(_amount: int):
	shake_short()

func shake_short():
	print("shake");
	shaker.play_shake()


# ====================================================
# LIMITS

func get_limited_position(pos: Vector2):
	var limited = pos;
	var half_width = 960;
	var half_height = 540;
	if pos.x < limits.get("left") + half_width:
		limited.x = limits.get("left") + half_width;
	if pos.y < limits.get("top") + half_height:
		limited.y = limits.get("top") + half_height;
	if pos.x > limits.get("right") - half_width:
		limited.x = limits.get("right") - half_width;
	if pos.y > limits.get("bottom") - half_height:
		limited.y = limits.get("bottom") - half_height;
	
	return limited;

func _on_following_add_camera_limit(side: String, pos: int):
	print("set limit ", side, " to ", pos);
	limits.set(side, pos);
	
func _on_following_remove_camera_limit(side: String):
	if side == "left":
		limits.set(side, -100000000000);
	if side == "right":
		limits.set(side, 100000000000);
	if side == "top":
		limits.set(side, -100000000000);
	if side == "bottom":
		limits.set(side, 100000000000);
