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
	WALL_JUMPING,
	FALLING,
	SLIDING,
	BOUNCING,
	TILE_EFFECT_BOUNCE,
	HURT,
	DEAD,
	VICTORY
}

var currentState : PlayerState = PlayerState.GROUNDED;

const STATE_TIMER : float = 1.2;
var stateTimeLeft : float = STATE_TIMER;

# The player settings that can be changed in editor
var groundSpeed : float = 1.0;
var baseAcceleration : float = 1.0;
var baseDeceleration : float = 1.0;
var jumpHeight : float = 2.0;
var doubleJump : bool = false;
var doubleJumpAvailable : bool = doubleJump;

# If the player can drop through oneways
var oneways : bool = true;

# Wall jumping variables, only matter if wallJump is true
var wallJump : bool = false;
var wallJumpCount : int = 0;
var wallJumpDirection : WallDirection = WallDirection.NONE;
var justWallJumped = false;
var wallJumpStrength := 1.0;
var wallJumpDecay = false;

var wallJumpConditionsMet : bool = false;
var wallSlideConditionsMet : bool = false;

# Friction in midair
# BUG: Air Control doesn't work the frame you land on a bouncy tile, allowing you to change direction beofre bouncing back up
var airControl : float = 1.0;
var fallSpeed : float = 1.0;

# Determines how long after leaving a platform you can still jump
var coyoteTime : float = 0.2;

var iceSpeedCap : int = 10;

var coyoteTimeLeft : float = 0;
var isCoyoteActive : bool = false;

var currentWalkingEffect : Global.WalkingEffect;

# Raycasts
@export var raycasts : Array[RayCast2D];
@export var downwardsRaycasts : Array[RayCast2D];
@export var sideRaycasts : Array[RayCast2D];

signal healthChanged(newHealth);
var maxHealth := 3;
var health := maxHealth:
	set(newHealth):
		health = newHealth;
		healthChanged.emit(health);
const INVULNERABILITY_TIMER := 1.5;
var invulnerabilityCurrent := 0.0;

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction : float = 1.0;
var currentSlowdown : float = 1.0;

var jumpBufferTimer : float = 0.075;
var jumpBufferTimerLeft : float = 0.0;

# Player inputs
var moveInput : bool = false;
var jumpInput : bool = false;
var leftInput : bool = false;
var rightInput : bool = false;
var jumpInputHeld : bool = false;
#var jumpInputReleased : bool = false;

# Direction, moved here so the animations can use it as well
var direction : float;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

# Tile effects (bounceTileHeight and iceFriction can be changed once tileProperties exist)
var bounceTileHeight : float = 1.0;
var iceFriction : float = 0.5;
var iceAccelerationFactor : float = .2;

var bounceTimer : float = 0.13;
var bounceTimerLeft : float = 0.0;

var isPlayerGrounded : bool = true;

var tileName : String = "null";

# The selected movement preset
@export var playerMovementPreset : PlayerMovementPreset;

# Enemy collision hitboxes for hooking signals
@export var enemyBounceCollision: Area2D;
@export var enemyCollision: Area2D;

var enemiesInside : Array[Node2D];

# Animation logic
@export var animatedSprites : AnimatedSprite2D;
@onready var jumpTimer : Timer = Timer.new();
var isJumping : bool = false;
var jumpAnimStarted : bool = false;
var fallAnimStarted : bool = false;

var victory : bool = false;

var debugLabel: Label;

# CONSTANTS

const TRUE_SPEED_BASE : int = 400;
# What point falling begins
const FALLING_POINT : float = 0.5;
const JUMP_BASE_HEIGHT : int = 496;

# Movement with Acc/Dec
const FRICTION_ACC_DEC_MAXIMUM : float = 1.25;
const DECELERATION_EXPONENT : int = 5;
const ACCELERATION_EXPONENT : int = 2;
# Clamping acceleration
const ACCELERATION_NO_FRICTION_CLAMPER : float = .5;
const ACCELERATION_FRICTION_CLAMPER : float = .75;

