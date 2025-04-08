extends Area2D

var velocity = Vector2.ZERO;
var SPEED = 450;

var player: Node2D = null;

var tut_visible = false;
@onready var tutorial = $CanvasLayer/tutorial;
var tutorial_image: Sprite2D; 

func _ready() -> void:
	$snd_orb.play();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tut_visible:
		if Input.is_action_just_pressed("jump"):
			tutorial.hide();
			tutorial_image.hide();
			tut_visible = false;
			get_tree().paused = false
			remove();
		return
	
	if player == null:
		return
	
	var player_pos = player.global_position + Vector2(0, -50);
	var direction = (player_pos - global_position).normalized();
	var adder = direction * 15;
	
	velocity += adder;
	velocity = velocity.limit_length(SPEED);
	
	position += velocity * delta;

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body;

func remove():
	queue_free();

func _on_body_entered(_body: Node2D) -> void:
	if not player.attack_upgraded:
		player.attack_upgraded = true;
		show_tutorial("smash");
		return;
	
	if not player.can_dash:
		player.can_dash = true;
		show_tutorial("dash");
		return;
	
	if player.MID_AIR_JUMPS < 1:
		player.MID_AIR_JUMPS += 1;
		show_tutorial("jump");
		return;
	
	print("NO");
	remove();

func show_tutorial(type: String):
	var tut = $CanvasLayer/tutorial;
	tut.show();
	$snd_collect.play();
	tutorial_image = tut.get_node(type);
	tutorial_image.show();
	tut_visible = true;
	get_tree().paused = true
