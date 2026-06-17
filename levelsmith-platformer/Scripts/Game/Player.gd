class_name Player;
extends CharacterBody2D

# The player settings that can be changed in editor
@export var groundSpeed := 1.0;
@export var jumpHeight := 2.0;
# Friction in midair
# BUG: Air Control doesn't work the frame you land on a bouncy tile, allowing you to change direction beofre bouncing back up
@export var airControl := 1.0;
@export var fallSpeed := 1.0;
# Determines how long after leaving a platform you can still jump
@export var coyoteTime := 0.2;

@export var iceSpeedCap := 10;

var coyoteTimeLeft = 0;
# TODO: Make FPS dependant on a global FPS initailly instead of being set to 24
# TODO: Impliment animations and use this
@export var FPS := 24;

var spawnpoint := Vector2(0, 0);

# Raycasts
@export var raycasts : Array[RayCast2D];
@export var downwardsRaycasts : Array[RayCast2D];

# STRETCH: Make maxHealth an export so the player doesn't always die in one hit
const maxHealth := 1;
var health := maxHealth

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction := 1.0;
var currentSlowdown := 1.0;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

# The selected movement preset
# TODO: Make it so that it selects the DefaultMovement preset automatically 
@export var playerMovementPreset : PlayerMovementPreset;

## Runs once on instantiation
func _ready() -> void:
	# Applies the preset on ready	
	if (playerMovementPreset):
		print("Applying ", playerMovementPreset, " player movement preset.");
		apply_preset(playerMovementPreset);

## Runs every frame during the play state
## delta: How much time has passed
func _physics_process(delta: float) -> void:
	check_out_of_bounds();
	trueSpeed = groundSpeed * 400 * currentSlowdown;
	# Add the gravity; reduce coyoteTimeLeft if in midair, and reset friction.
	if not is_on_floor():
		if coyoteTimeLeft > 0:
			coyoteTimeLeft -= delta;
		velocity += get_gravity() * delta * fallSpeed;
	else:
		coyoteTimeLeft = coyoteTime;
	
	# Detect tiles before jumping and running so slow and ice tiles apply affects before inputs
	detect_tiles();

	# Jumping with W or Space
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyoteTimeLeft > 0.0:
			# Don't allow double jumps by reducing coyoteTimeLeft to 0
			coyoteTimeLeft = 0;
			jump();
	# Handle A and D inputs, as well as lack of directional input
	run();
	
	
	# Look at what the player is colliding with and apply effects
	move_and_slide();

## Make the player jump
func jump() -> void:
	AudioManager.play_effect("PlayerJump");
	velocity.y = -jumpHeight * 360 * currentSlowdown;
	
## Handle left and right movement logic, with the inclusion of if there is no input
func run() -> void:
	# Acceration in the X direction for the player
	var accelerationX : float;
	var direction := Input.get_axis("left", "right");
	# If a direct is pressed, move in the direction, otherwise decellerate towards a 0 velocity 
	if direction:
		accelerationX = direction * trueSpeed * .5;
	else:
		accelerationX = -velocity.x;
	
	# Friction and air control
	if not is_on_floor():
		accelerationX *= airControl * airControl;
	if (currentFriction != 1.0):
		accelerationX *= currentFriction * currentFriction;
		if (abs(velocity.x) > trueSpeed * iceSpeedCap):
			accelerationX = 0;
			velocity.x *= .9;
		elif (abs(velocity.x) > trueSpeed):
			accelerationX *= .25;
	
	if (abs(velocity.x) > trueSpeed && currentFriction == 1.0):
		accelerationX = 0;
		velocity.x *= .9;
	# Adjust velocity by acceleration
	velocity.x += accelerationX;

## Have the player take damage
## amount: damage to deal
func take_damage(amount: int) -> void:
	health -= amount;
	if (health <= 0):
		die();
	
## Kill the player and send the global death signal
func die() -> void:
	AudioManager.play_effect("PlayerDeath");
	Global.death.emit();

## use raycast to detect enemy collision
# Wait one frame to see if the enemy has been killed by getting landed on, if so then don't take damage
func detect_enemies(body: Node2D) -> void:
	await get_tree().process_frame;
	if body && body.is_in_group("enemy"):
		take_damage(1);

