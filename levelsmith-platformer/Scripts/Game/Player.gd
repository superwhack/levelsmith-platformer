class_name Player;
extends CharacterBody2D

# Wall direction for wall jumps
enum WallDirection {
	LEFT,
	RIGHT,
	NONE
}

# FSM that controls the player's state
enum PlayerState {
	GROUNDED,
	RUNNING,
	JUMPING,
	FALLING,
	SLIDING,
	BOUNCING,
	DEAD
}

var currentState : PlayerState = PlayerState.GROUNDED;

# The player settings that can be changed in editor
@export var groundSpeed : float = 1.0;
@export var baseAcceleration : float = 1.0;
@export var baseDeceleration : float = 1.0;
@export var jumpHeight : float = 2.0;
@export var doubleJump : bool = false;
var doubleJumpAvailable : bool = doubleJump;

# If the player can drop through oneways
@export var oneways : bool = true;

@export var wallJump : bool = false;
var wallJumpCount : int = 0;
var wallJumpDirection : WallDirection = WallDirection.NONE;
var justWallJumped = false;
var wallJumpDecay = false;

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
var currentWalkingEffect : Global.WalkingEffect;

# Raycasts
@export var raycasts : Array[RayCast2D];
@export var downwardsRaycasts : Array[RayCast2D];

signal healthChanged(newHealth);
var maxHealth := 3;
var health := maxHealth:
	set(newHealth):
		health = newHealth;
		healthChanged.emit(health);
const invulnerabilityTimer := 0.5;
var invulnerabilityCurrent := 0.0;

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction : float = 1.0;
var currentSlowdown : float = 1.0;
var slidingSticky : bool = false;

# Direction, moved here so the animations can use it as well
var direction : float;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

var bounceTileHeight : float = 1.0;
var iceFriction : float = 0.5;

var iceAccelerationFactor : float = .25;

# The selected movement preset
# TODO: Make it so that it selects the DefaultMovement preset automatically 
@export var playerMovementPreset : PlayerMovementPreset;

# Enemy collision hitboxes for hooking signals
@export var enemyBounceCollision: Area2D;
@export var enemyCollision: Area2D;

var enemiesInside : Array[Node2D];

@export var animatedSprites : AnimatedSprite2D;
@onready var jumpTimer : Timer = Timer.new();
var isJumping : bool = false;
var jumpAnimStarted : bool = false;
var fallAnimStarted : bool = false;

var victory : bool = false;

## Runs once on instantiation
func _ready() -> void:
	enemyBounceCollision.body_entered.connect(detect_enemy_bounce);
	enemyCollision.body_entered.connect(detect_enemies);
	enemyCollision.body_exited.connect(remove_enemy);
	enemyBounceCollision.area_entered.connect(detect_projectile_bounce);
	enemyCollision.area_entered.connect(detect_projectiles);
	# Applies the preset on ready
	if (playerMovementPreset):
		apply_preset(playerMovementPreset);
	
	#for animationName in animatedSprites.sprite_frames.get_animation_names():
		#AnimationManager.replace_animation_by_name(animatedSprites, animationName);
	
	var swap_to_fall = func () -> void:
		isJumping = false;
	
	jumpTimer.wait_time = 0.8;
	jumpTimer.timeout.connect(swap_to_fall);
	add_child(jumpTimer);
	
	animatedSprites.sprite_frames = AnimationManager.playerTemplateSprite.sprite_frames;
	
	animatedSprites.animation = "PlayerIdle";
	animatedSprites.play();
	
	animatedSprites.animation_finished.connect(on_animation_finished);
	

