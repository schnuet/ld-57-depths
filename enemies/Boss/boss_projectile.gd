extends CharacterBody2D

@onready var hitbox_collider = $BasicHitBox2D/CollisionShape2D;
@onready var animated_sprite = $AnimatedSprite2D;

var floating = true;
var moving_around_center = false;
var center: Node2D;

var turnaround_progress = 0;
var turnaround_circle_offset = 0;
const DISTANCE_TO_CENTER = 200;

func enable_hitbox():
	hitbox_collider.disabled = false;

func disable_hitbox():
	hitbox_collider.disabled = true;

func _physics_process(delta: float) -> void:
	if moving_around_center:
		animated_sprite.animation = "static";
		
		turnaround_circle_offset = (turnaround_circle_offset + 1) % 360;
		var angle = deg_to_rad(turnaround_circle_offset);
		var x = center.global_position.x + cos(angle) * DISTANCE_TO_CENTER;
		var y = center.global_position.y + sin(angle) * DISTANCE_TO_CENTER;
		var wanted_position = Vector2(x, y);
		velocity = (wanted_position - global_position);
		position += velocity / 2;
		return;
	
	
	if floating:
		animated_sprite.animation = "static";
		return;
	
	animated_sprite.animation = "flying";
	
	velocity = Vector2(0, randi_range(500, 600)) * delta;
	
	var collision = move_and_collide(velocity);
	if collision != null:
		floating = true;
