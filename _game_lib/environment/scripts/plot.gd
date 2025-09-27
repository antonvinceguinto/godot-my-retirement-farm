class_name Plot
extends Node2D

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");
const PLANT_INSTANCE = preload("res://_game_lib/environment/plant_instance.gd");

@export var plot_id: int = 0;

# Z-index management constants
const ENTITY_THRESHOLD_DISTANCE: float = 25.0;
const ENTITY_THRESHOLD_DISTANCE_SQUARED: float = ENTITY_THRESHOLD_DISTANCE * ENTITY_THRESHOLD_DISTANCE;
const PLOT_Z_INDEX_FRONT: int = 1;  # When entities should render behind
const PLOT_Z_INDEX_BACK: int = 0;   # Default z-index

# Cached reference to player for performance
var player_ref: Node2D = null;
var current_z_index: int = PLOT_Z_INDEX_BACK;

@onready var soil_sprite: Sprite2D = $GroundSprite;
@onready var plant_sprite: Sprite2D = $PlantSprite;

var current_plant: PLANT_INSTANCE = null;
var is_planted: bool = false;
var is_selected: bool = false;
var coordinates: Vector2;

signal plot_clicked(plot: Plot);
signal plant_harvested(plot: Plot, crop_type: CROP_DATA.CropType);

func _ready() -> void:
	# Add input detection
	set_process_input(true);

	coordinates = global_position;

	# Get player reference for z-index management
	_get_player_reference();

	# Set initial z-index
	z_index = current_z_index;

	# Animation selection
	$AnimatedSelection.visible = false;
	$GroundSprite.visible = false;

	# Ensure plant sprite starts hidden
	if plant_sprite:
		plant_sprite.visible = false;

func _get_player_reference() -> void:
	# Try to find the player using groups (more efficient and reliable)
	var players: Array = get_tree().get_nodes_in_group("Player");

	if players.size() > 0 and players[0] is Node2D:
		player_ref = players[0] as Node2D;

func _should_entity_be_in_front() -> bool:
	# Check if player is within threshold distance and in front of the plot
	if not player_ref:
		return false;

	var distance_squared: float = global_position.distance_squared_to(player_ref.global_position);

	# Calculate plant sprite height for threshold reference
	var plant_height_threshold: float = _get_plant_sprite_height_threshold();

	# Check if player is within threshold distance
	if distance_squared > ENTITY_THRESHOLD_DISTANCE_SQUARED:
		return false;

	# Check if player is roughly in front of the plot using plant sprite as reference
	var player_y: float = player_ref.global_position.y;
	var plot_y: float = global_position.y;

	# Player is considered "in front" if they're overlapping with the plant sprite's height
	# This means the player is at a similar height to the plot and should be behind the plants
	return player_y >= plot_y - plant_height_threshold and player_y <= plot_y + 10.0;

func _get_plant_sprite_height_threshold() -> float:
	# Calculate the plant sprite's actual height for threshold reference
	if not plant_sprite or not plant_sprite.texture:
		return 16.0; # Default fallback threshold

	# Get the sprite's texture size and apply scale
	var sprite_size: Vector2 = plant_sprite.texture.get_size();
	var _frame_width: float = sprite_size.x / plant_sprite.hframes;
	var frame_height: float = sprite_size.y;

	# Apply the sprite's scale
	var scaled_height: float = frame_height * plant_sprite.scale.y;

	# Return half the height as a reasonable threshold for "in front" detection
	return scaled_height / 2.0;

func _update_z_index() -> void:
	var should_be_front: bool = _should_entity_be_in_front();
	var target_z_index: int = PLOT_Z_INDEX_BACK;

	if should_be_front:
		target_z_index = PLOT_Z_INDEX_FRONT;

	# Only update if z-index needs to change (avoid unnecessary updates)
	if current_z_index != target_z_index:
		current_z_index = target_z_index;
		z_index = current_z_index;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var global_mouse_pos: Vector2 = get_global_mouse_position();
			if is_mouse_over_plot(global_mouse_pos):
				plot_clicked.emit(self);

func is_mouse_over_plot(mouse_pos: Vector2) -> bool:
	if not soil_sprite:
		return false;
	
	# Get the sprite bounds in global coordinates
	var sprite_global_pos: Vector2 = soil_sprite.global_position;
	var sprite_size: Vector2 = soil_sprite.texture.get_size() / Vector2(soil_sprite.hframes, soil_sprite.vframes);
	sprite_size *= soil_sprite.global_scale;
	
	var bounds: Rect2 = Rect2(sprite_global_pos - sprite_size / 2, sprite_size);
	return bounds.has_point(mouse_pos);

func plant_seed(crop_data: CROP_DATA) -> bool:
	# Already has a plant
	if is_planted:
		return false;
	
	# Create plant instance for growth logic
	current_plant = PLANT_INSTANCE.new(crop_data);
	is_planted = true;

	# Initialize visual representation
	if plant_sprite:
		plant_sprite.initialize_plant(crop_data.crop_type);
		#plant_sprite.stage_changed.connect(_on_plant_visual_stage_changed);
		#plant_sprite.plant_matured.connect(_on_plant_visual_matured);
		current_plant.stage_changed.connect(_on_plant_growth);
		current_plant.plant_matured.connect(_on_plant_matured);
	
	return true;

func _process(delta: float) -> void:
	# Update z-index based on entity proximity
	_update_z_index();

	if current_plant and is_planted:
		if not current_plant.is_unwatered():
			current_plant.update_growth(delta);

		$AnimatedSelection.visible = false;


func _on_plant_growth(new_stage: CROP_DATA.GrowthStage) -> void:
	# When the plant logic advances, update the visual sprite
	if plant_sprite:
		plant_sprite.advance_stage();
	print("Plot ", plot_id, " plant stage changed to: ", new_stage);


func _on_plant_matured() -> void:
	print("Plot ", plot_id, " plant is now mature and ready for harvest!");


func harvest() -> CROP_DATA.CropType:
	if not is_planted or not current_plant.is_mature():
		return CROP_DATA.CropType.TOMATO; # Invalid harvest
	
	var harvested_crop: CROP_DATA.CropType = current_plant.crop_data.crop_type;
	
	# Clear the plot
	current_plant = null;
	is_planted = false;

	# Reset plant sprite
	if plant_sprite:
		plant_sprite.reset_plant();

	# Reset z-index to default
	current_z_index = PLOT_Z_INDEX_BACK;
	z_index = current_z_index;
	
	plant_harvested.emit(self, harvested_crop);
	return harvested_crop;


func set_selected(selected: bool) -> void:
	is_selected = selected;

	# Animation
	$AnimatedSelection.visible = selected;
	$AnimatedSelection.play("active");

func set_z_index_manually(new_z_index: int) -> void:
	# Allow external systems to override z-index
	current_z_index = new_z_index;
	z_index = new_z_index;

func set_player_reference(player_node: Node2D) -> void:
	# Allow external systems to set a specific player reference
	if player_node and player_node is Node2D:
		player_ref = player_node;

func clear_player_reference() -> void:
	# Clear the player reference (useful for cleanup)
	player_ref = null;


func water() -> void:
	if not current_plant:
		return;

	# Show the watered ground
	$GroundSprite.visible = true;
	current_plant.water();

func get_plant_info() -> Dictionary:
	if not current_plant:
		return {"stage": -1};

	return {
		"crop_name": current_plant.crop_data.crop_name,
		"stage": current_plant.current_stage,
		"is_mature": current_plant.is_mature(),
		"coordinates": coordinates
	};
