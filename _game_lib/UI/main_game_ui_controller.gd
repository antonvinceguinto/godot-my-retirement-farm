class_name MainGameUIController
extends Control

signal seed_selected(crop_type: CROP_DATA.CropType);

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");
const PLOT_MANAGER = preload("res://_game_lib/environment/plot_manager.gd");

@onready var tomato_button: Button = $CanvasLayer/GridContainer/Button;
@onready var potato_button: Button = $CanvasLayer/GridContainer/Button2;
@onready var wheat_button: Button = $CanvasLayer/GridContainer/Button3;
@onready var cabbage_button: Button = $CanvasLayer/GridContainer/Button4;

var selected_crop = null;
var plot_manager: PLOT_MANAGER;

func _ready() -> void:
	# Connect button signals
	if tomato_button:
		tomato_button.pressed.connect(_on_tomato_selected);
	if potato_button:
		potato_button.pressed.connect(_on_potato_selected);
	if wheat_button:
		wheat_button.pressed.connect(_on_wheat_selected);
	if cabbage_button:
		cabbage_button.pressed.connect(_on_cabbage_selected);
	
	# Find plot manager
	#plot_manager = get_node("$Soil") as PLOT_MANAGER;
	#if plot_manager:
		#print("XXXXX ASD");
		#seed_selected.connect(plot_manager._on_seed_selected);
	
	# Set initial selection
	update_button_selection();

func _on_tomato_selected() -> void:
	selected_crop = CROP_DATA.CropType.TOMATO;
	seed_selected.emit(selected_crop);
	update_button_selection();
	print("Selected crop: TOMATO");

func _on_potato_selected() -> void:
	selected_crop = CROP_DATA.CropType.POTATO;
	seed_selected.emit(selected_crop);
	update_button_selection();
	print("Selected crop: Potato");

func _on_wheat_selected() -> void:
	selected_crop = CROP_DATA.CropType.WHEAT;
	seed_selected.emit(selected_crop);
	update_button_selection();
	print("Selected crop: Wheat");

func _on_cabbage_selected() -> void:
	selected_crop = CROP_DATA.CropType.CABBAGE;
	seed_selected.emit(selected_crop);
	update_button_selection();
	print("Selected crop: Cabbage");

func update_button_selection() -> void:
	# Reset all buttons
	var buttons: Array[Button] = [tomato_button, potato_button, wheat_button, cabbage_button];
	
	for button: Button in buttons:
		if button:
			button.modulate = Color.WHITE;
	
	# Highlight selected button
	var selected_button: Button;
	match selected_crop:
		CROP_DATA.CropType.TOMATO:
			selected_button = tomato_button;
		CROP_DATA.CropType.POTATO:
			selected_button = potato_button;
		CROP_DATA.CropType.WHEAT:
			selected_button = wheat_button;
		CROP_DATA.CropType.CABBAGE:
			selected_button = cabbage_button;
	
	if selected_button:
		selected_button.modulate = Color(0.8, 1.0, 0.8, 1.0); # Green tint for selected
