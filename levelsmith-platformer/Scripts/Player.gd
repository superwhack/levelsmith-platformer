extends CharacterBody2D

# The player settings that can be changed in editor
@export var groundSpeed := 1.0;
@export var jumpHeight := 2.0;
# Friction in midair
@export var airControl := 1.0;
@export var fallSpeed := 1.0;
# Determines how long after leaving a platform you can still jump
@export var coyoteTime := 0.2;
var coyoteTimeLeft = 0;
# TODO: Make FPS dependant on a global FPS initailly instead of being set to 24
# TODO: Impliment animations and use this
@export var FPS := 24;

var spawnpoint := Vector2(0, 0);

# Raycasts
@export var raycasts : Array[RayCast2D];
@export var downwardsRaycasts : Array[RayCast2D];

# Audio manager export
#@export var audioManager : Node;

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
	trueSpeed = groundSpeed * 400 * currentSlowdown;
	# Add the gravity; reduce coyoteTimeLeft if in midair
	if not is_on_floor():
		if coyoteTimeLeft > 0:
			coyoteTimeLeft -= delta;
		velocity += get_gravity() * delta * fallSpeed;
	else:
		coyoteTimeLeft = coyoteTime;
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyoteTimeLeft > 0.0:
			# Don't allow double jumps by reducing coyoteTimeLeft to 0
			coyoteTimeLeft = 0;
			jump();
	# Handle A and D inputs, as well as lack of directional input
	run();
	# Look at what the player is colliding with and apply effects
	detect_tiles();
	move_and_slide();

## Make the player jump
func jump() -> void:
	# TODO fix reference later
	#audioManager.play_effect("PlayerJump");
	velocity.y = -jumpHeight * 360 * currentSlowdown;
	
## Handle left and right movement logic, with the inclusion of if there is no input
func run() -> void:
	# Acceration in the X direction for the player
	var accelerationX : float;
	var direction := Input.get_axis("left", "right");
	# If a direct is pressed, move in the direction, otherwise decellerate towards a 0 velocity 
	if direction:
		accelerationX = direction * trueSpeed;
	else:
		accelerationX = -velocity.x;
	
	# Friction and air control
	accelerationX *= currentFriction * currentFriction;
	if not is_on_floor():
		accelerationX *= airControl * airControl;

	# Adjust velocity by acceleration
	velocity.x += accelerationX;
	velocity.x = clamp(velocity.x, -trueSpeed, trueSpeed);

## Have the player take damage
## amount: damage to deal
func take_damage(amount: int) -> void:
	health -= amount;
	if (health <= 0):
		die();
	
## Kill the player and send the global death signal
func die() -> void:
	# TODO fix reference later
	#audioManager.play_effect("PlayerDeath");
	Global.death.emit();

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	# If there is a collision then reset savedFriction and savedSlowdown
	if get_slide_collision_count() != 0:
		currentFriction = 1.0;
		currentSlowdown = 1.0;
	
	# Check all collisions with raycasts
	var slideCollisions: Array[RayCast2D] = [];
	for raycast in raycasts:
		if raycast.is_colliding():
			slideCollisions.push_back(raycast);
	
	var finishedCollisions : Array;
	# Check all current collisions
	for i in slideCollisions.size():
		var collider = slideCollisions[i].get_collider();
		if (finishedCollisions.has(collider)):
			continue;
		finishedCollisions.append(collider);
		# Check for collisions with enemies
		if slideCollisions[i].get_collider() is RigidBody2D:
			# Landed on top of one, kill them and bounce
			if downwardsRaycasts.has(slideCollisions[i]):
				AudioManager.play_effect("EnemyDeath");
				slideCollisions[i].get_collider().queue_free();
				if (Input.is_action_pressed("jump")):
					velocity.y = -jumpHeight * 360;
				else:
					velocity.y = -jumpHeight * 180;
				coyoteTimeLeft = 0;
			# Ran into them or enemy dropped on head, take damage
			else:
				take_damage(1);
		# Only have collisions confer effects if they are below the player
		if slideCollisions[i].get_collider() is TileMapLayer:
			#collider = slideCollisions[i].get_collider();
			# Use the global coord to find tile collision
			var tilePos = collider.local_to_map(position + slideCollisions[i].target_position);
			var tileData = collider.get_cell_tile_data(tilePos);
			if tileData and (tileData.get_custom_data("name") == "hazard" || downwardsRaycasts.has(slideCollisions[i])):
				#print(tilePos, " ", tileData.get_custom_data("name"));
				# Depending on the tile type, apply a different effect
				match (tileData.get_custom_data("name")):
					## NOTE: Theoretical code for the player to drop down through one-ways, works fine but it's a no go for a feature
					"oneway":
						if Input.is_action_just_pressed("down"):
							position += Vector2(0, 1);
					# Bounce the player up
					"bounce":
						velocity.y = -jumpHeight * 600 * tileData.get_custom_data("bounce");
						coyoteTimeLeft = 0;
					# Deal damage to the player
					"hazard":
						take_damage(1);
					# Set friction for the player to slide
					"ice":
						currentFriction = tileData.get_custom_data("friction");
					# Apply a slowdown to player movement and jumps
					"slow":
						currentSlowdown = .5;
						
## When the player walks/falls out of bounds, force kill them
func check_out_of_bounds() -> void:
	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to players who leave bounds, before deth
	if (self.global_position.x < (-1) * Global.tileSize
	|| self.global_position.x > (masterManager.worldSize.y + 2) * Global.tileSize
	|| self.global_position.y < (-1) * Global.tileSize
	|| self.global_position.y > (masterManager.worldSize.x + 2) * Global.tileSize):
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
