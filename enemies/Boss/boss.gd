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
	var tween = get_tree().create_tween()
	animated_sprite.material.set_shader_parameter("flash_value", 1.0);
	tween.tween_property(animated_sprite, "material:shader_parameter/flash_value", 0.0, 0.5);
	emit_signal("was_hit");


func _on_health_died(_entity: Node) -> void:
	var tween = get_tree().create_tween()
	animated_sprite.material.set_shader_parameter("flash_value", 1.0);
	tween.tween_property(animated_sprite, "material:shader_parameter/flash_value", 0.0, 0.5);
	await tween.finished;
	animated_sprite.play("death");
	await animated_sprite.animation_finished;
	queue_free();
