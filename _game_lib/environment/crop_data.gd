class_name CropData
extends Resource

enum CropType {
	TOMATO,
	POTATO,
	WHEAT,
	CABBAGE
}

enum GrowthStage {
	SEED,
	SPROUT,
	GROWING,
	MATURE
}

@export var crop_type: CropType;
@export var crop_name: String;
@export var stage_durations: Array[float]; # Time in seconds for each growth stage
@export var stage_frames: Array[int]; # Sprite frames for each growth stage on the tileset

# Static data for different crop types
static func get_crop_data(type: CropType) -> CropData:
	var data: CropData = CropData.new();
	data.crop_type = type;
	
	match type:
		CropType.TOMATO:
			data.crop_name = "Tomato";
			data.stage_durations = [2.0, 4.0, 6.0, 7.0, 8.0, 0.0]; # Last stage (mature) doesn't have duration
			data.stage_frames = [0, 1, 2, 3, 4, 5]; # Frames on the tileset
			
		CropType.POTATO:
			data.crop_name = "Potato";
			data.stage_durations = [3.0, 5.0, 7.0, 0.0];
			data.stage_frames = [4, 5, 6, 7];
			
		CropType.WHEAT:
			data.crop_name = "Wheat";
			data.stage_durations = [2.5, 4.5, 5.5, 0.0];
			data.stage_frames = [8, 9, 10, 11];
			
		CropType.CABBAGE:
			data.crop_name = "Cabbage";
			data.stage_durations = [4.0, 6.0, 8.0, 0.0];
			data.stage_frames = [12, 13, 14, 15];
			
	return data;
