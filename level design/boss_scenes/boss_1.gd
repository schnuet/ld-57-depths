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
	FLOATING_PROJECTILES,
	THROWING_PROJECTILES
}

var in_stage: bool = false;

# FLOOR: 896px
const FLOOR_Y = 896;

var active_projectiles = [];
var floating_projectiles = [];

var needed_hits = 3;


func _ready() -> void:
	boss.position = Vector2(930, 560);
	player.enabled = false;
	await growl();
	await wait(0.5);
	
	enter_stage(Stage.TENTACLES);


func enter_stage(new_stage: Stage):
	if new_stage == Stage.TENTACLES:
		var move_tween = get_tree().create_tween();
		move_tween.tween_property(boss, "position", Vector2(960, 256), 0.3);
		await move_tween.finished;
		player.enabled = true;
		
		shake_rumble.play_shake();
		await shake_rumble.shake_finished;
		await wait(0.25);
		
		if randi_range(1, 2) == 1:
			add_arm(1600);
			await wait(1.5);
			add_arm(1600);
			await wait(1.5);
			add_arm(1600);
		else:
			add_arm(200);
			await wait(1.5);
			add_arm(200);
			await wait(1.5);
			add_arm(200);
		
		await wait(2);
		
		enter_stage(Stage.VULNERABLE);
	
	if new_stage == Stage.THROWING_PROJECTILES:
		var move_tween = get_tree().create_tween();
		if randi_range(1, 2) == 1:
			move_tween.tween_property(boss, "position", Vector2(1500, 256), 0.4);
		else:
			move_tween.tween_property(boss, "position", Vector2(384, 320), 0.4);
		await move_tween.finished;
		
		var throws = 3;
		
		while throws > 0:
			if floating_projectiles.size() == 0:
				break;
			
			var projectile = floating_projectiles[randi() % floating_projectiles.size()];
			floating_projectiles.erase(projectile);
			projectile.floating = true;
			projectile.moving_around_center = false;
			
			var tween = get_tree().create_tween();
			tween.tween_property(projectile, "global_position", boss.global_position, 0.2);
			await tween.finished;
			
			var dir = (player.global_position - Vector2(0, 140) - boss.global_position).normalized();
			projectile.thrown = true;
			projectile.velocity = dir * 800;
			projectile.velocity.limit_length(800);
			projectile.floating = false;
			
			
			throws -= 1;
			await wait(0.75);
		
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
		move_tween.tween_property(boss, "position", Vector2(960, 256), 0.5);
		await move_tween.finished;
		player.enabled = true;
		
		shake_rumble.play_shake();

		var non_floating_projectiles = get_non_floating_projectiles();
		var missing_floating_rocks = 8 - floating_projectiles.size();
		
		while missing_floating_rocks > 0:
			if non_floating_projectiles.size() == 0:
				break;
			
			missing_floating_rocks -= 1;
			
			# get a random projectile from the non floating projectiles
			var random_index = randi_range(0, non_floating_projectiles.size() - 1);
			var random_projectile = non_floating_projectiles[random_index];

			floating_projectiles.append(random_projectile);
			non_floating_projectiles.erase(random_projectile);
			active_projectiles.erase(random_projectile);
	
		
		var section_degrees = 30; # 360 / 12;
		var offset = randi_range(0, 360);
		
		var index = 0;
		var boss_position = boss.global_position;
		for projectile in floating_projectiles:
			projectile.floating = true;
			var tween = get_tree().create_tween();
			
			var projectile_pos: Vector2;

			var distance = 200;
			
			var angle = (section_degrees * index + offset) % 360;

			var angle_radians: float = deg_to_rad(angle);
			
			var adjacent: float = distance * cos(angle_radians)
			var opposite: float = distance * sin(angle_radians)

			# position the projectile on the circle
			projectile_pos.x = boss_position.x + adjacent;
			projectile_pos.y = boss_position.y + opposite;
			tween.tween_property(projectile, "global_position", projectile_pos, 1);
			
			projectile.turnaround_circle_offset = angle;
			
			projectile.center = boss;
			index += 1;
			tween.connect("finished", make_turning.bind(projectile));
		
		await wait(3);
		
		enter_stage(Stage.THROWING_PROJECTILES);
	
	
	if new_stage == Stage.VULNERABLE:
		var move_tween = get_tree().create_tween();
		if randi_range(1, 2) == 1:
			move_tween.tween_property(boss, "position", Vector2(1200, 560), 1);
		else:
			move_tween.tween_property(boss, "position", Vector2(720, 560), 1);
		
		await move_tween.finished;
		
		needed_hits = 3;
		
		wait(10);
		await boss_hit_or_time_expired;

		var next_state = get_random_next_state();
		enter_stage(next_state);


func growl():
	shake_rumble.play_shake();
	await shake_rumble.shake_finished;
	await wait(0.25);

func get_non_floating_projectiles():
	var non_floating_projectiles = [];
	for projectile in active_projectiles:
		if not floating_projectiles.has(projectile):
			non_floating_projectiles.append(projectile);
	return non_floating_projectiles;


func make_turning(projectile: Node2D):
	projectile.moving_around_center = true;


func is_stage_done():
	return false;
	

func get_random_next_state():
	var possible_states = [
		Stage.TENTACLES
	];
	
	if active_projectiles.size() <= 2 and floating_projectiles.size() <= 4:
		possible_states.append(Stage.FALLING_PROJECTILES);

	if floating_projectiles.size() <= 4 and active_projectiles.size() > 0:
		possible_states.append(Stage.FLOATING_PROJECTILES);
	
	if floating_projectiles.size() > 0:
		possible_states.append(Stage.THROWING_PROJECTILES);
	
	return possible_states[randi_range(0, possible_states.size() - 1)];


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
	shake_rumble.play_shake();
	needed_hits -= 1;
	print("NEEDED HITS ", needed_hits);
	if needed_hits <= 0:
		boss_hit_or_time_expired.emit()
