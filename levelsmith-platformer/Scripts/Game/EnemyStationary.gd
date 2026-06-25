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

@export var directionArrow : Sprite2D;

## Processes the physics every frame
## delta: Time since previous frame
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if gravityEnabled:
		super._physics_process(delta);
		move_and_slide();
	
	directionArrow.hide();
	

func adjust_arrow(angle: float) -> void:
	directionArrow.show();
	directionArrow.rotation_degrees = angle;
	directionArrow.position.x = sin(deg_to_rad(directionArrow.rotation_degrees)) * 90;
	directionArrow.position.y = -cos(deg_to_rad(directionArrow.rotation_degrees)) * 90;
