class_name EnemyPatrol;
extends Enemy

# Movement variables
var groundSpeed := 1.0;
var direction := 1;

var restricted : bool;

# Detection variables for directional change
@export var rayCastLeft : RayCast2D;
@export var rayCastRight : RayCast2D;

@export var rayCastDownL : RayCast2D;
@export var rayCastDownR : RayCast2D;

func _physics_process(delta: float) -> void:
	# Gravity
	super._physics_process(delta);
	
	patrol_behavior();
	move_and_slide();

## Applies horizontal movements and directional changes triggered by raycasts
func patrol_behavior() -> void:
	if rayCastRight.is_colliding():
		direction = -1;
	if rayCastLeft.is_colliding():
		direction = 1;
	
	# Check for running off of a tile with restricted on
	if restricted && !(rayCastDownL.is_colliding() && rayCastDownR.is_colliding()):
		if (!rayCastDownL.is_colliding()):
			direction = 1;
		elif (!rayCastDownR.is_colliding()):
			direction = -1;
	velocity.x = direction * groundSpeed * 400;
	
	# Check for collisions with other enemies and bounce
	for currentCollision in get_slide_collision_count():
		var collider = get_slide_collision(currentCollision).get_collider();
		if collider != null && collider.is_in_group("Enemy") && collider.position.y < position.y + 40 && collider.position.y > position.y - 40:
			if collider.position.x < position.x:
				direction = 1;
			else:
				direction = -1;

func assign_script(id: String, position: Vector2i) -> void:
	propertyFile = load("res://Resources/Enemies/Patrol" + id + ".tres");
	name = "Patrol" + id;
	propertyFile.position = position;
	groundSpeed = propertyFile.groundSpeed; 
	restricted = propertyFile.restricted; 

func apply_script(file: Resource) -> void:
	propertyFile = file;
	groundSpeed = propertyFile.groundSpeed;
	restricted = propertyFile.restricted;  
