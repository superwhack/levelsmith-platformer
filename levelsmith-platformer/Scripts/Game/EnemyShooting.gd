class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
@export var direction : float;

# Firing properties
@export var shotSpeed : float;
@export var fireRate : float;

const projectile = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

func _physics_process(delta: float) -> void:
	timeLeft -= delta;
	if (timeLeft <= 0.0):
		shooting_behavior();
		timeLeft = 1 / fireRate;

## Shoots in the determined direction
func shooting_behavior() -> void:
	var projectileFired = projectile.instantiate();
	projectileFired.speed = shotSpeed;
	projectileFired.global_position = position;
	projectileFired.global_rotation_degrees = direction;
	get_parent().add_child(projectileFired);

func assign_script(id: String, position: Vector2i) -> void:
	propertyFile = load("res://Resources/Enemies/Shooting" + id + ".tres");
	name = "Shooting" + id;
	propertyFile.position = position;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;

func apply_script(file: Resource) -> void:
	propertyFile = file;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	timeLeft = 1;
