class_name Enemy
extends CharacterBody2D

# Base variables for enemy, adjustable only in-engine.
@export var health : int = 1;
@export var gravity : float = 980.0;
var bounceMovementBoost := 1.0;
var propertyFile : Resource;
var direction := 1;
var active = false;

@export var leftRaycast : RayCast2D;
@export var rightRaycast : RayCast2D;
@export var downRaycast : RayCast2D;
@export var upRaycast : RayCast2D;
@export var raycastHelper : Node;

@export var onScreen : VisibleOnScreenNotifier2D;

@export var hitbox: CollisionShape2D;
@export var animatedSprites : AnimatedSprite2D;
var deathTimer : Timer;

var deathAnim : String = "death";

## Initializing, add to the group named enemy
func _ready() -> void:
	add_to_group("enemy");
	
	deathTimer = Timer.new();
	deathTimer.wait_time = 0.4;
	deathTimer.timeout.connect(queue_free);
	add_child(deathTimer);

## Processes for every frame based on time
## delta: Time since previous frame.
func _physics_process(delta: float) -> void:
	# Apply gravity every frame based on time passed since last frame
	apply_gravity(delta)

## Run tile detection with two or four raycasts on the enemy
## horizontal: True if horizontal (left and right) raycasts should be run
func detect_tiles(horizontal : bool) -> void:
	var bounceSpeedBoost = 0;
	# Horizontal Raycasts
	if (horizontal && rightRaycast.is_colliding()):
		direction = -1;
		var raycastTileData : TileData = raycastHelper.get_collision_data(rightRaycast);
		if raycastTileData && raycastTileData.get_custom_data("name") == "bounce":
			bounceMovementBoost = 2 * raycastTileData.get_custom_data("bounce");
			velocity.y += -500 * raycastTileData.get_custom_data("bounce");
	if (horizontal && leftRaycast.is_colliding()):
		direction = 1;
		var raycastTileData : TileData = raycastHelper.get_collision_data(leftRaycast);
		if raycastTileData && raycastTileData.get_custom_data("name") == "bounce":
			bounceMovementBoost = 2 * raycastTileData.get_custom_data("bounce");
			velocity.y += -500 * raycastTileData.get_custom_data("bounce");
	# Vertical raycasts
	if (downRaycast.is_colliding()):
		var raycastTileData : TileData = raycastHelper.get_collision_data(downRaycast);
		if raycastTileData:
			if raycastTileData.get_custom_data("name") == "bounce":
				velocity.y = -1000 * raycastTileData.get_custom_data("bounce");
			elif raycastTileData.get_custom_data("name") == "slow":
				velocity.x /= 2;
	if (upRaycast.is_colliding()):
		var raycastTileData : TileData = raycastHelper.get_collision_data(upRaycast);
		if raycastTileData && raycastTileData.get_custom_data("name") == "bounce":
			velocity.y = 1000 * raycastTileData.get_custom_data("bounce");
	# Decay the movement speed boost from bouncing
	if bounceMovementBoost > 1.0:
		bounceMovementBoost = pow(bounceMovementBoost, .97);
		bounceSpeedBoost = 600 * (bounceMovementBoost - 1.0);
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

## Kills the enemy death sound, and deletes the enemy
func die() -> void:
	AudioManager.play_effect("EnemyDeath");
	if (animatedSprites):
		animatedSprites.play(deathAnim);
	remove_from_group("enemy");
	deathTimer.start();

## Detects whether the enemy is out of bounds.
## Returns a bool based on enemy being out of bounds.
#func check_out_of_bounds() -> bool:
#	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to enemies who leave bounds, before death
#	if (global_position.x < (-1) * Global.TILE_SIZE
#	|| global_position.x > (masterManager.worldSize.x + 1) * Global.TILE_SIZE
#	|| global_position.y < (-1) * Global.TILE_SIZE
#	|| global_position.y > (masterManager.worldSize.y + 1) * Global.TILE_SIZE):
#		print("Player OOB: ", global_position)
#		return true;
#	return false;

## OVERRIDE -
## Assigns the script of the given ID (located in the Resources/Enemies folder) to an enemy at the given position.
## id: The ID of the script to assign
## position: The position of the enemy to assign to the script's appropriate value.
func assign_script(_id: String, _assignPosition: Vector2i) -> void:
	pass;

## OVERRIDE -
## Applies the effects of the given properties in the file to the enemy, this function is used by finding the enemy at the location specified in the script.
## file: The property file to apply to the enemy 
func apply_script(_file: Resource) -> void:
	pass;
