class_name PlotManager
extends Node2D

const CROP_DATA = preload("res://_game_lib/environment/crop_data.gd");

var plots: Array[Plot] = [];
var selected_plot: Plot = null;
var current_selected_crop: CROP_DATA = null;

func _ready() -> void:
	# Find all plot nodes
	find_plots();
	
	# Connect plot signals
	for plot: Plot in plots:
		plot.plot_clicked.connect(_on_plot_clicked);
		plot.plant_harvested.connect(_on_plant_harvested);


func find_plots() -> void:
	plots.clear();
	
	# Find all child nodes that are plots
	for i: int in range(get_child_count()):
		var child: Node = get_child(i);
		if child is Plot:
			var plot: Plot = child as Plot;
			plot.plot_id = i;
			plots.append(plot);


func _on_seed_selected(crop_data: CROP_DATA) -> void:
	current_selected_crop = crop_data;


func _on_plot_clicked(plot: Plot) -> void:
	print("Plot clicked: ", plot.plot_id);
	
	# Clear previous selection
	if selected_plot:
		selected_plot.set_selected(false);
	
	# Select new plot
	selected_plot = plot;
	plot.set_selected(true);
	
	# Try to plant the selected crop
	if not plot.is_planted:
		if !current_selected_crop:
			return

		var success: bool = plot.plant_seed(current_selected_crop);
		if success:
			var crop_data: CROP_DATA = current_selected_crop;
			print("Planted ", crop_data.crop_name, " in plot ", plot.plot_id);
		else:
			print("Failed to plant seed in plot ", plot.plot_id);
	else:
		var plant_info: Dictionary = plot.get_plant_info();
		print("Plot ", plot.plot_id, " already has a ", plant_info.crop_name, " (stage: ", plant_info.stage, ")");


func _on_plant_harvested(plot: Plot, crop_type: CROP_DATA.CropType) -> void:
	var crop_data: CROP_DATA = CROP_DATA.get_crop_data(crop_type);
	print("Harvested ", crop_data.crop_name, " from plot ", plot.plot_id);
	
	# Here you can add inventory management or other harvest effects


func get_all_plots_status() -> Array[Dictionary]:
	var status_list: Array[Dictionary] = [];
	
	for plot: Plot in plots:
		var plot_status: Dictionary = plot.get_plant_info();
		plot_status["plot_id"] = plot.plot_id;
		status_list.append(plot_status);
	
	return status_list;