## Runs every frame during the play state
## delta: How much time has passed
func _physics_process(delta: float) -> void:
	if (check_out_of_bounds() || victory):
		return;
	if currentState == PlayerState.DEAD:
		animate();
		return;
	if (currentState == PlayerState.BOUNCING || PlayerState.JUMPING) && velocity.y > 0:
		currentState = PlayerState.FALLING;
	
	justWallJumped = false;
	for enemy in enemiesInside:
		detect_enemies(enemy);
	if invulnerabilityCurrent > 0:
		invulnerabilityCurrent -= delta;
	
	trueSpeed = groundSpeed * 400 * currentSlowdown;
	# Add the gravity; reduce coyoteTimeLeft if in midair, and reset friction.
	if (not is_on_floor()):
		currentWalkingEffect = Global.WalkingEffect.NONE;
		if (coyoteTimeLeft > 0):
			coyoteTimeLeft -= delta;
		velocity += get_gravity() * delta * fallSpeed;
	else:
		isJumping = false;
		jumpAnimStarted = false;
		doubleJumpAvailable = doubleJump;
		wallJumpDirection = WallDirection.NONE;
		coyoteTimeLeft = coyoteTime;
	
	# Detect tiles before jumping and running so slow and ice tiles apply affects before inputs
	detect_tiles();
	# Jumping with W or Space
	if (Input.is_action_just_pressed("jump") && !victory && !justWallJumped && jumpHeight != 0):
		if (currentState == PlayerState.GROUNDED || coyoteTimeLeft > 0.0 || doubleJumpAvailable):
			if !(currentState == PlayerState.GROUNDED || coyoteTimeLeft > 0.0):
				currentSlowdown = 1.0;
				doubleJumpAvailable = false;
			coyoteTimeLeft = 0;
			jumpAnimStarted = false;
			currentState = PlayerState.JUMPING;
			jump(); 
	# Handle A and D inputs, as well as lack of directional input
	walk();
	
	if health > 0:
		move_and_slide();
	if !victory:
		AudioManager.play_effect_walking(currentWalkingEffect);
		animate();

## Animates the player while processing
func animate() -> void:
	if !is_on_floor() && currentState != PlayerState.SLIDING:
		if velocity.x < 0:
			animatedSprites.flip_h = true;
		elif velocity.x > 0:
			animatedSprites.flip_h = false;
	elif !victory:
		if Input.is_action_pressed("left"):
			animatedSprites.flip_h = true;
		elif Input.is_action_pressed("right"):
			animatedSprites.flip_h = false;
	if (health <= 0): 
		animatedSprites.animation = "PlayerDeath";
		animatedSprites.flip_h = false;
	elif (invulnerabilityCurrent > 0):
		animatedSprites.animation = "PlayerHurt";
		fallAnimStarted = false;
	elif (currentState == PlayerState.JUMPING || currentState == PlayerState.BOUNCING):
		animatedSprites.animation = "PlayerJump";
		fallAnimStarted = false;
		if (!jumpAnimStarted):
			jumpAnimStarted = true;
		else:
			return;
	elif (currentState == PlayerState.SLIDING):
		animatedSprites.animation = "PlayerWallSlide";
		fallAnimStarted = false;
	elif (currentState == PlayerState.FALLING):
		animatedSprites.animation = "PlayerFall";
		if (!fallAnimStarted):
			fallAnimStarted = true;
		else:
			return;
	elif (currentState == PlayerState.RUNNING):
		animatedSprites.animation = "PlayerRun";
		fallAnimStarted = false;
	else:
		animatedSprites.animation = "PlayerIdle";
		fallAnimStarted = false;
	animatedSprites.play();

## Event for 
func on_animation_finished() -> void:
	if (animatedSprites.animation == "PlayerDeath"):
		Global.death.emit();
	elif (animatedSprites.animation == "PlayerVictory"):
		await get_tree().create_timer(1.0).timeout;
		Global.complete.emit();

## Make the player jump
func jump() -> void:
	AudioManager.play_effect("Jump");
	velocity.y = -sqrt(jumpHeight) * 496 * currentSlowdown * sqrt(fallSpeed);
	isJumping = true;
	jumpTimer.start();

