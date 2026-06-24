class_name EnemyStationary;
extends Enemy

#Direction property
enum DirectionFacing{ LEFT, RIGHT }

enum CurrentState{ IDLE, DEATH }

var directionFacing : DirectionFacing = DirectionFacing.LEFT;
var currentState : CurrentState = CurrentState.IDLE;

## Processes the physics every frame
## delta: Time since previous frame
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta;
		
		#if(directionFacing == DirectionFacing.LEFT):
			
