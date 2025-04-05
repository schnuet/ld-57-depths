extends Node2D

var Projectile = preload("res://enemies/Projectile/Projectile.tscn");
@onready var health_bar = $HealthBar;

var shots_available = 0;
@onready var shoot_timer = $Timer;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	if shots_available > 0:
		shots_available -= 1;
		shoot();
	
	if shots_available <= 0:
		$Timer.stop()

func shoot():
	var projectile = Projectile.instantiate();
	projectile.velocity.x = -400;
	projectile.global_position = global_position - Vector2(0, 64);
	get_parent().add_child(projectile);


func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, applied: int) -> void:
	health_bar.value -= applied;


func _on_health_died(_entity: Node) -> void:
	queue_free()


func _on_cooldown_timer_timeout() -> void:
	shots_available = 3;
	shoot_timer.start()
