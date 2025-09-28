class_name WaterDrone
extends Node2D

# Constants
const MOVE_SPEED: float = 25;
const ARRIVAL_THRESHOLD: float = 2;
const CHECK_INTERVAL: float = 5.0;

# Drone states
enum DroneState {
	IDLE,
	MOVING_TO_PLOT,
	WATERING
}

# Signals
signal arrived_at_plot;

@onready var drone_sprite = $DroneSprite;
@onready var dust_sprite = $DustSprite;

# Timers
@onready var check_timer: Timer = Timer.new();

# Movement and state properties
var target_position: Vector2 = Vector2.ZERO;
var current_state: DroneState = DroneState.IDLE;
var current_plot: Plot = null;
var entity_id: String;
var velocity: Vector2 = Vector2.ZERO;

# Cached reference to plot manager
var plot_manager: Node2D = null;

var current_animation: String = "";



func _ready() -> void:
	# Generate unique entity ID for this drone instance
	entity_id = "water_drone_" + str(get_instance_id());
	
	# Initialize sprites
	_change_animation("idle");
	dust_sprite.play("default");
	
	# Setup timer for periodic plot checking
	_setup_timer();
	
	# Find plot manager in the scene (assume it's a sibling or in parent)
	_find_plot_manager();

func _setup_timer() -> void:
	check_timer.wait_time = CHECK_INTERVAL;
	check_timer.autostart = true;
	check_timer.timeout.connect(_on_check_timer_timeout);
	add_child(check_timer);

func _find_plot_manager() -> void:
	# Try to find plot manager by name in the scene tree
	var plot_manager_node: Node = get_tree().get_first_node_in_group("PlotManager");
	
	if plot_manager_node and plot_manager_node is Node2D:
		plot_manager = plot_manager_node as Node2D;
		# Initialize the shared plot detection system
		PlotDetection.set_plot_manager(plot_manager);
		print("WaterDrone: Found plot manager and initialized plot detection");
	else:
		push_warning("WaterDrone: Could not find PlotManager in scene tree");

func _physics_process(delta: float) -> void:
	if current_state == DroneState.MOVING_TO_PLOT:
		_handle_movement(delta);

func _handle_movement(delta: float) -> void:
	var final_target_pos = target_position;
	
	# Calculate direction to target using cached squared distance for performance
	var distance_squared: float = global_position.distance_squared_to(final_target_pos);
	
	# Check arrival first (most common case when close)
	if distance_squared < ARRIVAL_THRESHOLD:
		_arrive_at_plot();
		return;
	
	# Continue moving
	var direction: Vector2 = (final_target_pos - global_position).normalized();
	velocity = direction * MOVE_SPEED;
	
	# Apply movement
	global_position += velocity * delta;

func _on_check_timer_timeout() -> void:
	# Only check for plots when idle
	if current_state != DroneState.IDLE:
		return;
	
	# Use shared plot detection to get closest available plot
	var closest_plot: Plot = PlotDetection.get_closest_available_plot(global_position, entity_id);
	if closest_plot:
		# Reserve the plot before going to it
		if PlotDetection.reserve_plot(closest_plot, entity_id):
			await _move_to_plot(closest_plot);

func _move_to_plot(plot: Plot) -> void:
	# Prevent overlapping operations
	if current_state != DroneState.IDLE:
		# Release reservation if we can't proceed
		PlotDetection.release_plot(plot, entity_id);
		return;
	
	current_plot = plot;
	target_position = plot.coordinates;
	current_state = DroneState.MOVING_TO_PLOT;
	
	# Wait for arrival signal
	await arrived_at_plot;
	
	# Double-check we still have the right plot reserved
	if current_plot and PlotDetection.is_plot_reserved_by(current_plot, entity_id):
		await _perform_watering();
	else:
		# Something went wrong, release and reset
		if current_plot:
			PlotDetection.release_plot(current_plot, entity_id);
		current_plot = null;
		current_state = DroneState.IDLE;

func _arrive_at_plot() -> void:
	velocity = Vector2.ZERO;
	current_state = DroneState.IDLE;
	arrived_at_plot.emit();

func _perform_watering() -> void:
	current_state = DroneState.WATERING;
	_change_animation("watering");
	
	await drone_sprite.animation_finished;
	
	# Water the plot
	if current_plot:
		current_plot.water();

		# Release plot reservation after watering is complete
		PlotDetection.release_plot(current_plot, entity_id);
		current_plot = null;
	
	# Return to idle state
	current_state = DroneState.IDLE;
	_change_animation("idle");
	
	# Immediately check for new plots to water
	_on_check_timer_timeout();
	

func _change_animation(animation_name: String) -> void:
	# Only change animation if it's different (performance optimization)
	if current_animation != animation_name:
		current_animation = animation_name;
		drone_sprite.play(animation_name);