# Wall jump forces
const WALL_JUMP_FORCE_X : int = 1200;
const WALL_JUMP_FORCE_Y : int = 375;
const WALL_JUMP_GROUND_MIN : float = 1.5;
const WALL_JUMP_SPEED_EXPONENT_X : float = 0.8;
const WALL_JUMP_SPEED_EXPONENT_Y : float = 0.35;
const WALL_JUMP_Y_GROUND_MIN : float = 0.3;
const WALL_JUMP_Y_GROUND_MAX : float = 1.0;

# Tile Bases
const SLOW_ICE_SLIDE_JUMP_X : float = 1.2;
const SLOW_WALL_JUMP_Y : float = 1.5;
const SLOW_TILE_SLOWDOWN_Y : float = 0.5;
const BOUNCE_BASE_X : int = 3000;
const BOUNCE_BASE_Y : int = 1000;
const BOUNCE_BASE_Y_SIDE : int = 500;
const WALL_SLIDE_SLOWDOWN : float = 0.94;
const SLIME_NOISE_THRESHOLD : float = 2.5;
const HORIZONTAL_STICK_FACTOR : float = 0.90;

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
	
	if (OS.is_debug_build()):
		debugLabel = Label.new();
		get_tree().current_scene.add_child(debugLabel);
	
	animatedSprites.sprite_frames = AnimationManager.playerTemplateSprite.sprite_frames;
	
	animatedSprites.animation = "PlayerIdle";
	animatedSprites.play();
	
	animatedSprites.animation_finished.connect(on_animation_finished);
	

## Runs every frame during the play state
## delta: How much time has passed
func _physics_process(delta: float) -> void:
	
	if ( check_out_of_bounds() || victory ):
		return;
		
	jumpBufferTimerLeft -= delta;
	if ( Input.is_action_just_pressed("jump") ) :
		jumpBufferTimerLeft = jumpBufferTimer;
	
	bounceTimerLeft -= delta;
		
	# Register player inputs
	jumpInput = jumpBufferTimerLeft > 0;
	#jumpInputReleased = Input.is_action_just_released("jump");
	jumpInputHeld = Input.is_action_pressed("jump");
	leftInput = Input.is_action_pressed("left");
	rightInput = Input.is_action_pressed("right");
	moveInput = (leftInput || rightInput) && !(leftInput && rightInput);
	
	# Detect collision with enemies
	for enemy in enemiesInside:
		detect_enemies(enemy);
	
	# Count down invulnerability
	if (invulnerabilityCurrent > 0):
		invulnerabilityCurrent -= delta;
	
	trueSpeed = groundSpeed * TRUE_SPEED_BASE * currentSlowdown;
	isPlayerGrounded = is_on_floor();
	
	# Coyote time logic
	if (!isPlayerGrounded): 
		currentWalkingEffect = Global.WalkingEffect.NONE;
		velocity += get_gravity() * delta * fallSpeed;
		coyoteTimeLeft -= delta;
	else: 
		doubleJumpAvailable = doubleJump;
		coyoteTimeLeft = coyoteTime;
		wallJumpCount = 0;
	isCoyoteActive = coyoteTimeLeft > 0.0;
	
	# Decide whether player can wall jump and/or wallslide
	resolve_wall_jumping();
	
	# Detect tiles before jumping and running so slow and ice tiles apply affects before inputs
	detect_tiles();
	
	apply_state_logic(delta);
	
	# Move character body & play audio if player state is not VICTORY or DEAD
	if (currentState != PlayerState.VICTORY && currentState != PlayerState.DEAD):
		walk();
		move_and_slide();
		AudioManager.play_effect_walking(currentWalkingEffect);
	#if (OS.is_debug_build()):
		#var debugText : String = "state: %s" % currentState \
								#+ "\n coyote: %s" % isCoyoteActive \
								#+ "\n invul: %f" % invulnerabilityCurrent \
								#+ "\n wallJumpDir: %s" % wallJumpDirection \
								#+ "\n wallJumpCount: %s" % wallJumpCount \
								#+ "\n velocity.x: %f" % velocity.x \
								#+ "\n wallSlideConditions: %s" % wallSlideConditionsMet \
								#+ "\n isGrounded: %s" % isPlayerGrounded \
								#+ "\n justWallJumped: %s" % justWallJumped \
								#+ "\n tileName: %s" % tileName \
								#+ "\n friction: %f" % currentFriction;
		#
		#debugLabel.position = Vector2( position.x - 240, position.y - 180 );
		#debugLabel.text = debugText;


