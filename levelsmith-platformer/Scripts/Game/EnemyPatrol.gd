extends Enemy

# Movement variables
@export var groundSpeed := 600
@export var direction := 1

# Detection variables for directional change
@onready var rayCastRight = $RayCastRight
@onready var rayCastLeft = $RayCastLeft

func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # gravity

	patrol_behavior()

	move_and_slide()

## Applies horizontal movements and directional changes triggered by raycasts
func patrol_behavior() -> void:
	if rayCastRight.is_colliding():
		direction = -1
	if rayCastLeft.is_colliding():
		direction = 1
	velocity.x = direction * groundSpeed
