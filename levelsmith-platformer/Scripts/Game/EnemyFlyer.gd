class_name EnemyFlyer;
extends Enemy;

# Movement speed of the enemy.
@export var speed : float = 1.0;

# Movement points, from the spawn position to the preset offset.
var pointA : Vector2;
var pointB : Vector2;

# Current destination point.
var targetPoint : Vector2;

# Time remaining before another collision reversal is allowed.
var obstacleCooldown : float = 0.0;

# Delay between obstacle-triggered reversals.
const OBSTACLE_COOLDOWN_DURATION : float = 0.25;
const SPEED_MODIFIER : float = 100.0;

@export var previewLine : Line2D;

## Adds enemy to group and sets up initial points
func _ready() -> void:
	super._ready();
	
	animatedSprites.animation = "move";
	animatedSprites.play();

	# Set all points to its current position
	pointA = global_position;
	pointB = pointA;
	targetPoint = pointA;


## Processes flying movement and collision handling.
## delta: Time since previous frame.
func _physics_process(delta: float) -> void:
<<<<<<< HEAD
	if (health <= 0): return;
	
=======
	if !active:
		if !onScreen.is_on_screen():
			return;
		active = true;;
>>>>>>> main
	if (obstacleCooldown > 0.0):
		obstacleCooldown -= delta;

	fly_behavior();
	move_and_slide();
	handle_obstacles();


## Moves the enemy toward current destination.
func fly_behavior() -> void:
	# Get the direction and distance of movement
	var direction : Vector2 = targetPoint - global_position;
	var move_distance : float = speed * SPEED_MODIFIER * get_physics_process_delta_time();
	
	# NOTE: Assumes the sprite is facing right
	animatedSprites.flip_h = direction.x <= 0;

	# If the enemy is close enough to the point, change direction
	if (direction.length() <= move_distance):
		global_position = targetPoint;
		velocity = Vector2.ZERO;
		switch_target();
		return;

	velocity = direction.normalized() * speed * SPEED_MODIFIER;


## Switches the active destination.
func switch_target() -> void:
	if targetPoint.distance_to(pointA) < 1.0:
		targetPoint = pointB;
	else:
		targetPoint = pointA;


## Reverses direction if the enemy collides with terrain.
func handle_obstacles() -> void:
	# Early return if the cooldown is not done
	if obstacleCooldown > 0.0:
		return;
	
	# Otherwise, reverse the direction based on the colliding object
	for k in range(get_slide_collision_count()):
		var collision : KinematicCollision2D = get_slide_collision(k);

		if collision.get_collider() is TileMapLayer or Enemy:
			velocity = Vector2.ZERO;
			switch_target();
			obstacleCooldown = OBSTACLE_COOLDOWN_DURATION;
			break;


## Assigns a resource file to the enemy.
## id is the unique identifier of the preset.
## position: Tilemap position of the enemy.
func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Flying" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	name = "Flying" + id;
	propertyFile.position = assignPosition;
	speed = propertyFile.speed;
	pointA = global_position;
	pointB = pointA + propertyFile.pointBOffset;
	targetPoint = pointB;
	ResourceSaver.save(propertyFile);

	apply_script(propertyFile);


## Applies the values stored in a FlyingPreset.
## file: Resource containing enemy properties.
func apply_script(file: Resource) -> void:
	propertyFile = file;

	if file is FlyingPreset:
		speed = file.speed;

		pointA = global_position;
		pointB = pointA + file.pointBOffset;

		targetPoint = pointB;
