class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
var direction : float;

# Firing properties
var shotSpeed : float;
var fireRate : float;
var projBounce : bool;

var gravityOn : bool;

@export var directionArrow : Sprite2D;

const projectile = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

func _physics_process(delta: float) -> void:
	if gravityOn:
		super._physics_process(delta);
		move_and_slide();
	directionArrow.hide();
	timeLeft -= delta;
	if (timeLeft <= 0.0):
		shooting_behavior();
		timeLeft = 1 / fireRate;

## Adjust the direction of the indicator arrow
## angle: the angle that the arrow should be pointing at.
func adjust_arrow(angle: float) -> void:
	directionArrow.show();
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
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Shooting" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Shooting" + id;
	propertyFile.position = position;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	ResourceSaver.save(propertyFile);
	adjust_arrow(direction + 90);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	timeLeft = 1;
