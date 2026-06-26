class_name Player;
extends CharacterBody2D

# Wall direction for wall jumps
enum wallDirection {
	LEFT,
	RIGHT,
	NONE
}

# The player settings that can be changed in editor
@export var groundSpeed : float = 1.0;
@export var jumpHeight : float = 2.0;
@export var doubleJump : bool = true;
var doubleJumpAvailable : bool = doubleJump;

@export var wallJump : bool = true;
var wallJumpCount : int = 0;
var wallJumpDirection : wallDirection = wallDirection.NONE;
var justWallJumped = false;

# Friction in midair
# BUG: Air Control doesn't work the frame you land on a bouncy tile, allowing you to change direction beofre bouncing back up
@export var airControl : float = 1.0;
@export var fallSpeed : float = 1.0;

# Determines how long after leaving a platform you can still jump
@export var coyoteTime : float = 0.2;

@export var iceSpeedCap : int = 10;

var coyoteTimeLeft : float = 0;

# TODO: Make FPS dependant on a global FPS initailly instead of being set to 24
# TODO: Impliment animations and use this
@export var FPS : int = 24;

var spawnpoint : Vector2 = Vector2(0, 0);

# Raycasts
@export var raycasts : Array[RayCast2D];
@export var downwardsRaycasts : Array[RayCast2D];
@export var deathCasts : Array[RayCast2D];

signal healthChanged(newHealth);
var maxHealth := 3;
var health := maxHealth:
	set(newHealth):
		health = newHealth;
		healthChanged.emit(health);
const invulnerabilityTimer := 0.5;
var invulnerabilityCurrent := 0.0;
const flashTimerCap := .05;
var flashTimer := 0.0;

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction : float = 1.0;
var currentSlowdown : float = 1.0;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

# The selected movement preset
# TODO: Make it so that it selects the DefaultMovement preset automatically 
@export var playerMovementPreset : PlayerMovementPreset;

# Enemy collision hitboxes for hooking signals
@export var enemyBounceCollision: Area2D;
@export var enemyCollision: Area2D;

var enemiesInside : Array[Node2D];

## Runs once on instantiation
func _ready() -> void:
	enemyBounceCollision.body_entered.connect(detect_enemy_bounce);
	enemyCollision.body_entered.connect(detect_enemies);
	enemyCollision.body_exited.connect(remove_enemy);
	enemyBounceCollision.area_entered.connect(detect_projectile_bounce);
	enemyCollision.area_entered.connect(detect_projectiles);
	# Applies the preset on ready
	if (playerMovementPreset):
		#print("Applying ", playerMovementPreset, " player movement preset.");
		apply_preset(playerMovementPreset);

## Runs every frame during the play state
## delta: How much time has passed
func _physics_process(delta: float) -> void:
	if (check_out_of_bounds()):
		return;
	justWallJumped = false;
	for enemy in enemiesInside:
		detect_enemies(enemy);
	if invulnerabilityCurrent > 0:
		invulnerabilityCurrent -= delta;
		flashTimer -= delta;
		modulate = Color(1, .5, .5);
		if flashTimer < 0:
			flashTimer = flashTimerCap;
			visible = !visible;
		if invulnerabilityCurrent <= 0:
			modulate = Color(1, 1, 1);
			visible = true;
			flashTimer = 0;
	
	trueSpeed = groundSpeed * 400 * currentSlowdown;
	# Add the gravity; reduce coyoteTimeLeft if in midair, and reset friction.
	if (not is_on_floor()):
		if (coyoteTimeLeft > 0):
			coyoteTimeLeft -= delta;
		velocity += get_gravity() * delta * fallSpeed;
	else:
		doubleJumpAvailable = doubleJump;
		wallJumpDirection = wallDirection.NONE;
		coyoteTimeLeft = coyoteTime;
	
	# Detect tiles before jumping and running so slow and ice tiles apply affects before inputs
	detect_tiles();

	# Jumping with W or Space
	if (Input.is_action_just_pressed("jump") && !justWallJumped):
		if (is_on_floor() || coyoteTimeLeft > 0.0 || doubleJumpAvailable):
			if !(is_on_floor() || coyoteTimeLeft > 0.0):
				doubleJumpAvailable = false;
			coyoteTimeLeft = 0;
			jump();
	# Handle A and D inputs, as well as lack of directional input
	run();
	
	if health > 0:
		move_and_slide();

## Make the player jump
func jump() -> void:
	AudioManager.play_effect("PlayerJump");
	velocity.y = -jumpHeight * 360 * currentSlowdown;
	
