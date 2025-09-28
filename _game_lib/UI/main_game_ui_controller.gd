class_name MainGameUIController
extends Control

signal seed_selected(crop_data: CROP_DATA);

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");
const PLOT_MANAGER = preload("res://_game_lib/environment/plot_manager.gd");

@onready var tomato_button: Button = $CanvasLayer/Control/BGColor/GridContainer/Button;
@onready var potato_button: Button = $CanvasLayer/Control/BGColor/GridContainer/Button2;
@onready var wheat_button: Button = $CanvasLayer/Control/BGColor/GridContainer/Button3;
@onready var pumpkin_button: Button = $CanvasLayer/Control/BGColor/GridContainer/Button4;

var selected_crop = null;
var plot_manager: PLOT_MANAGER;
var crop_button_map: Dictionary = {};
var buttons_array: Array[Button] = [];

func _ready() -> void:
	# Initialize button mappings
	_initialize_button_mappings();

	# Connect button signals using generic handler
	_connect_button_signals();

	# Find plot manager
	plot_manager = get_tree().root.get_node("MainGame/PlotManager") as PLOT_MANAGER;
	if plot_manager:
		seed_selected.connect(plot_manager._on_seed_selected);

	# Set initial selection
	update_button_selection();

func _initialize_button_mappings() -> void:
	# Create mapping between crop types and buttons
	crop_button_map[CROP_DATA.CropType.TOMATO] = tomato_button;
	crop_button_map[CROP_DATA.CropType.POTATO] = potato_button;
	crop_button_map[CROP_DATA.CropType.WHEAT] = wheat_button;
	crop_button_map[CROP_DATA.CropType.PUMPKIN] = pumpkin_button;

	# Create array of all buttons for batch operations
	buttons_array = [tomato_button, potato_button, wheat_button, pumpkin_button];

func _connect_button_signals() -> void:
	# Connect all buttons to the same generic handler
	if tomato_button:
		tomato_button.pressed.connect(_on_crop_selected.bind(CROP_DATA.CropType.TOMATO));
	if potato_button:
		potato_button.pressed.connect(_on_crop_selected.bind(CROP_DATA.CropType.POTATO));
	if wheat_button:
		wheat_button.pressed.connect(_on_crop_selected.bind(CROP_DATA.CropType.WHEAT));
	if pumpkin_button:
		pumpkin_button.pressed.connect(_on_crop_selected.bind(CROP_DATA.CropType.PUMPKIN));

func _on_crop_selected(crop_type: CROP_DATA.CropType) -> void:
	# Toggle selection logic
	if selected_crop == crop_type:
		selected_crop = null;
		seed_selected.emit(null);
	else:
		selected_crop = crop_type;
		seed_selected.emit(CROP_DATA.get_crop_data(selected_crop));

	update_button_selection();


func update_button_selection() -> void:
	# Reset all buttons to default color
	for button: Button in buttons_array:
		if button:
			button.modulate = Color.WHITE;

	# Highlight selected button using the mapping
	if selected_crop != null and crop_button_map.has(selected_crop):
		var selected_button: Button = crop_button_map[selected_crop];
		if selected_button:
			selected_button.modulate = Color(0.8, 1.0, 0.8, 1.0); # Green tint for selected
	
