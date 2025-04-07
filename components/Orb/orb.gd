extends Area2D

var velocity = Vector2.ZERO;
var SPEED = 450;

var player: Node2D = null;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player == null:
		return
	
	var player_pos = player.global_position + Vector2(0, -50);
	var direction = (player_pos - global_position).normalized();
	var adder = direction * 50;
	
	velocity += adder;
	velocity = velocity.limit_length(SPEED);
	
	position += velocity * delta;

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body;

func remove():
	queue_free();

func _on_body_entered(body: Node2D) -> void:
	if not player.attack_upgraded:
		player.attack_upgraded = true;
		remove();
		return;
	
	if not player.can_dash:
		player.can_dash = true;
		remove();
		return;
	
	if player.MID_AIR_JUMPS < 1:
		player.MID_AIR_JUMPS += 1;
		remove();
		return;
	
	print("NO");
	remove();