## Handle left and right movement logic, with the inclusion of if there is no input
func walk() -> void:
	# Acceration in the X direction for the player
	var accelerationX : float;
	if !victory:
		direction = Input.get_axis("left", "right");
	else:
		direction = 0;
	# If a direct is pressed, move in the direction, otherwise decelerate towards a 0 velocity 
	if (direction):
		if currentState == PlayerState.GROUNDED:
			currentState = PlayerState.RUNNING;
		accelerationX = direction * trueSpeed;
		# Acceleration if moving in direction of current movement
		if baseAcceleration != 1.0 && (sign(velocity.x) == sign(direction) || velocity.x == 0):
			accelerationX = direction * pow(abs(accelerationX), pow(baseAcceleration, 2));
			if baseAcceleration + currentFriction < 1.25:
				currentFriction = 1.25 - baseAcceleration
		# Deceleration if moving in opposite direction
		elif baseDeceleration != 1.0 && sign(velocity.x) != sign(direction):
			if baseDeceleration + currentFriction < 1.25:
				currentFriction = 1.25 - baseDeceleration
			accelerationX *= pow(baseDeceleration, 5);
	# Acceleration
	else:
		if !slidingSticky:
			currentWalkingEffect = Global.WalkingEffect.NONE;
		if (currentFriction != 1.0):
			accelerationX = clamp(-velocity.x, -trueSpeed * .5, trueSpeed * .5);
		else:
			accelerationX = clamp(-velocity.x, -max(trueSpeed, 400) * .75, max(trueSpeed, 400) * .75);
		# Deceleration if not moving
		if baseDeceleration != 1.0:
			accelerationX *= pow(baseDeceleration, 5);
		# Clamping if velocity is too low
		if abs(velocity.x) < 10 * groundSpeed:
			accelerationX = -velocity.x;
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
				accelerationX *= iceAccelerationFactor;
	elif (currentFriction != 1.0 && !is_on_floor()):
		if direction / velocity.x > 0 && abs(velocity.x + accelerationX * .1) > trueSpeed:
			accelerationX = 0;
		else:
			if airControl != 0:
				accelerationX *= .05 / pow(airControl, 2);
			else:
				accelerationX *= .05;
		
	# Velocity gets capped so you can't accelerate faster
	elif (abs(velocity.x + accelerationX) > trueSpeed && groundSpeed != 0):
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
## higherBounce: if the player should bounce higher
## returns: true is damage applied
## onFloorBypass: If true, the player is NOT on the floor for knockback
func take_damage(amount: int, direction: Vector2 = Vector2(0, 0), higherBounce : int = 0, onFloorBypass : bool = false) -> bool:
	if invulnerabilityCurrent > 0 || victory:
		return false;
	AudioManager.play_effect("Hurt");
	invulnerabilityCurrent = invulnerabilityTimer;
	direction.y /= 2;
	velocity = direction * (1000 + higherBounce * 500);
	velocity.y *= sqrt(fallSpeed);
	coyoteTimeLeft = 0.0;
	if is_on_floor() && !onFloorBypass:
		velocity *= pow(max(3, groundSpeed), .9);
	health -= amount;
	if (health <= 0):
		die();
	else:
		AudioManager.play_effect("Hurt");
	return true;
	
## Kill the player and send the global death signal
func die() -> void:
	health = 0;
	AudioManager.play_effect("PlayerDie");
	currentState = PlayerState.DEAD;

## Remove enemies or projectiles when no longer inside of them
## body: the body or area to remove from the array
func remove_enemy(body: Node2D):
	if enemiesInside.find(body) != -1:
		enemiesInside.remove_at(enemiesInside.find(body));