## Handle left and right movement logic, with the inclusion of if there is no input
func run() -> void:
	# Acceration in the X direction for the player
	var accelerationX : float;
	var direction : float = Input.get_axis("left", "right");
	# If a direct is pressed, move in the direction, otherwise decellerate towards a 0 velocity 
	if (direction):
		accelerationX = direction * trueSpeed;
	# Acceleration
	else:
		if (currentFriction != 1.0):
			accelerationX = clamp(-velocity.x, -trueSpeed * .5, trueSpeed * .5);
		else:
			accelerationX = clamp(-velocity.x, -trueSpeed * .75, trueSpeed * .75);
	# Air Control
	if (not is_on_floor()):
		accelerationX *= airControl * airControl;

	# Friction while on ice
	if (currentFriction != 1.0 && is_on_floor()):
		accelerationX *= currentFriction * currentFriction * currentFriction;
		if (abs(velocity.x) > trueSpeed * iceSpeedCap):
			accelerationX = 0;
			velocity.x *= .9;
		elif (abs(velocity.x) > trueSpeed):
			if (velocity.x < 0 && accelerationX < 0) || (velocity.x > 0 && accelerationX > 0):
				accelerationX *= .1;
	elif (currentFriction != 1.0 && !is_on_floor()):
		if direction / velocity.x > 0 && abs(velocity.x + accelerationX * .1) > trueSpeed:
			accelerationX = 0;
		else:
			accelerationX *= .05;
		
	# Velocity gets capped so you can't accelerate faster
	elif (abs(velocity.x + accelerationX) > trueSpeed):
		if (abs(velocity.x) > trueSpeed):
			var ratio = pow(trueSpeed / abs(velocity.x), .07);
			velocity.x *= ratio;
		elif (abs(velocity.x + accelerationX) > trueSpeed):
			velocity.x += accelerationX;
			velocity.x = clamp(velocity.x, -trueSpeed, trueSpeed);
		accelerationX = 0;
	# Adjust velocity by acceleration
	velocity.x += accelerationX;

## Have the player take damage
## amount: damage to deal, -1 is instant death
## direction: direction to deal damage in
func take_damage(amount: int, direction: Vector2 = Vector2(0, 0)) -> void:
	if amount < 0:
		return die();
	if invulnerabilityCurrent > 0:
		return;
	invulnerabilityCurrent = invulnerabilityTimer;
	direction.y /= 2;
	velocity = direction * 1000;
	health -= amount;
	if (health <= 0):
		die();
	
## Kill the player and send the global death signal
func die() -> void:
	health = 0;
	AudioManager.play_effect("PlayerDeath");
	Global.death.emit();

## Remove enemies or projectiles when no longer inside of them
## body: the body or area to remove from the array
func remove_enemy(body: Node2D):
	if enemiesInside.find(body) != -1:
		enemiesInside.remove_at(enemiesInside.find(body));

## use raycast to detect enemy collision
# Wait one frame to see if the enemy has been killed by getting landed on, if so then don't take damage
func detect_enemies(body: Node2D) -> void:
	# Wait one frame to see if the enemy has been killed by getting landed on, if so then don't take damage
	await get_tree().process_frame;
	if body && body.is_in_group("enemy"):
		var direction : Vector2 = position - body.position;
		if enemiesInside.find(body) == -1:
			enemiesInside.append(body);
		take_damage(1, direction.normalized());

## Detect collisions between enemies and the bounce area
## body: the body being collided with
func detect_enemy_bounce(body: Node2D) -> void:
	if (body.is_in_group("enemy")):
		if (velocity.y > 0 || body.velocity.y - velocity.y <= 0):
			bounce();
			body.queue_free();

## Detect collisions with projectiles
## area: the area being collided with
func detect_projectiles(area: Area2D) -> void:
	# Wait one frame to see if the projectile has been bounced on
	await get_tree().process_frame;
	if (area && area.is_in_group("Projectile")):
		var direction : Vector2 = position - area.position;
		take_damage(1, direction.normalized());
		area.queue_free();

## Detect collisions between projectiles and the bounce area
## area: the area being collided with
func detect_projectile_bounce(area: Area2D) -> void:
	if (area.is_in_group("Projectile")):
		if area.bounceable:
			bounce();
		else:
			var direction : Vector2 = position - area.position;
			take_damage(1, direction.normalized());
		area.queue_free();

