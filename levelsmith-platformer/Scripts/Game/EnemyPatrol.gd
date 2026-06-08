extends CharacterBody2D

@export var groundSpeed := 600
@export var direction = 1

@onready var rayCastRight = $RayCastRight
@onready var rayCastLeft = $RayCastLeft


func _ready():
	add_to_group("enemy")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if rayCastRight.is_colliding():
		direction = -1;
	if rayCastLeft.is_colliding():
		direction = 1;

	velocity.x = direction * groundSpeed;
	velocity += get_gravity() * delta;
	
	move_and_slide();
	pass

func die() -> void:
	AudioManager.play_effect("EnemyDeath");
	queue_free();
