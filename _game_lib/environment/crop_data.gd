class_name CropData
extends Resource

enum CropType {
	TOMATO,
	POTATO,
	WHEAT,
	PUMPKIN
}

enum GrowthStage {
	UNWATERED,
	STAGE_1,    # Initial seed/sprout stage
	STAGE_2,    # Early growth stage
	STAGE_3,    # Mid growth stage
	STAGE_4,    # Late growth stage
	STAGE_5,    # Pre-mature stage
	STAGE_6     # Fully mature
}

@export var crop_type: CropType;
@export var crop_name: String;
@export var stage_durations: Array[float]; # Time in seconds for each growth stage (including mature stage with 0.0)
@export var stage_frames: Array[int]; # Sprite frames for each growth stage (must match stage_durations length)
@export var image_path: String;
@export var frames: int;

# Static data for different crop types
static func get_crop_data(type: CropType) -> CropData:
	var data: CropData = CropData.new();
	data.crop_type = type;
	
	match type:
		CropType.TOMATO:
			data.crop_name = "Tomato";
			data.stage_durations = [2.0, 4.0, 4.0, 5.0, 5.0, 0.0]; # 6 stages: 5 growth + 1 mature
			data.stage_frames = [0, 0, 1, 2, 3, 4, 5]; # 6 frames for 6 stages
			data.image_path = "res://_game_lib/environment/seeds/tomato/tomato.png";
			data.frames = 6;

		CropType.POTATO:
			data.crop_name = "Potato";
			data.stage_durations = [3.0, 5.0, 7.0, 0.0, 0.0, 0.0]; # 4 stages: 3 growth + 3 mature (reuse mature frame)
			data.stage_frames = [0, 0, 1, 2, 3, 3, 3]; # Repeat mature frame for unused stages
			data.image_path = "res://_game_lib/environment/seeds/potato/potato.png";
			data.frames = 4;

		CropType.WHEAT:
			data.crop_name = "Wheat";
			data.stage_durations = [2.5, 4.5, 5.5, 7.5, 0.0, 0.0]; # 4 stages: 3 growth + 3 mature
			data.stage_frames = [0, 0, 1, 2, 3, 3, 3]; # Repeat mature frame for unused stages
			data.image_path = "res://_game_lib/environment/seeds/wheat/wheat.png";
			data.frames = 4;

		CropType.PUMPKIN:
			data.crop_name = "Pumpkin";
			data.stage_durations = [4.0, 6.0, 8.0, 10.0, 0.0, 0.0]; # 4 stages: 3 growth + 3 mature
			data.stage_frames = [0, 0, 1, 2, 3, 4, 4]; # Repeat mature frame for unused stages
			data.image_path = "res://_game_lib/environment/seeds/pumpkin/pumpkin.png";
			data.frames = 5;
			
	return data;
