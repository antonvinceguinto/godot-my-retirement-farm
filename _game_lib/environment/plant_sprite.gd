class_name PlantSprite
extends Sprite2D

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");

var crop_type: CROP_DATA.CropType = CROP_DATA.CropType.TOMATO;
var crop_data: CROP_DATA;
var current_stage: CROP_DATA.GrowthStage = CROP_DATA.GrowthStage.STAGE_1;

signal stage_changed(new_stage: CROP_DATA.GrowthStage);
signal plant_matured();

func _ready() -> void:
	# Initially hidden until planted
	visible = false;
	current_stage = CROP_DATA.GrowthStage.STAGE_1; # Start at first stage

func initialize_plant(plant_crop_type: CROP_DATA.CropType) -> void:
	crop_type = plant_crop_type;
	crop_data = CROP_DATA.get_crop_data(crop_type);
	current_stage = CROP_DATA.GrowthStage.STAGE_1;
	
	# Load appropriate texture based on crop type
	load_crop_texture();
	
	# Show the sprite and set initial frame
	visible = true;
	update_visual();

func load_crop_texture() -> void:
	var texture_path: String = crop_data.image_path;
			
	# Load texture if it exists, otherwise use default
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path);
		hframes = crop_data.frames;

func advance_stage() -> void:
	if current_stage == CROP_DATA.GrowthStage.STAGE_6:
		return;

	current_stage = current_stage + 1 as CROP_DATA.GrowthStage;
	update_visual();

	stage_changed.emit(current_stage);

	if current_stage == CROP_DATA.GrowthStage.STAGE_6:
		plant_matured.emit();

func update_visual() -> void:
	if not crop_data:
		return;
	
	frame = crop_data.stage_frames[current_stage];

func get_current_stage() -> CROP_DATA.GrowthStage:
	return current_stage;

func is_mature() -> bool:
	return current_stage == CROP_DATA.GrowthStage.STAGE_6;

func reset_plant() -> void:
	visible = false;
	current_stage = CROP_DATA.GrowthStage.STAGE_1;
	crop_data = null;
