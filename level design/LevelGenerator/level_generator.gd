extends Node2D

@onready var start_sections: Array[LevelSection];
@onready var sections: Array[LevelSection];
@onready var level = $Level;
@onready var main_tilemap = $TileMapLayer;

@onready var game_dimensions = Vector2(1920, 1088); # 1088 is divisable by 64

var taken_spaces: PackedVector2Array = PackedVector2Array();
var section_positions: Dictionary[Vector2i, LevelSection] = {};
var placed_sections: Array[LevelSection] = [];

var PlayerScene = preload("res://player/Jumper/Jumper.tscn");
const SideCamera = preload("res://player/SideCamera/SideCamera.tscn");
const Orb = preload("res://components/Orb/Orb.tscn");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sections_container = $Sections;
	var sections_list = sections_container.get_children();
	for child in sections_list:
		sections.append(child);
	
	sections_container.position = Vector2(-50 * game_dimensions.x, -50 * game_dimensions.y);
	
	var start_sections_container = $StartSections;
	var start_sections_list = start_sections_container.get_children();
	for child in start_sections_list:
		start_sections.append(child);
	
	start_sections_container.position = Vector2(-50 * game_dimensions.x, -50 * game_dimensions.y);
	
	generate_level(30);
	add_player();
	
	MusicPlayer.play_music("horror");

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("regenerate"):
		generate_level(30);
		add_player();


func add_player():
	var player = PlayerScene.instantiate();
	player.position = Vector2(960, 900);
	level.add_child(player);
	
	var camera = SideCamera.instantiate();
	level.add_child(camera);
	camera.following = player;


# ==================================
# LEVEL GENERATION

const ORB_1_LEVEL = 7;
const ORB_2_LEVEL = 14;
const ORB_3_LEVEL = 20;


func generate_level(min_level_size: int = 30) -> void:
	clear_level();


	var start_level_section = start_sections[0];
	if start_level_section == null:
		print("No start section found.");
		return;
	
	var cursor = Vector2i.ZERO;
	var level_size = 1;
	add_level_section(start_level_section, cursor, Vector2.RIGHT, level_size);
	cursor.x += start_level_section.size.x;
	#print("→");

	var direction = Vector2.RIGHT;
	var last_side = "left";
	
	var criteria = {
		"min_openings": 2,
		"left": true
	};

	while level_size < min_level_size:
		#print(cursor);
		var new_section = get_random_level_section(criteria, level_size);
		if (new_section == null):
			print("No valid sections found");
			return generate_level(min_level_size)

		level_size += 1;
		add_level_section(new_section, cursor, direction, level_size);

		var next_side = new_section.get_random_remaining_side(last_side);
		
		if next_side == "":
			print("no place for next tile");
			return generate_level(min_level_size);

		if (next_side == "right"):
			cursor.x += new_section.size.x;
			direction = Vector2.RIGHT;
			last_side = "left";
			criteria = {
				"min_openings": 2,
				"left": true
			}
			#print("→");
		elif (next_side == "top"):
			cursor.y -= new_section.size.y;
			last_side = "bottom";
			criteria = {
				"min_openings": 2,
				"bottom": true
			}
			direction = Vector2.UP;
			#print("↑");
		elif (next_side == "bottom"):
			cursor.y += new_section.size.y;
			last_side = "top";
			criteria = {
				"min_openings": 2,
				"top": true
			}
			direction = Vector2.DOWN;
			#print("↓");
		elif (next_side == "left"):
			cursor.x -= new_section.size.x;
			last_side = "right";
			criteria = {
				"min_openings": 2,
				"right": true
			}
			direction = Vector2.LEFT;
			#print("←");
		
		var blocked_sides = get_blocked_sides(cursor, new_section.size);
		for side in blocked_sides:
			criteria[side] = false;
		criteria[last_side] = true;
		#print("Blocked: ", blocked_sides);

	# Add the last section
	criteria.erase("min_openings");
	criteria["openings"] = 1;
	var last_section = get_random_level_section(criteria, level_size);
	if (last_section == null):
		print("No valid sections found");
		return generate_level(min_level_size)

	level_size += 1;
	add_level_section(last_section, cursor, direction, level_size);


	# Close any open sides
	while(true):
		var placed = 0;
		for section in placed_sections:
			var unblocked_sides = get_unblocked_open_sides(section);
			var pos = Vector2i(int(section.position.x) / game_dimensions.x, int(section.position.y) / game_dimensions.y);
			for side in unblocked_sides:
				var side_pos = pos + side;
				var crits = get_position_criteria(side_pos);
				crits["openings"] = count_openings(crits);
				var new_section = get_random_level_section(crits, 50);
				if (new_section == null):
					print("No valid sections found", crits);
					return;
				level_size += 1;
				add_level_section(new_section, side_pos, side, level_size);
				placed += 1;
		if placed == 0:
			break;

	# Re-set all terrain tilemap tiles
	var main_tilemap_cells = main_tilemap.get_used_cells()
	main_tilemap.set_cells_terrain_connect(main_tilemap_cells, 0, false);

	# set connected section for each placed section
	for section in placed_sections:
		var pos = Vector2i(int(section.position.x) / game_dimensions.x, int(section.position.y) / game_dimensions.y);
		var unblocked_sides = get_unblocked_open_sides(section);
		for side in unblocked_sides:
			var side_pos = pos + side;
			if section_positions.has(side_pos):
				var connected_section = section_positions[side_pos];
				if not section.connected_sections.has(connected_section):
					section.connected_sections.append(connected_section);
					connected_section.connected_sections.append(section);
					print("Connected: ", section.name, " with ", connected_section.name);