## Handle all state switch & player logic 
## delta: How much time has passed
func apply_state_logic(delta: float) :
	
	# Input based sprite flipping
	var inputBasedAnimDir : bool = currentState != PlayerState.SLIDING \
								&& currentState != PlayerState.DEAD \
								&& currentState != PlayerState.VICTORY \
								&& currentState != PlayerState.WALL_JUMPING;
	
	if (inputBasedAnimDir):
		if (Input.is_action_pressed("right")): 
			animatedSprites.flip_h = false;
		elif (Input.is_action_pressed("left")): 
			animatedSprites.flip_h = true;
	
	match currentState:
		# Grounded state
		PlayerState.GROUNDED:
			wallJumpDirection = WallDirection.NONE;

			if ( isPlayerGrounded ) :
				if ( jumpInput ) :
					set_state( PlayerState.JUMPING );
				elif ( moveInput && groundSpeed != 0 ) :
					set_state( PlayerState.RUNNING );
			else :
				set_state( PlayerState.FALLING );

# Running state
		PlayerState.RUNNING:
			wallJumpDirection = WallDirection.NONE;
			if ( isPlayerGrounded ) :
				if ( jumpInput ) :
					set_state( PlayerState.JUMPING );
				elif ( !moveInput ) : 
					set_state( PlayerState.GROUNDED );
			else :
				set_state( PlayerState.FALLING );
	
# Jumping state
		PlayerState.JUMPING:
			if ( isPlayerGrounded ) :
				if ( moveInput && groundSpeed != 0 ) :
					set_state( PlayerState.RUNNING );
				else :
					set_state( PlayerState.GROUNDED );
			elif ( wallSlideConditionsMet ) :
				set_state( PlayerState.SLIDING );
			elif ( velocity.y > 0.5 ) :
				set_state( PlayerState.FALLING );
			elif ( jumpInput ) :
				if ( wallJumpConditionsMet ) : 
					set_state( PlayerState.WALL_JUMPING );
				elif ( doubleJumpAvailable ) :
					doubleJumpAvailable = false;
					set_state(PlayerState.JUMPING);
			justWallJumped = false;
			
		# Wall jumping state
		PlayerState.WALL_JUMPING:
			if (wallJumpDirection == WallDirection.LEFT && velocity.x > 0):
				animatedSprites.flip_h = false;
			if (wallJumpDirection == WallDirection.RIGHT && velocity.x < 0):
				animatedSprites.flip_h = true;
			stateTimeLeft -= delta;

			# Code for if the state has changed (landing, falling off wall, or wall jumping)
			if ( isPlayerGrounded ) :
				if ( moveInput && groundSpeed != 0 ) :
					set_state( PlayerState.RUNNING );
				else :
					set_state( PlayerState.GROUNDED );
				#retainWallJumpAnimDir();
			elif ( wallSlideConditionsMet && !justWallJumped ) :
				set_state( PlayerState.SLIDING );
				#retainWallJumpAnimDir();
			elif ( velocity.y > 0.5 ) :
				set_state( PlayerState.FALLING );
				#retainWallJumpAnimDir();
			elif ( jumpInput && !justWallJumped ) :
				if ( wallJumpConditionsMet ) : 
					set_state( PlayerState.WALL_JUMPING );
				elif ( doubleJumpAvailable ) :
					doubleJumpAvailable = false;
					set_state(PlayerState.JUMPING);
			elif (stateTimeLeft <= 0.0):
				currentState = PlayerState.JUMPING;
			justWallJumped = false;
		
		# Falling state
		PlayerState.FALLING:
			if ( isCoyoteActive ) :
				if ( jumpInput ) :
					set_state( PlayerState.JUMPING );
			if ( isPlayerGrounded ) :
				if ( moveInput && groundSpeed != 0 ) :
					set_state( PlayerState.RUNNING );
				else : 
					set_state ( PlayerState.GROUNDED );
			elif ( wallSlideConditionsMet ) :
				set_state( PlayerState.SLIDING );
			elif ( jumpInput ) :
				if ( wallJumpConditionsMet ) : 
					set_state( PlayerState.WALL_JUMPING );
				elif ( doubleJumpAvailable ) :
					doubleJumpAvailable = false;
					set_state(PlayerState.JUMPING);
		
		# Wall sliding state
		PlayerState.SLIDING:
			if ( jumpInput ) :
				set_state( PlayerState.WALL_JUMPING );
			elif ( !wallSlideConditionsMet ) :
				if ( isPlayerGrounded ) :
					if ( moveInput && groundSpeed != 0 ) : 
						set_state( PlayerState.RUNNING );
					else :
						set_state( PlayerState.GROUNDED );
				else :
					set_state( PlayerState.FALLING );
		
		# Hurt state
		PlayerState.HURT:
			invulnerabilityCurrent -= delta;
	
			if (health <= 0):
				set_state( PlayerState.DEAD );
			elif (invulnerabilityCurrent <= 0.0):
				if (isPlayerGrounded):
					if (moveInput): 
						set_state(PlayerState.RUNNING);
					else:
							set_state(PlayerState.GROUNDED);
				else:
					set_state(PlayerState.FALLING);
		# Dead state
		PlayerState.DEAD:
			velocity = Vector2.ZERO;
			animatedSprites.flip_h = false;
		# Victory state
		PlayerState.VICTORY:
			animatedSprites.flip_h = false;

