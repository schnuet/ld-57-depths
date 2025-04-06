@tool
extends Node2D
class_name LevelSection

@export var size: Vector2i = Vector2i.ONE:
	set(value):
		size = value;
		if size.x < 1:
			size.x = 1;
		if size.y < 1:
			size.y = 1;
		queue_redraw()

@export_group("Open Sides")
@export var top: bool = false;
@export var right: bool = false;
@export var bottom: bool = false;
@export var left: bool = false;

@onready var open_sides = {
	"top": top,
	"right": right,
	"bottom": bottom,
	"left": left
};

@onready var section_area:Area2D = Area2D.new();

const game_dimensions = Vector2i(1920, 1088);

func _ready() -> void:
	# add Area2D
	var collision_shape = CollisionShape2D.new();
	var shape = RectangleShape2D.new();
	shape.size = size * game_dimensions;
	collision_shape.shape = shape;
	collision_shape.position = game_dimensions / 2;
	section_area.add_child(collision_shape);
	section_area.set_collision_mask_value(5, true); # DETECT PLAYER ONLY
	section_area.set_collision_layer_value(1, false);
	section_area.set_collision_layer_value(32, true); # 32 is just so that it has a layer.
	section_area.set_collision_mask_value(1, false);
	section_area.connect("body_entered", _on_section_area_body_entered);
	add_child(section_area);
	
	for child in get_children():
		if child.has_method("awaken"):
			child.awaken();


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2i(0,0, size.x * game_dimensions.x, size.y * game_dimensions.y), Color(1, 0, 0, 0.5), false, 4);
	else:
		draw_rect(Rect2i(0,0, size.x * game_dimensions.x, size.y * game_dimensions.y), Color(1, 0, 0, 0.5), false, 4);

func _on_section_area_body_entered(body: Node2D):
	_on_player_section_entered(body as Jumper);


# =========================================
# SECTION ENTER / LEAVE

func _on_player_section_entered(player: Jumper):
	# set camera limits
	print("player entered ", name);
	adjust_player_camera_limits(player);

func adjust_player_camera_limits(player: Jumper):
	if top:
		player.remove_camera_limit("top")
	else:
		player.add_camera_limit("top", int(global_position.y));
	
	if left:
		player.remove_camera_limit("left")
	else:
		player.add_camera_limit("left", int(global_position.x));
		
	if bottom:
		player.remove_camera_limit("bottom")
	else:
		player.add_camera_limit("bottom", global_position.y + size.y * game_dimensions.y);
	
	if right:
		player.remove_camera_limit("right")
	else:
		player.add_camera_limit("right", global_position.x + size.x * game_dimensions.x);
		
# ==============================
# SIDES

var open_sides_count: int:
	get:
		open_sides_count = 0;
		for side in open_sides.keys():
			if open_sides[side]:
				open_sides_count += 1;
		return open_sides_count;

func meets_criteria(criteria: Dictionary) -> bool:
	if criteria.size() == 0:
		return true;

	for criterium in criteria:
		var value = criteria[criterium];
		if criterium == "openings":
			if open_sides_count != value:
				return false;
		elif criterium == "min_openings":
			if open_sides_count < value:
				return false;
		elif not open_sides.has(criterium):
			return false;
		elif open_sides[criterium] != value:
			return false;
	return true;

func get_open_sides() -> Array:
	var open_sides_array = [];
	for side in open_sides.keys():
		if open_sides[side]:
			open_sides_array.append(side);
	return open_sides_array;

func get_remaining_open_sides(side_to_exclude: String) -> Array:
	var remaining_sides = get_open_sides();
	remaining_sides.erase(side_to_exclude);
	return remaining_sides;

func get_random_remaining_side(side_to_exclude: String) -> String:
	var remaining_sides = get_remaining_open_sides(side_to_exclude);
	if remaining_sides.size() == 0:
		return "";
	var random_index = randi() % remaining_sides.size();
	return remaining_sides[random_index];
