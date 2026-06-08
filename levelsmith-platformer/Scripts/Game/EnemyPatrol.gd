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
	velocity.y += 980 * delta;
	
	move_and_slide();
	pass

func _on_hurt_area_body_entered(body):
	print("HIT:", body);
	print("GROUPS:", body.get_groups());
	if body.is_in_group("player"):
		body.take_damage(1);

func die() -> void:
	AudioManager.play_effect("EnemyDeath");
	queue_free();