## Handle the setup for entering a new player state
## state: The player state to transition into
## function: a callable function that to be used during state transitions, right now only used with HURT
func set_state(state : PlayerState, function : Callable = Callable()) -> void:
	
	stateTimeLeft = STATE_TIMER;
	animatedSprites.frame = 0;

	match state:
		PlayerState.GROUNDED:
			doubleJumpAvailable = doubleJump;
			animatedSprites.play("PlayerIdle");
			currentState = PlayerState.GROUNDED;
		
		PlayerState.RUNNING :
			if ( groundSpeed == 0 ) :
				return;
			doubleJumpAvailable = doubleJump;
			animatedSprites.play("PlayerRun");
			currentState = PlayerState.RUNNING;
			
		PlayerState.JUMPING:
			jumpInput = false;
			coyoteTimeLeft = 0.0;
			jumpBufferTimerLeft = 0.0;
			jump();
			AudioManager.play_effect("Jump");
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.JUMPING;
			
		PlayerState.WALL_JUMPING:
			jumpBufferTimerLeft = 0.0;
			wall_jump();
			if (wallJumpDirection == WallDirection.RIGHT): 
				animatedSprites.flip_h = false;
			elif (wallJumpDirection == WallDirection.LEFT): 
				animatedSprites.flip_h = true;
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.WALL_JUMPING;
			
		PlayerState.FALLING:
			animatedSprites.play("PlayerFall");
			currentState = PlayerState.FALLING;
			
		PlayerState.BOUNCING:
			bounce();
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.JUMPING;
			
		PlayerState.SLIDING:
			animatedSprites.flip_h = wallJumpDirection == WallDirection.RIGHT;
			animatedSprites.play("PlayerWallSlide");
			currentState = PlayerState.SLIDING;
			
		PlayerState.TILE_EFFECT_BOUNCE:
			if ( bounceTimerLeft <= 0.0 ) :
				AudioManager.play_effect("BounceTile");
				bounceTimerLeft = bounceTimer;
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.JUMPING;
			
		PlayerState.HURT:
			if (currentState == PlayerState.HURT || currentState == PlayerState.DEAD):
				return;
			function.call();
			if (health > 0) :
				AudioManager.play_effect("Hurt");
			invulnerabilityCurrent = INVULNERABILITY_TIMER;
			animatedSprites.play("PlayerHurt");
			animatedSprites.flip_h = velocity.x > 0;
			currentState = PlayerState.HURT;
			
		PlayerState.DEAD:
			velocity = Vector2.ZERO;
			currentWalkingEffect = Global.WalkingEffect.NONE;
			AudioManager.play_effect("PlayerDie");
			animatedSprites.play("PlayerDeath");
			animatedSprites.flip_h = false;
			currentState = PlayerState.DEAD;
			die();
			
		PlayerState.VICTORY:
			victory = true;
			AudioManager.play_effect("Victory");
			animatedSprites.play("PlayerVictory");
			animatedSprites.flip_h = false;
			currentState = PlayerState.VICTORY;

