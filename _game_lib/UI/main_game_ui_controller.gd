class_name MainGameUIController
extends Control

signal seed_selected(crop_data: CROP_DATA);

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");
const PLOT_MANAGER = preload("res://_game_lib/environment/plot_manager.gd");

# UI References
@onready var grid_container: GridContainer = %GridContainer;

# Dynamic button management
var selected_crop = null;
var plot_manager: PLOT_MANAGER;
var crop_button_map: Dictionary = {};
var buttons_array: Array[Button] = [];
var crop_icon_map: Dictionary = {};

func _ready() -> void:
	# Initialize crop icon mapping
	_initialize_crop_icons();

	# Create buttons dynamically
	_create_crop_buttons();

	# Find plot manager
	plot_manager = get_tree().root.get_node("MainGame/PlotManager") as PLOT_MANAGER;
	if plot_manager:
		seed_selected.connect(plot_manager._on_seed_selected);

	# Set initial selection
	update_button_selection();

func _initialize_crop_icons() -> void:
	# Map crop types to their icon resources
	crop_icon_map[CROP_DATA.CropType.TOMATO] = preload("res://_game_lib/environment/seeds/tomato/TomatoItem.png");
	crop_icon_map[CROP_DATA.CropType.POTATO] = preload("res://_game_lib/environment/seeds/potato/PotatoItem.png");
	crop_icon_map[CROP_DATA.CropType.WHEAT] = preload("res://_game_lib/environment/seeds/wheat/WheatItem.png");
	crop_icon_map[CROP_DATA.CropType.PUMPKIN] = preload("res://_game_lib/environment/seeds/pumpkin/PumpkinItem.png");
	crop_icon_map[CROP_DATA.CropType.EGGPLANT] = preload("res://_game_lib/environment/seeds/Eggplant/EggplantItem.png");

func _create_crop_buttons() -> void:
	# Clear existing buttons if any
	_clear_existing_buttons();

	# Create buttons for each available crop type
	for crop_type in CROP_DATA.CropType.values():
		var crop_data: CROP_DATA = CROP_DATA.get_crop_data(crop_type);
		if not crop_data:
			push_warning("Failed to get crop data for type: " + str(crop_type));
			continue;

		# Create new button
		var button: Button = Button.new();
		button.name = crop_data.crop_name + "Button";
		button.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST;
		button.custom_minimum_size = Vector2(61.68, 35);
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER;
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER;
		button.theme = load("res://_game_lib/UI/game_theme.tres");

		# Set text and icon
		button.text = "$" + str(crop_type + 1); # Simple pricing for demo
		if crop_icon_map.has(crop_type):
			button.icon = crop_icon_map[crop_type];

		# Connect signal
		button.pressed.connect(_on_crop_selected.bind(crop_type));

		# Add to container
		grid_container.add_child(button);

		# Store references
		crop_button_map[crop_type] = button;
		buttons_array.append(button);

func _clear_existing_buttons() -> void:
	# Clear existing button mappings and array
	crop_button_map.clear();
	buttons_array.clear();

	# Remove existing button children from grid container
	for child in grid_container.get_children():
		if child is Button:
			child.queue_free();

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

# Public methods for dynamic crop management
func add_crop_button(crop_type: CROP_DATA.CropType, custom_price: String = "") -> void:
	"""Add a new crop button to the UI"""
	var crop_data: CROP_DATA = CROP_DATA.get_crop_data(crop_type);
	if not crop_data:
		push_warning("Cannot add button for unknown crop type: " + str(crop_type));
		return;

	# Check if button already exists
	if crop_button_map.has(crop_type):
		push_warning("Button already exists for crop type: " + str(crop_type));
		return;

	# Create button
	var button: Button = Button.new();
	button.name = crop_data.crop_name + "Button";
	button.texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST;
	button.custom_minimum_size = Vector2(61.68, 35);
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER;
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER;
	button.theme = load("res://_game_lib/UI/game_theme.tres");

	# Set text and icon
	if custom_price.is_empty():
		button.text = "$" + str(crop_type + 1);
	else:
		button.text = custom_price;

	if crop_icon_map.has(crop_type):
		button.icon = crop_icon_map[crop_type];

	# Connect signal
	button.pressed.connect(_on_crop_selected.bind(crop_type));

	# Add to container
	grid_container.add_child(button);

	# Store references
	crop_button_map[crop_type] = button;
	buttons_array.append(button);

func remove_crop_button(crop_type: CROP_DATA.CropType) -> void:
	"""Remove a crop button from the UI"""
	if not crop_button_map.has(crop_type):
		push_warning("No button found for crop type: " + str(crop_type));
		return;

	var button: Button = crop_button_map[crop_type];
	if button:
		button.queue_free();

	# Remove from mappings
	crop_button_map.erase(crop_type);
	buttons_array.erase(button);

	# Clear selection if it was the selected crop
	if selected_crop == crop_type:
		selected_crop = null;
		seed_selected.emit(null);
		update_button_selection();

func refresh_buttons() -> void:
	"""Recreate all buttons (useful if crop data changes)"""
	_create_crop_buttons();
	