func get_random_level_section(criteria: Dictionary, index: int = 50) -> LevelSection:
	var valid_sections: Array[LevelSection] = [];

	if index <= ORB_2_LEVEL:
		if not criteria.has("top"):
			criteria["top"] = false;

	for section in sections:
		if section.meets_criteria(criteria):
			valid_sections.append(section);
	
	if valid_sections.size() == 0:
		print("No valid sections found");
		return null;
	
	var random_index = randi() % valid_sections.size();
	return valid_sections[random_index];


func clear_level() -> void:
	var level_chunks = level.get_children();
	for chunk in level_chunks:
		chunk.queue_free();
	taken_spaces.clear();
	section_positions.clear();
	placed_sections.clear();
	main_tilemap.clear()

func add_level_section(section: LevelSection, p: Vector2i, direction: Vector2, index: int = 0) -> void:
	if section == null:
		return;
	var new_section = section.duplicate();
	new_section.name = section.name + "_" + str(index);

	var section_size = new_section.size;
	for i in range(section_size.x):
		for j in range(section_size.y):
			var space = Vector2i(p.x + i, p.y + j);
			taken_spaces.append(space);
			section_positions[space] = new_section;
	
	var section_position = Vector2i.ZERO;

	if direction == Vector2.RIGHT:
		section_position = Vector2(p.x * game_dimensions.x, p.y * game_dimensions.y);
	elif direction == Vector2.LEFT:
		section_position = Vector2(p.x * game_dimensions.x - (section_size.x-1) * game_dimensions.x, p.y * game_dimensions.y);
	elif direction == Vector2.UP:
		section_position = Vector2(p.x * game_dimensions.x, p.y * game_dimensions.y - (section_size.y-1) * game_dimensions.y);
	elif direction == Vector2.DOWN:
		section_position = Vector2(p.x * game_dimensions.x, p.y * game_dimensions.y);
	else:
		section_position = Vector2(p.x * game_dimensions.x, p.y * game_dimensions.y);

	new_section.position = section_position;

	# add tiles to main tilemap directly
	var tilemap_layer: TileMapLayer = new_section.get_node("TileMapLayer");
	var tilemap_cells = tilemap_layer.get_used_cells();
	var tilemap_pattern = tilemap_layer.get_pattern(tilemap_cells);
	var pattern_offset = get_cells_offset(tilemap_cells);
	main_tilemap.set_pattern(Vector2i(section_position.x / 64 - 1, section_position.y / 64 - 1) - pattern_offset, tilemap_pattern);
	# remove the sections tilemap layer
	tilemap_layer.free();
	
	level.add_child(new_section);
	number_section(new_section, index);
	placed_sections.append(new_section);
	
	if index == ORB_1_LEVEL or index == ORB_2_LEVEL or index == ORB_3_LEVEL:
		var orb = Orb.instantiate();
		new_section.add_child(orb);
		orb.position = Vector2(960, 540);
	
	new_section.connect("player_entered", on_section_entered);


func on_section_entered(section: LevelSection):
	var active_sections = section.connected_sections;
	for level_section in placed_sections:
		if active_sections.find(level_section):
			level_section.awaken();
		else:
			level_section.sleep();


