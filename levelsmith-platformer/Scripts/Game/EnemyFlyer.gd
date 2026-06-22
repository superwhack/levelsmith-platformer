class_name EnemyFlyer;
extends Enemy;

# Movement speed of the enemy.
@export var speed: float = 1.0;

# First movement point, spawn position.
var pointA: Vector2;

# Second movement point calculated from the preset offset.
var pointB: Vector2;

# Current destination point.
var targetPoint: Vector2;

# Time remaining before another collision reversal is allowed.
var obstacleCooldown: float = 0.0;

# Delay between obstacle-triggered reversals.
const OBSTACLE_COOLDOWN_DURATION: float = 0.25;

@export var previewLine: Line2D;

## Initializes patrol points when the enemy is created.
func _ready() -> void:
	super._ready();

	pointA = global_position;
	pointB = pointA;
	targetPoint = pointB;


## Processes flying movement and collision handling.
func _physics_process(delta: float) -> void:
	if obstacleCooldown > 0.0:
		obstacleCooldown -= delta;
	fly_behavior();
	move_and_slide();
	handle_obstacles();


## Moves the enemy toward current destination.
func fly_behavior() -> void:
	var direction := targetPoint - global_position;
	var move_distance := speed * 100 * get_physics_process_delta_time();
	if direction.length() <= move_distance:
		global_position = targetPoint;
		velocity = Vector2.ZERO;
		switch_target();
		return;
	velocity = direction.normalized() * speed * 100;


## Switches the active destination.
func switch_target() -> void:
	if targetPoint.distance_to(pointA) < 1.0:
		targetPoint = pointB;
	else:
		targetPoint = pointA;


## Reverses direction if the enemy collides with terrain.
func handle_obstacles() -> void:
	if obstacleCooldown > 0.0:
		return;

	for k in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(k);

		if collision.get_collider() is TileMapLayer or Enemy:
			velocity = Vector2.ZERO;
			switch_target();
			obstacleCooldown = OBSTACLE_COOLDOWN_DURATION;
			break;


## Assigns a resource file to the enemy.
## id is the unique identifier of the preset.
## position: Tilemap position of the enemy.
func assign_script(id: String, position: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Flying" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	name = "Flying" + id;
	print(propertyFile.speed);
	speed = propertyFile.speed;
	pointA = global_position;
	pointB = pointA + propertyFile.pointBOffset;
	targetPoint = pointB;

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
