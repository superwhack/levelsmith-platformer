class_name EnemyShooting;
extends Enemy

# Direction of fire, stored as float
var fireDirection : float;
# If true, enemy fires in random directions
var randomDirection : bool;

# Firing properties
# How fast the projectiles go
var shotSpeed : float;
# How fast the enemy fires
var fireRate : float;
# Delay before firing first shot
const INITIAL_DELAY : float = 1.0;
# If the projectiles are bouncable
var projBounce : bool;

# Gravity toggle
var gravityOn : bool;

# Active regardless of being on screen
var alwaysActive : bool;
# Projectiles are persistent of screen
var persistence : bool;

# Direction arrow sprite
@export var directionArrow : Sprite2D;
@export var questionMark : Sprite2D;

# Reverences to Texture2D assets for bullet variants
@export var dangerTexture : Texture2D;
@export var bounceTexture : Texture2D;

# Projectile scene for instantiating
const PROJECTILE : PackedScene = preload("res://Scenes/Entities/Projectile.tscn");

var timeLeft : float = 1;

## Ready animations
func _ready() -> void:
	deathAnim = "ShootDeath";
	super._ready();
	
	animatedSprites.sprite_frames = AnimationManager.shootingEnemyTemplateSprite.sprite_frames;
	animatedSprites.animation = "ShootIdle";
	animatedSprites.play();
	animatedSprites.animation_finished.connect(_on_animation_finished);

func _physics_process(delta: float) -> void:
	# If dead, fall
	if (health <= 0):
		super._physics_process(delta);
		move_and_slide();
		return;
	if (!active && !alwaysActive):
		if !onScreen.is_on_screen():
			return;
		active = true;
	velocity.x = 0;
	if (gravityOn):
		super._physics_process(delta);
	directionArrow.hide();
	
	# If capable of firing, start the timer, when it expires, fire a shot
	if onScreen.is_on_screen() || alwaysActive:
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
## random: if true, display the ? instead
func adjust_arrow(angle: float = fireDirection, random: bool = randomDirection) -> void:
	if (random):
		questionMark.show();
		directionArrow.hide();
		animatedSprites.flip_h = false;
		return;
	questionMark.hide();
	directionArrow.show();
	directionArrow.rotation_degrees = angle;
	directionArrow.position.x = cos(deg_to_rad(directionArrow.rotation_degrees)) * 60;
	directionArrow.position.y = sin(deg_to_rad(directionArrow.rotation_degrees)) * 60;
	animatedSprites.flip_h = (angle <= -90 && angle > -270);


## Shoots in the determined direction
func shooting_behavior() -> void:
	AudioManager.play_effect("Shoot");
	# If the projectiles wouldn't persist off screen and the enemy is off screen, don't spawn the projectile
	if (!persistence && !onScreen.is_on_screen()):
		return;
		
	var projectileFired = PROJECTILE.instantiate();
	projectileFired.speed = shotSpeed;
	projectileFired.global_position = position;
	# If firing in a random direction, randomly rotate the projectile
	if (randomDirection):
		var randFireDirection = randi() % 360;
		projectileFired.global_rotation_degrees = randFireDirection
		update_flipped(!(randFireDirection >= 90 && randFireDirection < 270));
	# Otherwise, the direction is determined by the fireDirection
	else:
		projectileFired.global_rotation_degrees = fireDirection + rotation_degrees;
		
	projectileFired.bounceable = projBounce;
	projectileFired.persistence = persistence;
	if (projBounce):
		projectileFired.assign_texture(bounceTexture);
	else:
		projectileFired.assign_texture(dangerTexture);
	add_sibling(projectileFired);
	animatedSprites.play("EnemyShoot");

## When animation is finished, die.
func _on_animation_finished():
	if (animatedSprites.animation == "EnemyShoot"):
		animatedSprites.play("ShootIdle");

# Updates the orientation of the enemy
func update_flipped(facingRight: bool) -> void:
	animatedSprites.flip_h = !facingRight;

func update_standing(direction):
	if !gravityOn && rotation_degrees != direction * 90:
		rotation_degrees = direction * 90;
		shift_down();

func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("user://Resources/Enemies/Shooting" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Shooting" + id;
	propertyFile.position = assignPosition;
	fireDirection = propertyFile.direction; 
	randomDirection = propertyFile.randomDirection;
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	update_standing(propertyFile.facing);
	persistence = propertyFile.persistence;
	alwaysActive = propertyFile.active;
	ResourceSaver.save(propertyFile);
	adjust_arrow(fireDirection, randomDirection);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	fireDirection = propertyFile.direction; 
	randomDirection = propertyFile.randomDirection;
	shotSpeed = propertyFile.shotSpeed;
	fireRate = propertyFile.fireRate;
	projBounce = propertyFile.projBounce;
	gravityOn = propertyFile.gravity;
	update_standing(propertyFile.facing);
	persistence = propertyFile.persistence;
	alwaysActive = propertyFile.active;
	# Gravity being on impacts the shooting enemy's collisions with moving platforms
	if !(gravityOn):
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING;
		set_collision_layer_value(2, false);
		## NOTE: Uncomment these lines for the moving platform to not collide with the shooting enemy
		#set_collision_mask_value(2, false);
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED;
		set_collision_layer_value(2, true);
		#set_collision_mask_value(2, true);
	timeLeft = INITIAL_DELAY;
