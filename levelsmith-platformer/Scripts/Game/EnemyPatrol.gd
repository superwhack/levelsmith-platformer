class_name EnemyPatrol;
extends Enemy

# Movement variables
@export var groundSpeed := 1.0;
@export var direction := 1;

@export var restricted : bool;

# Detection variables for directional change
@export var rayCastLeft : RayCast2D;
@export var rayCastRight : RayCast2D;

func _physics_process(delta: float) -> void:
	# Gravity
	super._physics_process(delta);
	
	patrol_behavior();
	move_and_slide();

## Applies horizontal movements and directional changes triggered by raycasts
func patrol_behavior() -> void:
	if rayCastRight.is_colliding():
		direction = -1
	if rayCastLeft.is_colliding():
		direction = 1
	velocity.x = direction * groundSpeed * 400;

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
