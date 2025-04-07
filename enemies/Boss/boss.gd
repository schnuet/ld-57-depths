extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D;
@onready var hurtbox_collision = $BasicHurtBox2D/CollisionShape2D;

signal was_hit;

func _ready() -> void:
	animated_sprite.play();

func enable_hurtbox():
	hurtbox_collision.disabled = false;

func disable_hurtbox():
	hurtbox_collision.disabled = true;


func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, _applied: int) -> void:
	emit_signal("was_hit");
