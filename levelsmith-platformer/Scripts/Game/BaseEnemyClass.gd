class_name Enemy
extends CharacterBody2D

# Currently can't be adjusted in script
var health : int = 1;
var gravity : float = 980.0;

# Speed boost when running into bounce tile to mimic player movement
var bounceMovementBoost := 1.0;

# The enemy's property file, should never be null
var propertyFile : Resource;

# -1 = left, 1 = right
var direction := 1;

# True if the enemy can move/act, generally only enabled when player can see the enemy in play mode
var active = false;

@export var leftRaycast : RayCast2D;
@export var rightRaycast : RayCast2D;
@export var downRaycast : RayCast2D;
@export var upRaycast : RayCast2D;
@export var raycastHelper : Node;

@export var onScreen : VisibleOnScreenNotifier2D;

@export var hitbox: CollisionShape2D;
@export var animatedSprites : AnimatedSprite2D;

var deathAnim : String = "death";

## Initializing, add to the group named enemy and connect animation
func _ready() -> void:
	add_to_group("enemy");
	animatedSprites.animation_finished.connect(on_animation_finished);

## Processes for every frame based on time
## delta: Time since previous frame.
func _physics_process(delta: float) -> void:
	# Apply gravity every frame based on time passed since last frame
	apply_gravity(delta)

const BOUNCE_VEL_HORIZONTAL : int = 500;
const BOUNCE_VEL_VERTICAL : int = 1000;
const BOUNCE_DECAY_RATE : float = 0.97;
const BOUNCE_BASE_BOOST : int = 600;

## Run tile detection with two or four raycasts on the enemy
## horizontal: True if horizontal (left and right) raycasts should be run
func detect_tiles(horizontal : bool) -> void:
	var bounceSpeedBoost = 0;
	
	# -- Horizontal Raycasts -- #
	if (horizontal):
		# Only interactable with bounce tiles
		if (rightRaycast.is_colliding()):
			direction = -1;
			var raycastTileData : TileData = raycastHelper.get_collision_data(rightRaycast);
			if (raycastTileData && raycastTileData.get_custom_data("name") == "bounce"):
				bounceMovementBoost = 2 * raycastTileData.get_custom_data("bounce");
				velocity.y += -BOUNCE_VEL_HORIZONTAL * raycastTileData.get_custom_data("bounce");
		if (leftRaycast.is_colliding()):
			direction = 1;
			var raycastTileData : TileData = raycastHelper.get_collision_data(leftRaycast);
			if (raycastTileData && raycastTileData.get_custom_data("name") == "bounce"):
				bounceMovementBoost = 2 * raycastTileData.get_custom_data("bounce");
				velocity.y += -BOUNCE_VEL_HORIZONTAL * raycastTileData.get_custom_data("bounce");
	
	# -- Vertical raycasts -- #
	if (downRaycast.is_colliding()):
		var raycastTileData : TileData = raycastHelper.get_collision_data(downRaycast);
		if (raycastTileData):
			if (raycastTileData.get_custom_data("name") == "bounce"):
				velocity.y = -BOUNCE_VEL_VERTICAL * raycastTileData.get_custom_data("bounce");
			elif (raycastTileData.get_custom_data("name") == "slow"):
				velocity.x /= 2;
	if (upRaycast.is_colliding()):
		var raycastTileData : TileData = raycastHelper.get_collision_data(upRaycast);
		if (raycastTileData && raycastTileData.get_custom_data("name") == "bounce"):
			velocity.y = BOUNCE_VEL_VERTICAL * raycastTileData.get_custom_data("bounce");
	
	# Decay the movement speed boost from bouncing on the side of a bounce tile
	if (bounceMovementBoost > 1.0):
		bounceMovementBoost = pow(bounceMovementBoost, BOUNCE_DECAY_RATE);
		bounceSpeedBoost = BOUNCE_BASE_BOOST * (bounceMovementBoost - 1.0);
	velocity.x += bounceSpeedBoost * direction;

## Adds gravity
func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

## Applies damage to enemy, triggered by player stomping
## amount: The amount of damage the enemy is taking from a source
func take_damage(amount: int = 1) -> void:
	health -= amount;
	if health <= 0:
		die();

## Kills the enemy death sound, animates the enemy, and then deletes them
func die() -> void:
	# If this is uncommented, then the enemies will also fall through collision while dying
	#hitbox.queue_free();
	AudioManager.play_effect("EnemyDie");
	self.set_collision_layer_value(3, false);
	if (animatedSprites):
		animatedSprites.play(deathAnim);
	remove_from_group("enemy");

## Once the animation is finished, delete this enemy
func on_animation_finished() -> void:
	if (animatedSprites.animation == deathAnim):
		queue_free();

## TO OVERRIDE -
## Assigns the script of the given ID (located in the Resources/Enemies folder) to an enemy at the given position.
## id: The ID of the script to assign
## position: The position of the enemy to assign to the script's appropriate value.
func assign_script(_id: String, _assignPosition: Vector2i) -> void:
	pass;

## TO OVERRIDE -
## Applies the effects of the given properties in the file to the enemy, this function is used by finding the enemy at the location specified in the script.
## file: The property file to apply to the enemy 
func apply_script(_file: Resource) -> void:
	pass;
