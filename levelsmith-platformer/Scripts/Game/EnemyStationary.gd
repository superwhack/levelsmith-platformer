class_name EnemyStationary;
extends Enemy

#Direction property
enum DirectionFacing{ LEFT, RIGHT }

enum CurrentState{ IDLE, DEATH }

#true = stationary enemy is affected by gravity
var gravityEnabled : bool;

#enum variables for the two editable properties
var directionFacing : DirectionFacing = DirectionFacing.LEFT;
var currentState : CurrentState = CurrentState.IDLE;

## Processes the physics every frame
## delta: Time since previous frame
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if gravityEnabled:
		super._physics_process(delta);
		move_and_slide();
	
	

#func assign_script(id: String, assignPosition: Vector2i) -> void:
	#propertyFile = ResourceLoader.load("res://Resources/Enemies/Stationary" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	#name = "Stationary" + id;
	#propertyFile.position = assignPosition;
	#directionFacing = propertyFile.directionFacing;
	#gravityEnabled = propertyFile.gravityEnabled;
	#ResourceSaver.save(propertyFile);