## Event for when an animation is done playing
func on_animation_finished() -> void:
	if (animatedSprites.animation == "PlayerDeath"):
		Global.death.emit();
		
	elif (animatedSprites.animation == "PlayerVictory"):
		await get_tree().create_timer(1.0).timeout;
		Global.complete.emit();

## Make the player jump
func jump() -> void:
	isPlayerGrounded = false;
	velocity.y = -sqrt(jumpHeight) * JUMP_BASE_HEIGHT * currentSlowdown * sqrt(fallSpeed);

## Handle left and right movement logic, with the inclusion of if there is no input
func walk() -> void:
	# Acceration in the X direction for the player
	var accelerationX : float;
	
	if (!victory && groundSpeed != 0):
		direction = Input.get_axis("left", "right");
	else:
		direction = 0;
		
	# If a direction is pressed, move in the direction, otherwise decelerate towards a 0 velocity 
	if (direction):
		accelerationX = direction * trueSpeed;
		# Acceleration if moving in direction of current movement
		if (baseAcceleration != 1.0 && (sign(velocity.x) == sign(direction) || velocity.x == 0)):
			accelerationX = direction * pow(abs(accelerationX), pow(baseAcceleration, ACCELERATION_EXPONENT));
			if (baseAcceleration + currentFriction < FRICTION_ACC_DEC_MAXIMUM):
				currentFriction = FRICTION_ACC_DEC_MAXIMUM - baseAcceleration
		# Deceleration if moving in opposite direction
		elif (baseDeceleration != 1.0 && sign(velocity.x) != sign(direction)):
			if (baseDeceleration + currentFriction < FRICTION_ACC_DEC_MAXIMUM):
				currentFriction = FRICTION_ACC_DEC_MAXIMUM - baseDeceleration
			accelerationX *= pow(baseDeceleration, DECELERATION_EXPONENT);
	# Acceleration
	else:
		currentWalkingEffect = Global.WalkingEffect.NONE;
		if (currentFriction != 1.0):
			accelerationX = clamp(-velocity.x, -trueSpeed * ACCELERATION_NO_FRICTION_CLAMPER, trueSpeed * ACCELERATION_NO_FRICTION_CLAMPER);
		else:
			accelerationX = clamp(-velocity.x, -max(trueSpeed, TRUE_SPEED_BASE) * ACCELERATION_FRICTION_CLAMPER, max(trueSpeed, TRUE_SPEED_BASE) * ACCELERATION_FRICTION_CLAMPER);
		# Deceleration if not moving
		if (baseDeceleration != 1.0):
			accelerationX *= pow(baseDeceleration, 5);
		# Clamping if velocity is too low
		if (abs(velocity.x) < 10 * groundSpeed):
			accelerationX = -velocity.x;
	# Air Control
	if (!isPlayerGrounded):
		accelerationX *= airControl * airControl;

	# Friction while on ice
	if (currentFriction != 1.0 && isPlayerGrounded):
		accelerationX *= currentFriction * currentFriction * currentFriction;
		# If above maximum ice speed, slow down gradually
		if (abs(velocity.x) > trueSpeed * iceSpeedCap):
			accelerationX = 0;
			velocity.x *= .9;
		# If above top ground speed, continue speeding up at a slower rate.
		elif (abs(velocity.x) > trueSpeed):
			if (velocity.x < 0 && accelerationX < 0) || (velocity.x > 0 && accelerationX > 0):
				accelerationX *= iceAccelerationFactor;
	elif (currentFriction != 1.0 && !isPlayerGrounded):
		if (direction / velocity.x > 0 && abs(velocity.x + accelerationX * .1) > trueSpeed):
			accelerationX = 0;
		else:
			if (airControl != 0):
				accelerationX *= .05 / pow(airControl, 2);
			else:
				accelerationX *= .05;
		
	# Velocity gets capped so you can't accelerate faster when on normal ground
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
## damageDirection: direction to deal damage in
## higherBounce: if the player should bounce higher
## onFloorBypass: If true, the player is NOT on the floor for knockback
func take_damage(amount: int, damageDirection: Vector2 = Vector2(0, 0), higherBounce : int = 0, onFloorBypass : bool = false) -> void:
	invulnerabilityCurrent = INVULNERABILITY_TIMER;
	damageDirection.y /= 2;
	velocity = damageDirection * (1000 + higherBounce * 500);
	velocity.y *= sqrt(fallSpeed);
	coyoteTimeLeft = 0.0;
	if (isPlayerGrounded && !onFloorBypass):
		velocity *= pow(max(3, groundSpeed), .9);
	health -= amount;
	
