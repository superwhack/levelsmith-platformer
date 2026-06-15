class_name EnemyFlyer;
extends Enemy;

# Movement speed of the enemy.
@export var speed: float = 300.0;

# First movement point, spawn position.
var pointA: Vector2;

# Second movement point calculated from the preset offset.
var pointB: Vector2;

# Current destination point.
var targetPoint: Vector2;


## Initializes patrol points when the enemy is created.
func _ready() -> void:
	super._ready();

	pointA = global_position;
	pointB = pointA;
	targetPoint = pointB;


## Processes flying movement and collision handling.
func _physics_process(delta: float) -> void:
	fly_behavior();
	move_and_slide();
	handle_obstacles();


## Moves the enemy toward current destination.
func fly_behavior() -> void:
	var direction: Vector2 = targetPoint - global_position;

	if direction.length() < 5.0:
		switch_target();
		return;

	velocity = direction.normalized() * speed;


## Switches the active destination.
func switch_target() -> void:
	if targetPoint.distance_to(pointA) < 1.0:
		targetPoint = pointB;
	else:
		targetPoint = pointA;


## Reverses direction if the enemy collides with terrain.
func handle_obstacles() -> void:
	for k in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(k);

		if collision.get_collider() is TileMapLayer:
			switch_target();
			break;


## Assigns a resource file to the enemy.
## id is the unique identifier of the preset.
## position: Tilemap position of the enemy.
func assign_script(id: String, position: Vector2i) -> void:
	propertyFile = load("res://Resources/Enemies/Flying" + id + ".tres");

	name = "Flying" + id;

	propertyFile.position = position;

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