## use raycast to detect enemy collision
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
			body.take_damage();

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
	jumpAnimStarted = false;
	currentState = PlayerState.JUMPING;
	if (Input.is_action_pressed("jump") && !victory):
		velocity.y = -jumpHeight * 360 * sqrt(fallSpeed);
	else:
		velocity.y = -jumpHeight * 240 * sqrt(fallSpeed);
	coyoteTimeLeft = 0;

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	slidingSticky = false;
	
	
	# Check all collisions with raycasts
	var slideCollisions : Array[RayCast2D] = [];
	var slideCollisionsHit : Array[TileData] = [];
	
	for raycast in raycasts:
		if (raycast.is_colliding()):
			slideCollisions.push_back(raycast);
		
	for raycast in slideCollisions:
		var collider : Object = raycast.get_collider();
		# Moving platform
		if collider is MovingPlatform && is_on_floor():
			if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
				currentState = PlayerState.GROUNDED;
			currentFriction = 1.0;
			currentSlowdown = 1.0;
			currentWalkingEffect = Global.WalkingEffect.GENERAL;
			if collider.momentumShare:
				platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY;
			else:
				platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING;
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
		# Wall jumps not allowed on bedrock or one way tiles
		if wallJump && rayDirection.x != 0 && !(tileName == "bedrock" || tileName == "oneway" || tileName == "bounce"):
			# Wall Slide when not on ice
			if ((rayDirection.x < 0 && (Input.is_action_pressed("left") && !victory) || rayDirection.x > 0 && Input.is_action_pressed("right"))) && !is_on_floor():
				currentState = PlayerState.SLIDING;
				if tileName != "ice":
					velocity.y *= .94;
				if tileName != "slow":
					currentSlowdown = 1.0;
			if (Input.is_action_just_pressed("jump") && !victory) && !is_on_floor():
				currentState = PlayerState.JUMPING;
				# Depending on direction, apply a different x velocity
				if rayDirection.x < 0:
					if wallJumpDirection != WallDirection.LEFT:
						wallJumpCount = 0;
					wallJumpDirection = WallDirection.LEFT;
					velocity.x = 1500 * pow(groundSpeed, .55);
				elif rayDirection.x > 0:
					if wallJumpDirection != WallDirection.RIGHT:
						wallJumpCount = 0;
					wallJumpDirection = WallDirection.RIGHT;
					velocity.x = -1500 * pow(groundSpeed, .55);
				# Remove friction if not on ice
				if tileName != "ice":
					currentFriction = 1.0;
				# Slow down on slow tiles (and on ice, but you normally wall jump faster anyways)
				if tileName == "slow" || tileName == "ice":
					velocity.x /= 1.5;
				wallJumpCount += 1;
				# If the option for decay is turned off, don't decay
				if !wallJumpDecay:
					wallJumpCount = 1;
				velocity.y = -300 * jumpHeight * sqrt(1.0 / wallJumpCount) / pow(min(groundSpeed, 1), .35);;
				justWallJumped = true;

		# Bounce tile collisions
		if (tileName == "bounce"):
			AudioManager.play_effect("BounceTile");
			doubleJumpAvailable = doubleJump;
			currentSlowdown = 1.0;
			# Horizontal bounces
			if (abs(rayDirection.x) > abs(rayDirection.y)):
				if rayDirection.x < 0:
					velocity.x = 3000 * tileLayer.bounceHeight;
				else:
					velocity.x = -3000 * tileLayer.bounceHeight;
				if Input.is_action_pressed("jump") && !victory:
					velocity.y = -500 * tileLayer.bounceHeight;
				# Vertical bounces
			else:
				if (rayDirection.y < 0):
					velocity.y = 1000 * tileLayer.bounceHeight;
				else:
					jumpAnimStarted = false;
					coyoteTime = 0.0;
					currentState = PlayerState.BOUNCING;
					velocity.y = -1000 * sqrt(fallSpeed) * tileLayer.bounceHeight;
					if velocity.x > 0 && Input.is_action_pressed("left") && !victory:
						velocity.x /= 2;
					elif velocity.x < 0 && Input.is_action_pressed("right") && !victory:
						velocity.x /= 2;

		# Sticky Tiles
		elif (tileData && (tileData.get_custom_data("name") == "slow")):
			currentWalkingEffect = Global.WalkingEffect.SLIME;
			currentFriction = 1;
			# Horizontal Stick
			if (abs(raycast.target_position.x) > abs(raycast.target_position.y)):
				velocity.y *= .9;
				slidingSticky = true;
				# Vertical Stick
			## NOTE: Uncomment this to turn on the ability for the player to 'climb' on the bottom of sticky tiles
			else:
			#	if (raycast.target_position.y < 0):
			#		wallJumpDirection = WallDirection.NONE;
			#		velocity.y = 0;
			#		if (Input.is_action_just_pressed("down")):
			#			while raycast.is_colliding():
			#				position += Vector2(0, 1);
			#				raycast.force_raycast_update();
			#		velocity.x = clamp(velocity.x, -trueSpeed * .5, trueSpeed * .5);
				if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
					currentState = PlayerState.GROUNDED
				currentSlowdown = 1 - tileLayer.stickySlowdown;
		elif tileName == "hazard":
			var direction : Vector2 = -raycast.target_position;
			take_damage(1, direction.normalized(), downwardsRaycasts.has(raycast) && Input.is_action_pressed("jump"), true);
		elif tileName == "death":
			take_damage(maxHealth);
		# Only downward rays should drive floor tile effects (except hazard)
		elif downwardsRaycasts.has(raycast):
			if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
				currentState = PlayerState.GROUNDED;
			if tileName != "ice" && tileName != "slow":
				currentWalkingEffect = Global.WalkingEffect.GENERAL;
			if (tileData.get_custom_data("name") != "bounce" && is_on_floor()):
				if (tileData.get_custom_data("name") != "ice"):
					currentFriction = 1.0;
				if (tileData.get_custom_data("name") != "slow"):
					currentSlowdown = 1.0;
			
			match tileName:
				"oneway":
					if Input.is_action_just_pressed("down") && !victory && oneways:
						position += Vector2(0, 1);
				"ice":
					currentWalkingEffect = Global.WalkingEffect.ICE;
					currentFriction = 1 - tileLayer.iceFriction;

