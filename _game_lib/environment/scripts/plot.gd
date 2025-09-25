class_name Plot
extends Node2D

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");
const PLANT_INSTANCE = preload("res://_game_lib/environment/plant_instance.gd");

@export var plot_id: int = 0;

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
	
	# Animation selection
	$AnimatedSelection.visible = false;
	$GroundSprite.visible = false;
	
	# Ensure plant sprite starts hidden
	if plant_sprite:
		plant_sprite.visible = false;

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
	#if plant_sprite:
		#plant_sprite.reset_plant();
	
	plant_harvested.emit(self, harvested_crop);
	return harvested_crop;


func set_selected(selected: bool) -> void:
	is_selected = selected;
	
	# Animation
	$AnimatedSelection.visible = selected;
	$AnimatedSelection.play("active");


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
