class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
var fireDirection : float;
var randomDirection : bool;

# Firing properties
var shotSpeed : float;
var fireRate : float;
var projBounce : bool;

# Gravity toggle
var gravityOn : bool;

# Direction arrow sprite
@export var directionArrow : Sprite2D;
@export var questionMark : Sprite2D;

# Projectile scene for instantiating
const PROJECTILE : PackedScene = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

func _ready() -> void:
	deathAnim = "ShootDeath";
	super._ready();
	
	#AnimationManager.replace_animation_by_name(animatedSprites, "ShootIdle");
	#AnimationManager.replace_animation_by_name(animatedSprites, "EnemyShoot");
	
	animatedSprites.sprite_frames = AnimationManager.shootingEnemyTemplateSprite.sprite_frames;
	
	animatedSprites.animation = "ShootIdle";
	animatedSprites.play();
	animatedSprites.animation_finished.connect(_on_animation_finished);

func _physics_process(delta: float) -> void:
	if !active:
		if !onScreen.is_on_screen():
			return;
		active = true;
	velocity.x = 0;
	if gravityOn:
		super._physics_process(delta);
	directionArrow.hide();
	if onScreen:
		if (!randomDirection):
			update_flipped(!(fireDirection <= -90 && fireDirection > -270));
		# Decrease time left
		timeLeft -= delta;
		# If cooldown is finished, shoot
		if (timeLeft <= 0.0):
			shooting_behavior();
			timeLeft = 1 / fireRate;
	super.detect_tiles(false);
	move_and_slide();

## Adjust the direction of the indicator arrow
## angle: the angle that the arrow should be pointing at.
func adjust_arrow(angle: float = fireDirection + 90, random: bool = randomDirection) -> void:
	if random:
		questionMark.show();
		directionArrow.hide();
		return;
	questionMark.hide();
	directionArrow.show();
	directionArrow.rotation_degrees = angle;
	directionArrow.position.x = sin(deg_to_rad(directionArrow.rotation_degrees)) * 90;
	directionArrow.position.y = -cos(deg_to_rad(directionArrow.rotation_degrees)) * 90;


## Shoots in the determined direction
func shooting_behavior() -> void:
	var projectileFired = PROJECTILE.instantiate();
	projectileFired.speed = shotSpeed;
	projectileFired.global_position = position;
	if randomDirection:
		var randFireDirection = randi() % 360;
		projectileFired.global_rotation_degrees = randFireDirection
		update_flipped(!(randFireDirection >= 90 && randFireDirection < 270));
	else:
		projectileFired.global_rotation_degrees = fireDirection;
	projectileFired.bounceable = projBounce;
	add_sibling(projectileFired);
	animatedSprites.play("EnemyShoot");

func _on_animation_finished():
	if (animatedSprites.animation == "EnemyShoot"):
		animatedSprites.play("ShootIdle");

# Updates the orientation of the enemy
func update_flipped(facingRight: bool) -> void:
	animatedSprites.flip_h = !facingRight;

func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Shooting" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Shooting" + id;
	propertyFile.position = assignPosition;
	fireDirection = propertyFile.direction; 
	randomDirection = propertyFile.randomDirection;
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	ResourceSaver.save(propertyFile);
	adjust_arrow(fireDirection + 90, randomDirection);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	fireDirection = propertyFile.direction; 
	randomDirection = propertyFile.randomDirection;
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	if !gravityOn:
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING;
		set_collision_layer_value(2, false);
		## NOTE: Uncomment these lines for the moving platform to not collide with the shooting enemy
		#set_collision_mask_value(2, false);
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED;
		set_collision_layer_value(2, true);
		#set_collision_mask_value(2, true);
	timeLeft = 1;
