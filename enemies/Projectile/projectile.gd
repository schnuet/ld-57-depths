extends Node2D

var velocity: Vector2 = Vector2.ZERO;
@onready var animated_sprite = $AnimatedSprite2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite.play();


func _physics_process(delta: float) -> void:
	position += velocity * delta;
	
	animated_sprite.look_at(global_position + velocity);
	animated_sprite.rotation_degrees -= 180;


func _on_basic_hit_box_2d_action_applied(_hurt_box: HurtBox2D) -> void:
	queue_free();


func _on_wall_collider_body_entered(_body: Node2D) -> void:
	queue_free();