## When the player walks/falls out of bounds, force kill them
func check_out_of_bounds() -> bool:
	var masterManager : Node2D = get_tree().current_scene;
	
	# There is a 1 tile leeway given to players who leave bounds, before deth
	if (self.global_position.x < (-1) * Global.TILE_SIZE
	|| self.global_position.x > (masterManager.worldSize.x + 2) * Global.TILE_SIZE
	|| self.global_position.y < (-1) * Global.TILE_SIZE
	|| self.global_position.y > (masterManager.worldSize.y + 2) * Global.TILE_SIZE):
		die();
		return true;
	return false;

## Change the player's state to victory 
func play_victory() -> void:
	if (victory): 
		return;
	victory = true;
	AudioManager.play_effect("Victory");
	animatedSprites.play("PlayerVictory");

## Applies the player selected player movement preset to the player
func apply_preset(preset: PlayerMovementPreset) -> void:
	if (!preset): return;
	
	# Setting all the player variables
	maxHealth = preset.health;
	health = maxHealth
	groundSpeed = preset.groundSpeed;
	baseAcceleration = preset.acceleration / 100.0;
	baseDeceleration = preset.deceleration / 100.0;
	jumpHeight = preset.jumpHeight;
	airControl = preset.airControl / 100.0;
	fallSpeed = preset.fallSpeed;
	coyoteTime = preset.coyoteTime;
	floor_constant_speed = !preset.slopeSlowdown;
	oneways = preset.oneways;
	doubleJump = preset.doubleJump;
	wallJump = preset.wallJump;
	wallJumpDecay = preset.wallJumpDecay;
