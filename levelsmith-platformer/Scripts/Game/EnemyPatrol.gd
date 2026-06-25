class_name EnemyPatrol;
extends Enemy

# Movement variables
var groundSpeed : float = 1.0;
const SPEED_MODIFIER : float = 400.0;
var bounceBoost := 1.0;

# True = enemies can't fall off ledges
var restricted : bool;

# Detection variables for directional change
@export var rayCastLeft : RayCast2D;
@export var rayCastRight : RayCast2D;
@export var rayCastLeftTop : RayCast2D;
@export var rayCastRightTop : RayCast2D;
@export var rayCastDownL : RayCast2D;
@export var rayCastDownR : RayCast2D;
@export var directionArrow : Sprite2D;

## Processes the physics every frame
## delta: Time since previous frame
func _physics_process(delta: float) -> void:
	# When we are processing physics, we are in the game scene, so the direction
	# arrow can be hidden.
	directionArrow.hide();
	# Processes gravity from base class
	super._physics_process(delta);
	
	# Executing basic movement behavior.
	patrol_behavior();
	super.detect_tiles(true);
	
	move_and_slide();

## Applies horizontal movements and directional changes triggered by raycasts
func patrol_behavior() -> void:
	# If either side raycast is colliding, switch direction.
	if (rayCastRight.is_colliding() || rayCastRightTop.is_colliding()):
		direction = -1;
	if (rayCastLeft.is_colliding() || rayCastLeftTop.is_colliding()):
		direction = 1;
	
	# Check for running off of a tile with restricted on
	if (restricted && !(rayCastDownL.is_colliding() && rayCastDownR.is_colliding())):
		if (!rayCastDownL.is_colliding()):
			direction = 1;
		elif (!rayCastDownR.is_colliding()):
			direction = -1;
	velocity.x = direction * groundSpeed * SPEED_MODIFIER;
	
	# Check for collisions with other enemies and bounce
	for currentCollision in get_slide_collision_count():
		var collider : Object = get_slide_collision(currentCollision).get_collider();
		if collider != null && collider.is_in_group("Enemy") && collider.position.y < position.y + 40 && collider.position.y > position.y - 40:
			if collider.position.x < position.x:
				direction = 1;
			else:
				direction = -1;

## Adjust the current direction of the arrow.
## angle: The angle to adjust it to
func adjust_arrow(angle: float) -> void:
	directionArrow.show();
	directionArrow.rotation_degrees = angle;
	directionArrow.position.x = sin(deg_to_rad(directionArrow.rotation_degrees)) * 90;
	directionArrow.position.y = -cos(deg_to_rad(directionArrow.rotation_degrees)) * 90;

func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Patrolling" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Patrolling" + id;
	propertyFile.position = assignPosition;
	groundSpeed = propertyFile.groundSpeed; 
	direction = -(int(propertyFile.direction) * 2 - 1);
	restricted = propertyFile.restricted; 
	adjust_arrow(int(propertyFile.direction) * 180 + 90);
	directionArrow.scale = Vector2(1, 1);
	ResourceSaver.save(propertyFile);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	groundSpeed = propertyFile.groundSpeed;
	direction = -(int(propertyFile.direction) * 2 - 1);
	restricted = propertyFile.restricted;  
