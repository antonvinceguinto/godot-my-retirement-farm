extends CharacterBody2D

@onready var plot_manager = %PlotManager;

# Movement properties
var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 50.0
var is_moving: bool = false
var arrival_threshold: float = 2.0  # Distance threshold to consider "arrived"

func _ready() -> void:
	%AnimatedSprite2D.play("idle");

	# Set up the timer to check for unwatered seeds every 5 seconds
	var timer = Timer.new();
	timer.wait_time = 2.0;
	timer.autostart = true;
	timer.timeout.connect(check_for_unwatered_seed);
	add_child(timer);

func _physics_process(_delta: float) -> void:
	if is_moving and target_position != Vector2.ZERO:
		# Calculate direction to target
		var direction: Vector2 = (target_position - global_position).normalized();

		# Set velocity
		velocity = direction * move_speed;

		# Move and slide
		move_and_slide();

		# Play walking animation
		%AnimatedSprite2D.play("walk");

		# Check if we've arrived at the target
		if global_position.distance_to(target_position) < arrival_threshold:
			velocity = Vector2.ZERO;
			is_moving = false;


func check_for_unwatered_seed() -> void:
	var unwatered_plots: Array[Plot] = %PlotManager.get_all_unwatered_plots();
	if unwatered_plots.size() > 0:
		await walk_to_plot(unwatered_plots[0]);


func walk_to_plot(plot: Plot) -> void:
	target_position = plot.coordinates;
	is_moving = true;

	# Wait until we've arrived at the target
	while is_moving:
		await get_tree().physics_frame;
		
	# Play watering animation
	%AnimatedSprite2D.play("watering");
	await %AnimatedSprite2D.animation_finished;

	# Water the plot after arriving
	plot.water();

	# Play idle animation
	%AnimatedSprite2D.play("idle");
