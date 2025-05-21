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
			get_tree().paused = false;
			var time_tween = get_tree().create_tween();
			time_tween.tween_property(Engine, "time_scale", 1.0, 1);
			time_tween.set_ignore_time_scale(true);
			time_tween.set_ease(Tween.EASE_IN);
			remove();
		return
	
	if player == null:
		return
	
	rotation += delta;
	
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
	var time_tween = get_tree().create_tween();
	time_tween.set_ignore_time_scale(true);
	time_tween.tween_property(Engine, "time_scale", 0.1, 0.125);
	time_tween.tween_property($image, "modulate", Color.TRANSPARENT, 0.125);
	time_tween.tween_property($image, "scale", Vector2.ZERO, 0.125);
	await time_tween.finished;
	get_tree().paused = true;
	await get_tree().create_timer(0.025).timeout;
	var tut = $CanvasLayer/tutorial;
	tut.show();
	$snd_collect.play();
	tutorial_image = tut.get_node(type);
	tutorial_image.modulate = Color.TRANSPARENT;
	tutorial_image.show();
	var tween = get_tree().create_tween();
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);
	tween.set_ignore_time_scale(true);
	tween.tween_property(tutorial_image, "modulate", Color.WHITE, 0.5);
	tutorial_image.show();
	await tween.finished;
	tut_visible = true;
