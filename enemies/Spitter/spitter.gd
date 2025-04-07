extends Node2D

var shots_available = 0;

var Projectile = preload("res://enemies/Projectile/Projectile.tscn");
@onready var health_bar = $HealthBar;
@onready var animated_sprite = $AnimatedSprite2D;

@onready var cooldown_timer = $cooldown_timer;
@onready var attack_timer = $attack_timer;

enum SIDE {
	TOP,
	LEFT,
	RIGHT,
	BOTTOM
}

@export var base_side: SIDE = SIDE.TOP;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#start_timers();
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func shoot():
	var player = find_player();
	if player:
		var projectile = Projectile.instantiate();
		var origin = get_projectile_origin();
		var direction = ((player.global_position + player.velocity * 0.25 + Vector2(0, -50)) - origin).normalized()
		projectile.velocity = direction * 500;
		get_parent().add_child(projectile);
		projectile.global_position = origin;
		animated_sprite.play("default");
	else:
		print("no player!");


func find_player() -> Jumper:
	var players = get_tree().get_nodes_in_group("player");
	if players.size() == 0:
		return null;
	return players[0];


func get_projectile_origin():
	return global_position + get_side_offset();


func get_side_offset() -> Vector2:
	if base_side == SIDE.TOP:
		return Vector2(0, 64);
	if base_side == SIDE.BOTTOM:
		return Vector2(0, -64);
	if base_side == SIDE.LEFT:
		return Vector2(64, 0);
	if base_side == SIDE.RIGHT:
		return Vector2(-64, 0);
	return Vector2.ZERO;

func _on_health_died(_entity: Node) -> void:
	queue_free()


func _on_cooldown_timer_timeout() -> void:
	shots_available = 2;
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if shots_available > 0:
		shots_available -= 1;
		shoot();
	
	if shots_available <= 0:
		attack_timer.stop()


func _on_health_damaged(_entity: Node, _type: HealthActionType.Enum, _amount: int, _incrementer: int, _multiplier: float, _applied: int) -> void:
	pass # Replace with function body.

func start_timers():
	cooldown_timer.start(5);

func awaken():
	start_timers();
	if base_side == SIDE.RIGHT:
		animated_sprite.rotation_degrees = 0;
	elif base_side == SIDE.LEFT:
		animated_sprite.rotation_degrees = 180;
	elif base_side == SIDE.BOTTOM:
		animated_sprite.rotation_degrees = 90;
	elif base_side == SIDE.TOP:
		animated_sprite.rotation_degrees = 270;
