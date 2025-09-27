class_name Player
extends CharacterBody2D

# Constants
#const MOVE_SPEED: float = 15
const MOVE_SPEED: float = 30
const ARRIVAL_THRESHOLD: float = 2.0
const CHECK_INTERVAL: float = 3.0
const ARRIVAL_THRESHOLD_SQUARED: float = ARRIVAL_THRESHOLD * ARRIVAL_THRESHOLD

# Player states
enum PlayerState {
	IDLE,
	WALKING,
	WATERING
}

# Cached node references
@onready var plot_manager: Node2D = %PlotManager;
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D;
@onready var player_chair: Node2D = %PlayerChair;

# Timers
@onready var check_timer: Timer = Timer.new();
@onready var chair_timer: Timer = Timer.new();

# Movement properties
var target_position: Vector2 = Vector2.ZERO;
var current_state: PlayerState = PlayerState.IDLE;
var current_plot: Plot = null;
var current_animation: String = "";

# Signals
signal arrived_at_destination

func _ready() -> void:
	_setup_timer();
	_change_animation("idle");


func _setup_timer() -> void:
	# Water Timer
	check_timer.wait_time = CHECK_INTERVAL;
	check_timer.autostart = true;
	check_timer.timeout.connect(_on_check_timer_timeout);
	add_child(check_timer);
	
	# Chair Timer
	chair_timer.wait_time = CHECK_INTERVAL;
	chair_timer.autostart = true;
	chair_timer.timeout.connect(_on_chair_timer_timeout);
	add_child(chair_timer);

func _physics_process(_delta: float) -> void:
	if current_state == PlayerState.WALKING:
		_handle_movement();


func _handle_movement() -> void:
	var final_target_pos = target_position + Vector2(0, 2);
	
	# Calculate direction to target using cached squared distance for performance
	var distance_squared: float = global_position.distance_squared_to(final_target_pos);
	
	# Check arrival first (most common case when close)
	if distance_squared < ARRIVAL_THRESHOLD_SQUARED:
		_arrive_at_destination();
		return;
	
	# Continue moving
	var direction: Vector2 = (final_target_pos - global_position).normalized();
	velocity = direction * MOVE_SPEED;
	move_and_slide();
	
	# Update animation based on movement direction
	_update_movement_animation(direction);


func _update_movement_animation(direction: Vector2) -> void:
	# Determine primary movement direction
	if abs(direction.x) > abs(direction.y):
		# Moving horizontally
		animated_sprite.flip_h = direction.x < 0;  # Flip when moving left
		_change_animation("walk_right");
	else:
		# Moving vertically or diagonally with more vertical component
		animated_sprite.flip_h = false;  # Reset flip
		_change_animation("walk_front");


func _on_check_timer_timeout() -> void:
	# Only check for plots when idle
	if current_state != PlayerState.IDLE:
		return;
		
	var unwatered_plots: Array[Plot] = plot_manager.get_all_unwatered_plots();
	if unwatered_plots.size() > 0:
		await _walk_to_plot(unwatered_plots[0]);


func _on_chair_timer_timeout() -> void:
	# Only check chair when idle
	if current_state != PlayerState.IDLE:
		return;

	if current_state == PlayerState.IDLE:
		_walk_to_chair();

func _walk_to_chair() -> void:
	target_position = player_chair.global_position;
	current_state = PlayerState.WALKING;
	await arrived_at_destination;
	
	# Return to IDLE state
	current_state = PlayerState.IDLE;
	_change_animation("idle");
	

func _walk_to_plot(plot: Plot) -> void:
	# Prevent overlapping operations
	if current_state != PlayerState.IDLE:
		return;
	
	current_plot = plot;
	target_position = plot.coordinates;
	current_state = PlayerState.WALKING;
	
	# Wait for arrival signal instead of inefficient while loop
	await arrived_at_destination;
	
	# Perform watering sequence
	await _perform_watering();


func _arrive_at_destination() -> void:
	velocity = Vector2.ZERO;
	current_state = PlayerState.IDLE;
	animated_sprite.flip_h = false;  # Reset flip when stopping
	arrived_at_destination.emit();


func _perform_watering() -> void:
	current_state = PlayerState.WATERING;
	_change_animation("watering");
	
	await animated_sprite.animation_finished;
	
	# Water the plot after animation completes
	if current_plot:
		current_plot.water();
		current_plot = null;
	
	# Return to idle state
	current_state = PlayerState.IDLE;
	_change_animation("idle");
	
	# Recheck for new seeds isntantly
	_on_check_timer_timeout();

func _change_animation(animation_name: String) -> void:
	# Only change animation if it's different (performance optimization)
	if current_animation != animation_name:
		current_animation = animation_name;
		animated_sprite.play(animation_name);