func get_section_at(pos: Vector2i) -> LevelSection:
	if section_positions.has(pos):
		return section_positions[pos];
	return null;


func number_section(section: LevelSection, num: int) -> void:
	# Add a label to the section
	var label = Label.new();
	label.text = str(num);
	label.position = Vector2(200, 200);
	label.add_theme_font_size_override("font_size", 64);
	section.add_child(label);

	var sides_count = section.open_sides_count;
	var count_label = Label.new();
	count_label.text = str(sides_count);
	count_label.position = Vector2(200, 300);
	count_label.text += " " + section.name;
	count_label.add_theme_font_size_override("font_size", 32);
	section.add_child(count_label);


func is_space_free(pos: Vector2i, size: Vector2i) -> bool:
	for i in range(size.x):
		for j in range(size.y):
			var space = Vector2(pos.x + i, pos.y + j);
			if taken_spaces.has(space):
				return false;
	return true;


func get_blocked_sides(pos: Vector2i, size: Vector2i) -> Array:
	var blocked_sides = [];
	if not is_space_free(pos + Vector2i(0, -1), size):
		blocked_sides.append("top");
	if not is_space_free(pos + Vector2i(1, 0), size):
		blocked_sides.append("right");
	if not is_space_free(pos + Vector2i(0, 1), size):
		blocked_sides.append("bottom");
	if not is_space_free(pos + Vector2i(-1, 0), size):
		blocked_sides.append("left");

	return blocked_sides;


func get_unblocked_open_sides(section: LevelSection) -> Array[Vector2i]:
	var unblocked_sides: Array[Vector2i] = [];

	var pos = Vector2i(int(section.position.x) / game_dimensions.x, int(section.position.y) / game_dimensions.y);

	if section.top and not taken_spaces.has(Vector2i(pos.x, pos.y - 1)):
		unblocked_sides.append(Vector2i.UP);
	if section.right and not taken_spaces.has(Vector2i(pos.x + 1, pos.y)):
		unblocked_sides.append(Vector2i.RIGHT);
	if section.bottom and not taken_spaces.has(Vector2i(pos.x, pos.y + 1)):
		unblocked_sides.append(Vector2i.DOWN);
	if section.left and not taken_spaces.has(Vector2i(pos.x - 1, pos.y)):
		unblocked_sides.append(Vector2i.LEFT);

	return unblocked_sides;


func get_position_criteria(pos: Vector2i) -> Dictionary:
	var criteria = {};
	
	var upper = Vector2i(pos.x, pos.y - 1);
	if section_positions.has(upper):
		var section = section_positions[upper];
		if section.bottom:
			criteria["top"] = true;
		else:
			criteria["top"] = false;
	
	var right = Vector2i(pos.x + 1, pos.y);
	if section_positions.has(right):
		var section = section_positions[right];
		if section.left:
			criteria["right"] = true;
		else:
			criteria["right"] = false;
	
	var lower = Vector2i(pos.x, pos.y + 1);
	if section_positions.has(lower):
		var section = section_positions[lower];
		if section.top:
			criteria["bottom"] = true;
		else:
			criteria["bottom"] = false;
	
	var left = Vector2i(pos.x - 1, pos.y);
	if section_positions.has(left):
		var section = section_positions[left];
		if section.right:
			criteria["left"] = true;
		else:
			criteria["left"] = false;

	return criteria;

func count_openings(crits: Dictionary) -> int:
	var openings = 0;
	for side in crits.keys():
		if crits[side] == true:
			openings += 1;
	return openings;

func get_section_ascii_sign(section: LevelSection) -> String:
	var ascii_sign = "";
	if section.top:
		ascii_sign += "T";
	else:
		ascii_sign += " ";
	if section.right:
		ascii_sign += "R";
	else:
		ascii_sign += " ";
	if section.bottom:
		ascii_sign += "B";
	else:
		ascii_sign += " ";
	if section.left:
		ascii_sign += "L";
	else:
		ascii_sign += " ";
	return ascii_sign;


func get_cells_offset(cells: Array[Vector2i]) -> Vector2i:
	var min_x = INF;
	var min_y = INF;

	for cell in cells:
		if cell.x < min_x:
			min_x = cell.x;
		if cell.y < min_y:
			min_y = cell.y;
	
	return Vector2i(
		-1 - min_x,
		-1 - min_y
	);
