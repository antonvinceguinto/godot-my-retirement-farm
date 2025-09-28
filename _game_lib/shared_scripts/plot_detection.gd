class_name PlotDetection
extends Node

# Entity types that can reserve plots
enum EntityType {
	PLAYER,
	WATER_DRONE
}

# Global plot reservation system - static so it's shared across all instances
static var reserved_plots: Dictionary = {}; # plot_id -> entity_identifier
static var plot_manager_ref: Node2D = null;

# Initialize the plot manager reference
static func set_plot_manager(manager: Node2D) -> void:
	plot_manager_ref = manager;

# Get available unwatered plots that aren't reserved by other entities
static func get_available_unwatered_plots(requesting_entity: String = "") -> Array[Plot]:
	if not plot_manager_ref:
		push_error("PlotDetection: Plot manager reference not set!");
		return [];
	
	var all_unwatered: Array[Plot] = plot_manager_ref.get_all_unwatered_plots();
	var available_plots: Array[Plot] = [];
	
	for plot: Plot in all_unwatered:
		# Skip plots that are reserved by other entities
		if reserved_plots.has(plot.plot_id):
			if reserved_plots[plot.plot_id] != requesting_entity:
				continue;
		
		available_plots.append(plot);
	
	return available_plots;

# Reserve a plot for a specific entity
static func reserve_plot(plot: Plot, entity_identifier: String) -> bool:
	if not plot:
		return false;
	
	# Check if plot is already reserved by another entity
	if reserved_plots.has(plot.plot_id) and reserved_plots[plot.plot_id] != entity_identifier:
		return false;
	
	reserved_plots[plot.plot_id] = entity_identifier;
	print("PlotDetection: Plot ", plot.plot_id, " reserved by ", entity_identifier);
	return true;

# Release a plot reservation
static func release_plot(plot: Plot, entity_identifier: String) -> void:
	if not plot:
		return;
	
	if reserved_plots.has(plot.plot_id) and reserved_plots[plot.plot_id] == entity_identifier:
		reserved_plots.erase(plot.plot_id);
		print("PlotDetection: Plot ", plot.plot_id, " released by ", entity_identifier);

# Get the closest available plot to a position
static func get_closest_available_plot(from_position: Vector2, requesting_entity: String = "") -> Plot:
	var available_plots: Array[Plot] = get_available_unwatered_plots(requesting_entity);
	
	if available_plots.is_empty():
		return null;
	
	var closest_plot: Plot = null;
	var shortest_distance: float = INF;
	
	for plot: Plot in available_plots:
		var distance: float = from_position.distance_squared_to(plot.coordinates);
		if distance < shortest_distance:
			shortest_distance = distance;
			closest_plot = plot;
	
	return closest_plot;

# Check if a plot is reserved by a specific entity
static func is_plot_reserved_by(plot: Plot, entity_identifier: String) -> bool:
	if not plot:
		return false;
	
	return reserved_plots.has(plot.plot_id) and reserved_plots[plot.plot_id] == entity_identifier;

# Get reservation info for debugging
static func get_reservation_info() -> Dictionary:
	return reserved_plots.duplicate();
