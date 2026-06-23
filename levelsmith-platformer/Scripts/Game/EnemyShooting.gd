class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
var direction : float;

# Firing properties
var shotSpeed : float;
var fireRate : float;
var projBounce : bool;

# Gravity toggle
var gravityOn : bool;

# Direction arrow sprite
@export var directionArrow : Sprite2D;

# Projectile scene for instantiating
const PROJECTILE = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

func _physics_process(delta: float) -> void:
	if gravityOn:
		super._physics_process(delta);
		move_and_slide();
	directionArrow.hide();
	# Decrease time left
	timeLeft -= delta;
	# If cooldown is finished, shoot
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
	var projectileFired = PROJECTILE.instantiate();
	projectileFired.speed = shotSpeed;
	projectileFired.global_position = position;
	projectileFired.global_rotation_degrees = direction;
	projectileFired.bounceable = projBounce;
	add_sibling(projectileFired);

func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Shooting" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Shooting" + id;
	propertyFile.position = assignPosition;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	adjust_arrow(direction + 90);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	direction = propertyFile.direction; 
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	timeLeft = 1;
