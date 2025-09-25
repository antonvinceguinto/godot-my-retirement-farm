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

	# Find all nodes that contain Plot children (regardless of their name)
	for child: Node in get_children():
		if child is Node2D:
			# Check if this SOIL NODE contains any Plot children
			var has_plots: bool = false;
			for soil_child: Node in child.get_children():
				if soil_child is Plot:
					has_plots = true;
					break;

			# If this node contains plots, collect all Plot nodes from it
			if has_plots:
				for soil_child: Node in child.get_children():
					if soil_child is Plot:
						plots.append(soil_child as Plot);

	if plots.is_empty():
		push_warning("No plots found in child nodes under PlotManager");
		return;

	# Assign plot IDs in a single pass
	for i: int in range(plots.size()):
		plots[i].plot_id = i;


func _on_seed_selected(crop_data: CROP_DATA) -> void:
	current_selected_crop = crop_data;

	# If no seed is selected (deselected), clear all plot selections
	if crop_data == null:
		for plot in plots:
			plot.set_selected(false);
		return;

	# If a seed is selected, mark all empty plots as selectable
	for plot in plots:
		if plot.current_plant == null:
			plot.set_selected(true);


func _on_plot_clicked(plot: Plot) -> void:
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
		var plant_info: Dictionary = plot.get_plant_info();
		print("Plot ", plot.plot_id, " already has a ", plant_info.crop_name, " (stage: ", plant_info.stage, ")");


func _on_plant_harvested(plot: Plot, crop_type: CROP_DATA.CropType) -> void:
	var crop_data: CROP_DATA = CROP_DATA.get_crop_data(crop_type);
	print("Harvested ", crop_data.crop_name, " from plot ", plot.plot_id);
	
	# Here you can add inventory management or other harvest effects


func get_all_unwatered_plots() -> Array[Plot]:
	var status_list: Array[Plot] = [];
	
	for plot: Plot in plots:
		var plot_status: Dictionary = plot.get_plant_info();
		if plot_status["stage"] == CROP_DATA.GrowthStage.UNWATERED:
			status_list.append(plot);
	
	return status_list;