## Kill the player and send the global death signal
func die() -> void:
	health = -1;

## Remove enemies or projectiles when no longer inside of them
## body: the body or area to remove from the array
func remove_enemy(body: Node2D):
	if (enemiesInside.find(body) != -1):
		enemiesInside.remove_at(enemiesInside.find(body));

## use raycast to detect enemy collision
## body: the body detected to test for being an enemy
func detect_enemies(body: Node2D) -> void:
	if (currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY) :
		return;
	# Wait one frame to see if the enemy has been killed by getting landed on, if so then don't take damage
	await get_tree().process_frame;
	
	# Take damage
	if (body && body.is_in_group("enemy")):
		var enemyDirection : Vector2 = position - body.position;
		if (enemiesInside.find(body) == -1):
			enemiesInside.append(body);
		# Hurt Player
		set_state(PlayerState.HURT, take_damage.bind(1, enemyDirection.normalized()));

## Detect collisions between enemies and the bounce area
## body: the body being collided with
func detect_enemy_bounce(body: Node2D) -> void:
	if (currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY):
		return;
	if (body.is_in_group("enemy")):
		if (velocity.y > 0 || body.velocity.y - velocity.y <= 0):
			set_state(PlayerState.BOUNCING);
			body.take_damage();

## Detect collisions with projectiles
## area: the area being collided with
func detect_projectiles(area: Area2D) -> void:
	if (currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY):
		return;
	# Wait one frame to see if the projectile has been bounced on
	await get_tree().process_frame;
	if (area && area.is_in_group("Projectile")):
		var projectileDirection : Vector2 = position - area.position;
		# Hurt Player
		set_state(PlayerState.HURT, take_damage.bind(1, projectileDirection.normalized(), 0, true));
		area.queue_free();

## Detect collisions between projectiles and the bounce area
## area: the area being collided with
func detect_projectile_bounce(area: Area2D) -> void:

	if (currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY):
		return;
	if (area.is_in_group("Projectile")):
		if (area.bounceable):
			set_state(PlayerState.BOUNCING);
		else:
			var projectileDirection : Vector2 = position - area.position;
			# Hurt Player
			set_state(PlayerState.HURT, take_damage.bind(1, projectileDirection.normalized(), 0, true));
		area.queue_free();

## Bounce the player up
func bounce() -> void:
	if (jumpInputHeld):
		velocity.y = -jumpHeight * 360 * sqrt(fallSpeed);
	else:
		velocity.y = -jumpHeight * 240 * sqrt(fallSpeed);
	coyoteTimeLeft = 0.0;
	