func detect_enemy_bounce(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		bounce();
		body.queue_free();

func bounce() -> void:
	if (Input.is_action_pressed("jump")):
		velocity.y = -jumpHeight * 360;
	else:
		velocity.y = -jumpHeight * 240;
	coyoteTimeLeft = 0;

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	
	# Check all collisions with raycasts
	var slideCollisions: Array[RayCast2D] = [];
	for raycast in raycasts:
		if raycast.is_colliding():
			slideCollisions.push_back(raycast);
	
	# Check all current collisions
	for i in slideCollisions.size():
		var collider = slideCollisions[i].get_collider();
		# Have collisions with tiles confer effects
		if collider is TileMapLayer:
			# Use the global coord to find tile collision
			var tilePos = collider.local_to_map(position + slideCollisions[i].target_position + slideCollisions[i].target_position * .1);
			var tileData = collider.get_cell_tile_data(tilePos);
			# Bounce tile collisions
			if tileData && (tileData.get_custom_data("name") == "bounce"):
				# Horizontal Bounces
				if (abs(slideCollisions[i].target_position.x) > abs(slideCollisions[i].target_position.y)):
					if slideCollisions[i].target_position.x < 0:
						velocity.x = 3000 * tileData.get_custom_data("bounce");
					else:
						velocity.x = -3000 * tileData.get_custom_data("bounce");
					if Input.is_action_pressed("jump"):
						velocity.y = -500 * tileData.get_custom_data("bounce");
				# Vertical Bounces
				else:
					if slideCollisions[i].target_position.y < 0:
						velocity.y = 1000 * tileData.get_custom_data("bounce");
					else:
						velocity.y = -1000 * tileData.get_custom_data("bounce");
			if tileData && (tileData.get_custom_data("name") == "slow"):
				# Horizontal Stick
				if (abs(slideCollisions[i].target_position.x) > abs(slideCollisions[i].target_position.y)):
					velocity.y *= .75;
					# NOTE: Uncomment this out if we want to be able to wall jump on sticky tiles
					#if Input.is_action_just_pressed("jump") && !is_on_floor():
					#	if slideCollisions[i].target_position.x < 0:
					#		velocity.x = jumpHeight * 520;
					#	else:
					#		velocity.x = -jumpHeight * 520;
					#	velocity.y = -jumpHeight * 220;;
				# Vertical Stick
				else:
					if slideCollisions[i].target_position.y < 0:
						velocity.y = 0;
						if Input.is_action_just_pressed("down"):
							while slideCollisions[i].is_colliding():
								position += Vector2(0, 1);
								slideCollisions[i].force_raycast_update();
					currentSlowdown = .5;
			if tileData && (tileData.get_custom_data("name") == "hazard" || downwardsRaycasts.has(slideCollisions[i])):
				if tileData.get_custom_data("name") != "bounce":
					currentFriction = 1.0;
					currentSlowdown = 1.0;
				# Depending on the tile type, apply a different effect
				match (tileData.get_custom_data("name")):
					"oneway":
						if Input.is_action_just_pressed("down"):
							position += Vector2(0, 1);
					"hazard":
						take_damage(1);
					# Set friction for the player to slide
					"ice":
						currentFriction = tileData.get_custom_data("friction");

## When the player walks/falls out of bounds, force kill them
func check_out_of_bounds() -> void:
	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to players who leave bounds, before deth
	if (self.global_position.x < (-1) * Global.tileSize
	|| self.global_position.x > (masterManager.worldSize.x + 2) * Global.tileSize
	|| self.global_position.y < (-1) * Global.tileSize
	|| self.global_position.y > (masterManager.worldSize.y + 2) * Global.tileSize):
		print(masterManager.worldSize);
		print("Player OOB: ", self.global_position)
		die();

## Applies the player selected player movement preset to the player
func apply_preset(preset: PlayerMovementPreset) -> void:
	# Setting all the player variables
	groundSpeed = preset.groundSpeed;
	jumpHeight = preset.jumpHeight;
	airControl = preset.airControl;
	fallSpeed = preset.fallSpeed;
	coyoteTime = preset.coyoteTime;
