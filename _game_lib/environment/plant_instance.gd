class_name PlantInstance
extends Resource

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd")

@export var crop_data: CROP_DATA;
@export var current_stage: CROP_DATA.GrowthStage;
@export var stage_timer: float = 0.0;
@export var planted_time: float = 0.0;

signal stage_changed(new_stage: CROP_DATA.GrowthStage);
signal plant_matured();

func _init(_crop_data: CROP_DATA) -> void:
	crop_data = _crop_data;
	current_stage = CROP_DATA.GrowthStage.UNWATERED;
	stage_timer = 0.0;
	planted_time = Time.get_time_dict_from_system()["second"] as float;

func update_growth(delta: float) -> void:
	if current_stage == CROP_DATA.GrowthStage.STAGE_6:
		return; # Already fully grown

	stage_timer += delta;
	var current_stage_duration: float = crop_data.stage_durations[current_stage];
	if stage_timer >= current_stage_duration:
		advance_stage();

func advance_stage() -> void:
	if current_stage == CROP_DATA.GrowthStage.STAGE_6:
		return;

	current_stage = current_stage + 1 as CROP_DATA.GrowthStage;
	stage_timer = 0.0;

	stage_changed.emit(current_stage);

	if current_stage == CROP_DATA.GrowthStage.STAGE_6:
		plant_matured.emit();

func get_current_frame() -> int:
	return crop_data.stage_frames[current_stage];

func is_unwatered() -> bool:
	return current_stage == CROP_DATA.GrowthStage.UNWATERED;

func is_mature() -> bool:
	return current_stage == CROP_DATA.GrowthStage.STAGE_6;

func water() -> void:
	current_stage = CROP_DATA.GrowthStage.STAGE_1;
	stage_timer = 0.0;
	planted_time = Time.get_time_dict_from_system()["second"] as float;