## Detect walls to either side of player and check for wall jump and slide conditions
func resolve_wall_jumping() -> void:
	
	wallJumpConditionsMet = false;
	wallSlideConditionsMet = false;
	
	# Bail is grounded or walljump feature is diabled
	if ( isPlayerGrounded || !wallJump || justWallJumped ): return;
	
	var sideWallCollisions : Array[RayCast2D] = [];
	var sideWallCollisionsHit : Array[TileData] = [];
	
	# Check all 3 right and left raycasts to check collision against wall
	for sideRay in sideRaycasts:
		if (sideRay.is_colliding()):
			sideWallCollisions.push_back(sideRay);
	
	for sideRay in sideWallCollisions:
		var collider : Object = sideRay.get_collider();
		if !(collider is TileMapLayer): continue;
		var tileLayer : TileMapLayer = collider;
		
		var hitGlobal : Vector2 = sideRay.get_collision_point();
		var hitNormal : Vector2 = sideRay.get_collision_normal();
		var probeGlobal : Vector2 = hitGlobal - hitNormal * 0.5;
		var probeLocal : Vector2 = tileLayer.to_local(probeGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		
		if (!tileData || sideWallCollisionsHit.find(tileData) > -1):
			continue;
		sideWallCollisionsHit.push_back(tileData);
		tileName = tileData.get_custom_data("name");
		var rayDirection : Vector2 = sideRay.target_position;
		
		# Wall jumps not allowed on bedrock or one way tiles
		if (tileName == "bedrock" || tileName == "oneway" || tileName == "bounce"):
			return;
			
		wallJumpConditionsMet = true;
		
		# decide wall jump direction & count
		if (rayDirection.x > 0): 
			if (wallJumpDirection != WallDirection.LEFT):
				wallJumpCount = 0;
			wallJumpDirection = WallDirection.LEFT;
			
		if (rayDirection.x < 0): 
			if (wallJumpDirection != WallDirection.RIGHT):
				wallJumpCount = 0;
			wallJumpDirection = WallDirection.RIGHT;

		# If no input pressed wall slide is false
		if !((Input.is_action_pressed("left") && rayDirection.x < 0 ) || ( Input.is_action_pressed("right") && rayDirection.x > 0)): 
			return;
			
		wallSlideConditionsMet = true;

## Make the player wall jump
func wall_jump():
	if (wallJumpDirection == WallDirection.NONE): 
		return;
	
	wallJumpCount += 1;
	if !(wallJumpDecay):
		wallJumpCount = 1;
		
	if (wallJumpDirection == WallDirection.RIGHT):
		velocity.x = WALL_JUMP_FORCE_X * pow(max(groundSpeed, WALL_JUMP_GROUND_MIN), WALL_JUMP_SPEED_EXPONENT_X) * wallJumpStrength;
	else:
		velocity.x = -WALL_JUMP_FORCE_X * pow(max(groundSpeed, WALL_JUMP_GROUND_MIN), WALL_JUMP_SPEED_EXPONENT_X) * wallJumpStrength;
	velocity.y = -WALL_JUMP_FORCE_Y * jumpHeight * sqrt(1.0 / wallJumpCount) / pow(clamp(groundSpeed, WALL_JUMP_Y_GROUND_MIN, WALL_JUMP_Y_GROUND_MAX), WALL_JUMP_SPEED_EXPONENT_Y);
	
	var iceXSpeedScale : float = 1.75;
	# Slow down on slow tiles (and on ice, but you normally wall jump faster anyways)
	if (tileName == "slow" || tileName == "ice"):
		velocity.x /= ( SLOW_ICE_SLIDE_JUMP_X * iceXSpeedScale );
	if (tileName == "slow") :
		velocity.y /= SLOW_WALL_JUMP_Y;
		currentFriction = 1.0;
	if (tileName == "solid") :
		currentFriction = 1.0;
		
	justWallJumped = true;

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	if (currentState == PlayerState.VICTORY || currentState == PlayerState.DEAD):
		return;
		
	# Check all collisions with raycasts
	var slideCollisions : Array[RayCast2D] = [];
	var slideCollisionsHit : Array[TileData] = [];
	
	for raycast in raycasts:
		if (raycast.is_colliding()):
			slideCollisions.push_back(raycast);
		
	for raycast in slideCollisions:
		var collider : Object = raycast.get_collider();
		# Moving platform (It's not on the tilemap but still works like a solid tile)
		if (collider is MovingPlatform && isPlayerGrounded):
			currentFriction = 1.0;
			currentSlowdown = 1.0;
			currentWalkingEffect = Global.WalkingEffect.GENERAL;
			if (collider.momentumShare):
				platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY;
			else:
				platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING;
		if !(collider is TileMapLayer): continue;
		
		var tileLayer : TileMapLayer = collider;
		
		var hitGlobal : Vector2 = raycast.get_collision_point();
		var hitNormal : Vector2 = raycast.get_collision_normal();
		var probeGlobal : Vector2 = hitGlobal - hitNormal * 0.5;
		var probeLocal : Vector2 = tileLayer.to_local(probeGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		
		if !(tileData || slideCollisionsHit.find(tileData) > -1):
			continue;
		slideCollisionsHit.push_back(tileData);
		tileName = tileData.get_custom_data("name");
		var rayDirection : Vector2 = raycast.target_position;

		# Only create wallslide friction if tile is not ice
		if ( wallSlideConditionsMet && groundSpeed != 0 ):
			if tileName != "ice" && tileName != "oneway":
				velocity.y *= WALL_SLIDE_SLOWDOWN;
			if tileName != "slow":
				currentSlowdown = 1.0;
				
		if (wallJumpConditionsMet) :
			if (tileName == "ice") :
				currentFriction = iceFriction;
			else :
				currentFriction = 1.0;

		# Bounce tile collisions
		if (tileName == "bounce"):
			isPlayerGrounded = false;
			wallJumpCount = 0;
			currentSlowdown = 1.0;
			set_state(PlayerState.TILE_EFFECT_BOUNCE);
			# Horizontal bounces
			if (abs(rayDirection.x) > abs(rayDirection.y)):
				if (rayDirection.x < 0):
					velocity.x = BOUNCE_BASE_X * bounceTileHeight;
				else:
					velocity.x = -BOUNCE_BASE_X * bounceTileHeight;
				if (jumpInput) :
					velocity.y = -BOUNCE_BASE_Y_SIDE * bounceTileHeight;
			# Vertical bounces
			else:
				if (rayDirection.y < 0):
					velocity.y = BOUNCE_BASE_Y * bounceTileHeight;
				else:
					doubleJumpAvailable = doubleJump;
					coyoteTimeLeft = 0.0;
					velocity.y = -BOUNCE_BASE_Y * sqrt(fallSpeed) * bounceTileHeight;
					if ( velocity.x > 0 && leftInput && groundSpeed!=0 ) :
						velocity.x /= 2;
					elif ( velocity.x < 0 && rightInput && groundSpeed!=0 ) :
						velocity.x /= 2;
			
		# Sticky Tiles
		elif (tileData && (tileData.get_custom_data("name") == "slow")):
			if ((rayDirection.y > 0 && abs(get_real_velocity().x) > SLIME_NOISE_THRESHOLD) || wallSlideConditionsMet):
				currentWalkingEffect = Global.WalkingEffect.SLIME;
				currentFriction = 1;
				currentSlowdown = SLOW_TILE_SLOWDOWN_Y;
		
			# Horizontal Stick
			if (abs(raycast.target_position.x) > abs(raycast.target_position.y)):
				velocity.y *= HORIZONTAL_STICK_FACTOR;
				currentSlowdown = SLOW_TILE_SLOWDOWN_Y;
				#slidingSticky = true;
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
				#if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
					#currentState = PlayerState.GROUNDED
				currentSlowdown = SLOW_TILE_SLOWDOWN_Y;
		
		# Hazard tile
		elif (tileName == "hazard"):
			var hazardDirection : Vector2 = -raycast.target_position;
			# Hurt Player
			if (currentState != PlayerState.HURT && currentState != PlayerState.DEAD):
				set_state( PlayerState.HURT, take_damage.bind(1, hazardDirection.normalized(), downwardsRaycasts.has(raycast) && Input.is_action_pressed("jump"), true) );
		
		# Death tile
		elif (tileName == "death"):
			# Kill Player
			if (currentState != PlayerState.DEAD):
				set_state(PlayerState.DEAD);
		# Only downward rays should drive floor tile effects (except hazard)
		elif (downwardsRaycasts.has(raycast)):
			if (tileName != "ice" && tileName != "slow"):
				currentWalkingEffect = Global.WalkingEffect.GENERAL;
			if (tileData.get_custom_data("name") != "bounce" && isPlayerGrounded):
				if (tileData.get_custom_data("name") != "ice"):
					currentFriction = 1.0;
				if (tileData.get_custom_data("name") != "slow"):
					currentSlowdown = 1.0;
			
			match tileName:
				"oneway":
					if (Input.is_action_just_pressed("down") && isPlayerGrounded && oneways):
						position += Vector2(0, 1);
						for downRay in downwardsRaycasts:
							if (position.y > downRay.get_collision_point().y): 
								isPlayerGrounded = false;
				"ice":
					currentWalkingEffect = Global.WalkingEffect.ICE;
					currentFriction = iceFriction;

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
	set_state( PlayerState.VICTORY );

## Applies the player selected player movement preset to the player
## preset: The preset to apply to the player
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
	wallJumpStrength = preset.wallJumpStrength;
	wallJumpDecay = preset.wallJumpDecay;
