extends Node2D

var velocity: Vector2 = Vector2.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	position += velocity * delta;


func _on_basic_hit_box_2d_action_applied(_hurt_box: HurtBox2D) -> void:
	queue_free();
