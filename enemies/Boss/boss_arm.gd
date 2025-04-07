extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D;
@onready var cooldown_timer = $cooldown_timer;

var risen = false;
var target_x: float = 0;
var moving = false;

var MAX_SPEED = 400;

enum Half {
	LEFT,
	RIGHT
}
var side: Half = Half.LEFT;

func _ready() -> void:
	rise();

func _physics_process(delta: float) -> void:
	if not risen:
		return;
	
	if moving:
		var distance = get_remaining_distance();
		if abs(distance) < 5:
			moving = false;
			remove();
			return;
		
		var EASE_FACTOR = abs(distance);
		
		if distance < 0:
			velocity.x = max(distance * EASE_FACTOR, -MAX_SPEED);
		else:
			velocity.x = min(distance * EASE_FACTOR, MAX_SPEED);
			
		move_and_slide()
		return;


func start_moving():
	moving = true;


func get_remaining_distance():
	return target_x - global_position.x;

func remove():
	animated_sprite.play("lower");
	await animated_sprite.animation_finished;
	queue_free();

func _on_health_died(_entity: Node) -> void:
	$BasicHitBox2D/CollisionShape2D.set_deferred("disabled", true);
	$BasicHurtBox2D/CollisionShape2D.set_deferred("disabled", true);
	animated_sprite.play("lower");
	await animated_sprite.animation_finished;
	queue_free()

func rise():
	await get_tree().physics_frame;
	
	animated_sprite.stop();
	animated_sprite.play("rise");
	
	if global_position.x > 960:
		side = Half.RIGHT;
		target_x = 160;
		animated_sprite.flip_h = true;
	else:
		side = Half.LEFT;
		target_x = 1760;
		animated_sprite.flip_h = false;
	
	await animated_sprite.animation_finished;
	
	risen = true;
	$BasicHitBox2D/CollisionShape2D.disabled = false;
	animated_sprite.play("wiggle");
	
	start_moving();