## Bounce the player up
func bounce() -> void:
	if (Input.is_action_pressed("jump")):
		velocity.y = -jumpHeight * 360;
	else:
		velocity.y = -jumpHeight * 240;
	coyoteTimeLeft = 0;

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	
	# Check all collisions with raycasts
	var slideCollisions : Array[RayCast2D] = [];
	var slideCollisionsHit : Array[TileData] = [];
	
	for raycast in raycasts:
		if (raycast.is_colliding()):
			slideCollisions.push_back(raycast);

	for raycast in slideCollisions:
		var collider : Object = raycast.get_collider();
		if (collider is not TileMapLayer): continue;
		
		var tileLayer : TileMapLayer = collider;
		
		var hitGlobal : Vector2 = raycast.get_collision_point();
		var hitNormal : Vector2 = raycast.get_collision_normal();
		var probeGlobal : Vector2 = hitGlobal - hitNormal * 0.5;
		var probeLocal : Vector2 = tileLayer.to_local(probeGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		
		if !tileData || slideCollisionsHit.find(tileData) > -1:
			continue;
		slideCollisionsHit.push_back(tileData);
		var tileName : String = tileData.get_custom_data("name");
		var rayDirection : Vector2 = raycast.target_position;

		# Wall Jumping + Sliding
		if wallJump && rayDirection.x != 0:
			# Wall Slide when not on ice
			if tileName != "ice":
				velocity.y *= .94;
			if Input.is_action_just_pressed("jump"):
				# Depending on direction, apply a different x velocity
				if rayDirection.x < 0:
					if wallJumpDirection != wallDirection.LEFT:
						wallJumpCount = 0;
					wallJumpDirection = wallDirection.LEFT;
					velocity.x = 1500 * pow(groundSpeed, .66);
				elif rayDirection.x > 0:
					if wallJumpDirection != wallDirection.RIGHT:
						wallJumpCount = 0;
					wallJumpDirection = wallDirection.RIGHT;
					velocity.x = -1500 * pow(groundSpeed, .66);
				# Remove friction if not on ice
				if tileName != "ice":
					currentFriction = 1.0;
				# Slow down on slow tiles (and on ice, but you normally wall jump faster anyways)
				if tileName == "slow" || tileName == "ice":
					velocity.x /= 1.5;
				wallJumpCount += 1;
				velocity.y = -300 * jumpHeight * sqrt(1.0 / wallJumpCount);
				justWallJumped = true;

		# Bounce tile collisions
		if (tileName == "bounce"):
			# Horizontal bounces
			if (abs(rayDirection.x) > abs(rayDirection.y)):
				if rayDirection.x < 0:
					velocity.x = 3000 * tileData.get_custom_data("bounce");
				else:
					velocity.x = -3000 * tileData.get_custom_data("bounce");
				if Input.is_action_pressed("jump"):
					velocity.y = -500 * tileData.get_custom_data("bounce");
				# Vertical bounces
			else:
				if (rayDirection.y < 0):
					velocity.y = 1000 * tileData.get_custom_data("bounce");
				else:
					velocity.y = -1000 * tileData.get_custom_data("bounce");
					if velocity.x > 0 && Input.is_action_pressed("left"):
						velocity.x /= 2;
					elif velocity.x < 0 && Input.is_action_pressed("right"):
						velocity.x /= 2;

		# Sticky Tiles
		if (tileData && (tileData.get_custom_data("name") == "slow")):
			currentFriction = 1;
			# Horizontal Stick
			if (abs(raycast.target_position.x) > abs(raycast.target_position.y)):
				velocity.y *= .9;
				# Vertical Stick
			else:
				if (raycast.target_position.y < 0):
					wallJumpDirection = wallDirection.NONE;
					velocity.y = 0;
					if (Input.is_action_just_pressed("down")):
						while raycast.is_colliding():
							position += Vector2(0, 1);
							raycast.force_raycast_update();
					velocity.x = clamp(velocity.x, -trueSpeed * .5, trueSpeed * .5);
				currentSlowdown = .5;
		if tileName == "hazard" && (hitGlobal - position).length() < 57:
			var direction : Vector2 = -raycast.target_position;
			take_damage(1, direction.normalized());
		elif tileName == "death" && (hitGlobal - position).length() < 57:
			take_damage(-1);
		# Only downward rays should drive floor tile effects (except hazard)
		if tileName == "hazard" || tileName == "death" || downwardsRaycasts.has(raycast):
			if (tileData.get_custom_data("name") != "bounce"):
				if (tileData.get_custom_data("name") != "ice"):
					currentFriction = 1.0;
				if (tileData.get_custom_data("name") != "slow"):
					currentSlowdown = 1.0;
			
			match tileName:
				"oneway":
					if Input.is_action_just_pressed("down"):
						position += Vector2(0, 1);
				"ice":
					currentFriction = .5;

## When the player walks/falls out of bounds, force kill them
func check_out_of_bounds() -> bool:
	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to players who leave bounds, before deth
	if (self.global_position.x < (-1) * Global.TILE_SIZE
	|| self.global_position.x > (masterManager.worldSize.x + 2) * Global.TILE_SIZE
	|| self.global_position.y < (-1) * Global.TILE_SIZE
	|| self.global_position.y > (masterManager.worldSize.y + 2) * Global.TILE_SIZE):
		#print("Player OOB: ", self.global_position)
		die();
		return true;
	return false;

## Applies the player selected player movement preset to the player
func apply_preset(preset: PlayerMovementPreset) -> void:
	if (!preset): return;
	
	# Setting all the player variables
	maxHealth = preset.health;
	health = maxHealth
	groundSpeed = preset.groundSpeed;
	jumpHeight = preset.jumpHeight;
	airControl = preset.airControl;
	fallSpeed = preset.fallSpeed;
	coyoteTime = preset.coyoteTime;
	doubleJump = preset.doubleJump;
	wallJump = preset.wallJump;
