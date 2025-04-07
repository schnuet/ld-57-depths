extends Node2D

var Tentacle = preload("res://enemies/Boss/BossArm.tscn");

@onready var boss = $Boss;
@onready var player = $Jumper;
@onready var shake_rumble = $Camera2D/shake_rumble;

signal all_tentacles_defeated;
signal tentacle_defeated;
signal boss_hit_or_time_expired;
signal wait_expired;

enum Stage {
	TENTACLES,
	VULNERABLE,
	FALLING_PROJECTILES,
	FLOATING_PROJECTILES
}

var in_stage: bool = false;

# FLOOR: 896px
const FLOOR_Y = 896;

var active_projectiles = [];
var floating_projectiles = [];


func _ready() -> void:
	player.enabled = false;
	enter_stage(Stage.FALLING_PROJECTILES);
	boss.position = Vector2(930, 560);


func enter_stage(new_stage: Stage):
	if new_stage == Stage.TENTACLES:
		in_stage = true;
		
		await wait(1);
		
		shake_rumble.play_shake();
		await shake_rumble.shake_finished;
		await wait(0.25);
		
		var move_tween = get_tree().create_tween();
		move_tween.tween_property(boss, "position", Vector2(960, 256), 0.3);
		await move_tween.finished;
		player.enabled = true;

		add_arm(1600);
		await wait(1.5);
		add_arm(1600);
		await wait(1.5);
		add_arm(1600);
		await wait(5);
		add_arm(200);
		await wait(1.5);
		add_arm(200);
		await wait(1.5);
		add_arm(200);
		await wait(5);
		
		enter_stage(Stage.VULNERABLE);
	
	if new_stage == Stage.FALLING_PROJECTILES:
		var move_tween = get_tree().create_tween();
		move_tween.tween_property(boss, "position", Vector2(960, 256), 0.3);
		await move_tween.finished;
		player.enabled = true;
		
		print("STAGE FALLING PROJECTILES");
		shake_rumble.play_shake();
		await shake_rumble.shake_finished;
		await wait(0.25);
		
		var variant = randi_range(1, 2);
		var group: Node2D;
		if variant == 1:
			group = $projectiles_a.duplicate();
		if variant == 2:
			group = $projectiles_b.duplicate();
			
		for projectile in group.get_children():
			active_projectiles.append(projectile);
			projectile.floating = false;
			group.remove_child(projectile);
			add_child(projectile);
		
		group.queue_free();
	
		await wait(3);
		
		enter_stage(Stage.FLOATING_PROJECTILES);
	
	if new_stage == Stage.FLOATING_PROJECTILES:
		print("enter stage floating projectiles");
		
		var move_tween = get_tree().create_tween();
		move_tween.tween_property(boss, "position", Vector2(960, 256), 0.3);
		await move_tween.finished;
		player.enabled = true;
		
		shake_rumble.play_shake();
		shake_rumble.shake_finished;
		
		var missing_floating_rocks = 8 - floating_projectiles.size();
		
		for projectile in active_projectiles:
			if not floating_projectiles.has(projectile):
				floating_projectiles.append(projectile);
		
		#active_projectiles.clear();
		
		var amount = floating_projectiles.size();
		var section_degrees = 360 / (amount + 4);
		var offset = randi_range(0, 360);
		
		var index = 0;
		var boss_position = boss.global_position;
		for projectile in floating_projectiles:
			projectile.floating = true;
			var tween = get_tree().create_tween();
			
			var projectile_pos: Vector2;

			var distance = 200;

			var angle_radians: float = deg_to_rad(section_degrees * index + offset);
			
			var adjacent: float = distance * cos(angle_radians)
			var opposite: float = distance * sin(angle_radians)

			# position the projectile on the circle
			projectile_pos.x = boss_position.x + adjacent;
			projectile_pos.y = boss_position.y + opposite;
			tween.tween_property(projectile, "global_position", projectile_pos, 1);
			
			projectile.turnaround_circle_offset = section_degrees * index;
			
			projectile.center = boss;
			index += 1;
			tween.connect("finished", make_turning.bind(projectile));
		
		await wait(3);
		
		enter_stage(Stage.VULNERABLE);
	
	if new_stage == Stage.VULNERABLE:
		var move_tween = get_tree().create_tween();
		move_tween.tween_property(boss, "position", Vector2(960, 550), 0.3);
		await move_tween.finished;
		
		await boss_hit_or_time_expired;

		var next_state = get_random_next_state();
		enter_stage(next_state);


func take_random_active_projectile():
	var non_floating_projectiles = [];

func make_turning(projectile: Node2D):
	projectile.moving_around_center = true;


func is_stage_done():
	return false;
	

func get_random_next_state():
	var next_state = randi_range(1, 2);
	
	if next_state == 1:
		return Stage.FALLING_PROJECTILES;
		
	return Stage.TENTACLES;


# TENTACLES

func add_arm(x: int):
	# min: 200
	# max: 1500
	var tentacle = Tentacle.instantiate();
	add_child(tentacle);
	tentacle.position = Vector2(x, FLOOR_Y);
	tentacle_defeated.emit()

# HELPERS

func wait(seconds: float):
	get_tree().create_timer(seconds).connect("timeout", _on_wait_timeout);
	return wait_expired

func _on_wait_timeout():
	boss_hit_or_time_expired.emit();
	wait_expired.emit();

func _on_boss_was_hit() -> void:
	boss_hit_or_time_expired.emit()
