class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
var direction : float;

# Firing properties
var shotSpeed : float;
var fireRate : float;
var projBounce : bool;

@export var directionArrow : Sprite2D;

const projectile = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

func _physics_process(delta: float) -> void:
	timeLeft -= delta;
	if (timeLeft <= 0.0):
		shooting_behavior();
		timeLeft = 1 / fireRate;

func adjust_arrow(angle: float) -> void:
	directionArrow.rotation_degrees = angle;
	directionArrow.position.x = sin(deg_to_rad(directionArrow.rotation_degrees)) * 90;
	directionArrow.position.y = -cos(deg_to_rad(directionArrow.rotation_degrees)) * 90;


## Shoots in the determined direction
func shooting_behavior() -> void:
	var projectileFired = projectile.instantiate();
	projectileFired.speed = shotSpeed;
	projectileFired.global_position = position;
	projectileFired.global_rotation_degrees = direction;
	projectileFired.bouncable = projBounce;
	get_parent().add_child(projectileFired);

func assign_script(id: String, position: Vector2i) -> void:
	propertyFile = load("res://Resources/Enemies/Shooting" + id + ".tres");
	name = "Shooting" + id;
	propertyFile.position = position;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;

func apply_script(file: Resource) -> void:
	propertyFile = file;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	timeLeft = 1;
