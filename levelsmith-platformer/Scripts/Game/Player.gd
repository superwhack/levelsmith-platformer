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
	HURT,
	DEAD,
	VICTORY
}

var currentState : PlayerState = PlayerState.GROUNDED;

var stateTimer : float = 1.5;
var stateTimeLeft : float = stateTimer;

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

var wallJumpConditionsMet : bool = false;
var wallSlideConditionsMet : bool = false;

# Friction in midair
# BUG: Air Control doesn't work the frame you land on a bouncy tile, allowing you to change direction beofre bouncing back up
@export var airControl : float = 1.0;
@export var fallSpeed : float = 1.0;

# Determines how long after leaving a platform you can still jump
@export var coyoteTime : float = 0.2;

@export var iceSpeedCap : int = 10;

var coyoteTimeLeft : float = 0;
var isCoyoteActive : bool = false;

# TODO: Make FPS dependant on a global FPS initailly instead of being set to 24
# TODO: Impliment animations and use this
@export var FPS : int = 24;

var spawnpoint : Vector2 = Vector2(0, 0);
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
const invulnerabilityTimer := 1.5;
var invulnerabilityCurrent := 0.0;

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction : float = 1.0;
var currentSlowdown : float = 1.0;
var slidingSticky : bool = false;

# Player inputs
var moveInput : bool = false;
var jumpInput : bool = false;
var leftInput : bool = false;
var rightInput : bool = false;
var jumpInputHeld : bool = false;
var jumpInputReleased : bool = false;

# Direction, moved here so the animations can use it as well
var direction : float;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

var bounceTileHeight : float = 1.0;
var iceFriction : float = 0.5;

var iceAccelerationFactor : float = .25;

var isPlayerGrounded : bool = true;

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

#var debugLabel: Label

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
	
	#for animationName in animatedSprites.sprite_frames.get_animation_names():
		#AnimationManager.replace_animation_by_name(animatedSprites, animationName);
	
	#debugLabel = Label.new();
	#debugLabel.position = Vector2(10, 10);
	
	#get_tree().current_scene.add_child(debugLabel);
	
	animatedSprites.sprite_frames = AnimationManager.playerTemplateSprite.sprite_frames;
	
	animatedSprites.animation = "PlayerIdle";
	animatedSprites.play();
	
	animatedSprites.animation_finished.connect(on_animation_finished);
	

## Runs every frame during the play state
## delta: How much time has passed
func _physics_process(delta: float) -> void:
	
	if ( check_out_of_bounds() || victory ):
		return;
		
	# Register player inputs
	jumpInput = Input.is_action_just_pressed("jump");
	jumpInputReleased = Input.is_action_just_released("jump");
	jumpInputHeld = Input.is_action_pressed("jump");
	leftInput = Input.is_action_pressed("left");
	rightInput = Input.is_action_pressed("right");
	moveInput = ( leftInput || rightInput ) && !( leftInput && rightInput );
	
	# Detect collision with enemies
	for enemy in enemiesInside:
		detect_enemies(enemy);
	
	# Count down invulnerability
	if ( invulnerabilityCurrent > 0 ):
		invulnerabilityCurrent -= delta;
	
	trueSpeed = groundSpeed * 400 * currentSlowdown;
	isPlayerGrounded = is_on_floor();
	
	# Coyote time logic
	if ( !isPlayerGrounded ): 
		currentWalkingEffect = Global.WalkingEffect.NONE;
		velocity += get_gravity() * delta * fallSpeed;
		coyoteTimeLeft -= delta;
	else : 
		doubleJumpAvailable = doubleJump;
		coyoteTimeLeft = coyoteTime;
		wallJumpCount = 0;
	
	isCoyoteActive = coyoteTimeLeft > 0.0;
	
	# Decide whether player can wall jump and/or wallslide
	resolve_wall_jumping();
	
	# Detect tiles before jumping and running so slow and ice tiles apply affects before inputs
	detect_tiles();
	
	apply_state_logic( delta );
	
	# Move character body & play audio if player state is not VICTORY or DEAD
	if ( currentState != PlayerState.DEAD || currentState != PlayerState.VICTORY ):
		move_and_slide();
		AudioManager.play_effect_walking(currentWalkingEffect);
	
	#var debugText : String = "state: %s" % currentState \
							#+ "\n coyote: %f" % coyoteTimeLeft \
							#+ "\n invul: %f" % invulnerabilityCurrent \
							#+ "\n wallJumpDir: %s" % wallJumpDirection \
							#+ "\n wallJumpCount: %s" % wallJumpCount \
							#+ "\n velocity.x: %f" % velocity.x;
	#
	#debugLabel.position = Vector2( position.x - 148, position.y - 170 );
	#debugLabel.text = debugText;
	
	
	
	
			
func apply_state_logic( delta: float ) :
	
		# Input based sprite flipping
	var inputBasedAnimDir : bool = currentState != PlayerState.SLIDING \
								&& currentState != PlayerState.DEAD \
								&& currentState != PlayerState.VICTORY \
								&& currentState != PlayerState.WALL_JUMPING;
	
	if ( inputBasedAnimDir ) :
		if ( Input.is_action_pressed("right") ): animatedSprites.flip_h = false;
		elif ( Input.is_action_pressed("left") ): animatedSprites.flip_h = true;
	
	match currentState:
# GROUNDED STATE
		PlayerState.GROUNDED:
			walk();
			wallJumpDirection = WallDirection.NONE;
			if ( isPlayerGrounded ) :
				if ( moveInput ) : 
					set_state( PlayerState.RUNNING );
				elif ( jumpInput ) :
					set_state( PlayerState.JUMPING );
			else :
				set_state( PlayerState.FALLING );

# RUNNING STATE
		PlayerState.RUNNING:
			walk();
			if ( isPlayerGrounded ) :
				if ( !moveInput ) : 
					set_state( PlayerState.GROUNDED );
				elif ( jumpInput ) :
					set_state( PlayerState.JUMPING );
			else :
				set_state( PlayerState.FALLING );
	
# JUMPING STATE
		PlayerState.JUMPING:
			walk();
			if ( isPlayerGrounded ) :
				if ( !moveInput ) : 
					set_state( PlayerState.GROUNDED );
				else :
					set_state( PlayerState.RUNNING );
			elif ( wallSlideConditionsMet ) :
				set_state( PlayerState.SLIDING );
			elif ( velocity.y > 0.5 ) :
				set_state( PlayerState.FALLING );
			elif ( jumpInput ) :
				if ( wallJumpConditionsMet ) : 
					set_state( PlayerState.WALL_JUMPING );
				elif ( doubleJumpAvailable ) :
					currentSlowdown = 1.0;
					doubleJumpAvailable = false;
					set_state( PlayerState.JUMPING );
			justWallJumped = false;
			
# WALL JUMPING STATE
		PlayerState.WALL_JUMPING:
			stateTimeLeft -= delta;
			
			walk();
			if ( isPlayerGrounded ) :
				if ( !moveInput ) : 
					set_state( PlayerState.GROUNDED );
				else :
					set_state( PlayerState.RUNNING );
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
					currentSlowdown = 1.0;
					doubleJumpAvailable = false;
					set_state( PlayerState.JUMPING );
				#retainWallJumpAnimDir();
			elif ( stateTimeLeft <= 0.0 ) :
				currentState = PlayerState.JUMPING;
				#retainWallJumpAnimDir();
			justWallJumped = false;
			
	
# FALLING STATE
		PlayerState.FALLING:
			walk();
			if ( isCoyoteActive ) :
				if ( jumpInput ) :
					set_state( PlayerState.JUMPING );
			if ( isPlayerGrounded ) :
				if ( moveInput ) : 
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
					set_state( PlayerState.JUMPING );
					
# WALL SLIDING STATE
		PlayerState.SLIDING:
			walk();
			if ( jumpInput ) :
				set_state( PlayerState.WALL_JUMPING );
			elif ( !wallSlideConditionsMet ) :
				if ( isPlayerGrounded ) :
					if ( moveInput ) : 
						set_state( PlayerState.RUNNING );
					elif ( jumpInput ) :
						set_state( PlayerState.JUMPING );
				else :
					set_state( PlayerState.FALLING );
# HURT STATE
		PlayerState.HURT:
			walk();
			invulnerabilityCurrent -= delta;
	
			if ( health <= 0 ) :
				set_state( PlayerState.DEAD );
			elif ( invulnerabilityCurrent <= 0.0 ) :
				if ( isPlayerGrounded ) :
					if ( moveInput ) : 
						set_state( PlayerState.RUNNING );
					else :
							set_state( PlayerState.GROUNDED );
				else :
					set_state( PlayerState.FALLING );
# DEAD STATE
		PlayerState.DEAD:
			velocity = Vector2.ZERO;
			# Animation
			animatedSprites.flip_h = false;
# VICTORY STATE
		PlayerState.VICTORY:
			# Animation
			animatedSprites.flip_h = false;
	

func retainWallJumpAnimDir() :
	if ( wallJumpDirection == WallDirection.RIGHT ): animatedSprites.flip_h = true;
	elif ( wallJumpDirection == WallDirection.LEFT ) : animatedSprites.flip_h = false;

func set_state( state : PlayerState, function : Callable = Callable()) -> void:
	
	stateTimeLeft = stateTimer;
	animatedSprites.frame = 0;

	match state:
		PlayerState.GROUNDED :
			doubleJumpAvailable = doubleJump;
			animatedSprites.play("PlayerIdle");
			currentState = PlayerState.GROUNDED;
			print( "set_state GROUNDED" );
			
		PlayerState.RUNNING :
			doubleJumpAvailable = doubleJump;
			animatedSprites.play("PlayerRun");
			currentState = PlayerState.RUNNING;
			print( "set_state RUNNING" );
			
		PlayerState.JUMPING :
			jumpInput = false;
			coyoteTimeLeft = 0.0;
			jump();
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.JUMPING;
			print( "set_state JUMPING" );
			
		PlayerState.WALL_JUMPING :
			wall_jump();
			#Animation
			if ( wallJumpDirection == WallDirection.RIGHT ): animatedSprites.flip_h = false;
			elif ( wallJumpDirection == WallDirection.LEFT ) : animatedSprites.flip_h = true;
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.WALL_JUMPING;
			print( "set_state WALL JUMPING" );
			
		PlayerState.FALLING :
			animatedSprites.play("PlayerFall");
			currentState = PlayerState.FALLING;
			print( "set_state FALLING" );
			
		PlayerState.BOUNCING :
			bounce();
			animatedSprites.play("PlayerJump");
			currentState = PlayerState.JUMPING;
			print( "set_state BOUNCING ( JUMPING )" );
			
		PlayerState.SLIDING :
			# Animation
			if ( wallJumpDirection == WallDirection.RIGHT ): animatedSprites.flip_h = true;
			else : animatedSprites.flip_h = false;
			animatedSprites.play("PlayerWallSlide");
			currentState = PlayerState.SLIDING;
			print( "set_state SLIDING" );
			
		PlayerState.HURT :
			currentState = PlayerState.HURT;
			function.call();
			invulnerabilityCurrent = invulnerabilityTimer;
			animatedSprites.play("PlayerHurt");
			animatedSprites.flip_h = velocity.x > 0;
			print( "set_state HURT" );
			
		PlayerState.DEAD :
			velocity = Vector2.ZERO;
			currentWalkingEffect = Global.WalkingEffect.NONE;
			animatedSprites.play("PlayerDeath");
			animatedSprites.flip_h = false;
			currentState = PlayerState.DEAD;
			print( "set_state DEAD" );
			die();
			
		PlayerState.VICTORY :
			currentState = PlayerState.VICTORY;
			animatedSprites.animation == "PlayerVictory";
			animatedSprites.flip_h = false;
			print( "set_state VICTORY" );

## Event for 
func on_animation_finished() -> void:
	if (animatedSprites.animation == "PlayerDeath"):
		Global.death.emit();
		
	elif (animatedSprites.animation == "PlayerVictory"):
		await get_tree().create_timer(1.0).timeout;
		Global.complete.emit();

## Make the player jump
func jump() -> void:
	isPlayerGrounded = false;
	AudioManager.play_effect("Jump");
	velocity.y = -sqrt(jumpHeight) * 496 * currentSlowdown * sqrt(fallSpeed);

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
		if ( !slidingSticky ):
			currentWalkingEffect = Global.WalkingEffect.NONE;
		if ( currentFriction != 1.0 ):
			accelerationX = clamp(-velocity.x, -trueSpeed * .5, trueSpeed * .5);
		else:
			accelerationX = clamp(-velocity.x, -max(trueSpeed, 400) * .75, max(trueSpeed, 400) * .75);
		# Deceleration if not moving
		if ( baseDeceleration != 1.0 ):
			accelerationX *= pow(baseDeceleration, 5);
		# Clamping if velocity is too low
		if abs( velocity.x ) < 10 * groundSpeed:
			accelerationX = -velocity.x;
	# Air Control
	if ( !isPlayerGrounded ):
		accelerationX *= airControl * airControl;

	# Friction while on ice
	if ( currentFriction != 1.0 && isPlayerGrounded ):
		accelerationX *= currentFriction * currentFriction * currentFriction;
		if ( abs( velocity.x ) > trueSpeed * iceSpeedCap ):
			accelerationX = 0;
			velocity.x *= .9;
		elif ( abs( velocity.x ) > trueSpeed ):
			if ( velocity.x < 0 && accelerationX < 0 ) || ( velocity.x > 0 && accelerationX > 0 ):
				accelerationX *= iceAccelerationFactor;
	elif ( currentFriction != 1.0 && !isPlayerGrounded ):
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
	invulnerabilityCurrent = invulnerabilityTimer;
	direction.y /= 2;
	velocity = direction * (1000 + higherBounce * 500);
	velocity.y *= sqrt(fallSpeed);
	coyoteTimeLeft = 0.0;
	if ( isPlayerGrounded && !onFloorBypass ):
		velocity *= pow(max(3, groundSpeed), .9);
	health -= amount;
	AudioManager.play_effect("Hurt");
	return true;
	
## Kill the player and send the global death signal
func die() -> void:
	health = -1;
	AudioManager.play_effect("PlayerDie");

## Remove enemies or projectiles when no longer inside of them
## body: the body or area to remove from the array
func remove_enemy(body: Node2D):
	if enemiesInside.find(body) != -1:
		enemiesInside.remove_at(enemiesInside.find(body));

## use raycast to detect enemy collision
func detect_enemies(body: Node2D) -> void:
	if ( currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY ) :
			return;
	# Wait one frame to see if the enemy has been killed by getting landed on, if so then don't take damage
	await get_tree().process_frame;
	
	if (body && body.is_in_group("enemy")):
		var direction : Vector2 = position - body.position;
		if enemiesInside.find(body) == -1:
			enemiesInside.append(body);
		# Hurt Player
		if ( currentState != PlayerState.HURT && currentState != PlayerState.DEAD ) :
			set_state( PlayerState.HURT, take_damage.bind(1, direction.normalized()) );
		#else : set_state( PlayerState.DEAD );

## Detect collisions between enemies and the bounce area
## body: the body being collided with
func detect_enemy_bounce(body: Node2D) -> void:
	if ( currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY ) :
			return;
	if (body.is_in_group("enemy")):
		if (velocity.y > 0 || body.velocity.y - velocity.y <= 0):
			set_state( PlayerState.BOUNCING );
			body.take_damage();

## Detect collisions with projectiles
## area: the area being collided with
func detect_projectiles(area: Area2D) -> void:
	if ( currentState == PlayerState.DEAD || currentState == PlayerState.VICTORY ) :
			return;
	# Wait one frame to see if the projectile has been bounced on
	await get_tree().process_frame;
	if (area && area.is_in_group("Projectile")):
		var direction : Vector2 = position - area.position;
		
		# Hurt Player
		if ( currentState != PlayerState.HURT ) :
			set_state( PlayerState.HURT, take_damage.bind(1, direction.normalized()) );
		#else : set_state( PlayerState.DEAD );
		area.queue_free();

## Detect collisions between projectiles and the bounce area
## area: the area being collided with
func detect_projectile_bounce(area: Area2D) -> void:
	if (area.is_in_group("Projectile")):
		if area.bounceable:
			set_state( PlayerState.BOUNCING );
		else:
			var direction : Vector2 = position - area.position;
			# Hurt Player
			if ( currentState != PlayerState.HURT ) :
				set_state( PlayerState.HURT, take_damage.bind(1, direction.normalized()) );
			#else : set_state( PlayerState.DEAD );
		area.queue_free();

## Bounce the player up
func bounce() -> void:
	#jumpAnimStarted = false;
	if ( jumpInputHeld ) :
		velocity.y = -jumpHeight * 360 * sqrt(fallSpeed);
	else:
		velocity.y = -jumpHeight * 240 * sqrt(fallSpeed);
	coyoteTimeLeft = 0.0;
	
## Detect walls to either side of player and check for wall jump and slide conditions
func resolve_wall_jumping() -> void:
	
	wallJumpConditionsMet = false;
	wallSlideConditionsMet = false;
	
	# Bail is grounded or walljump feature is diabled
	if ( isPlayerGrounded || !wallJump || justWallJumped ) : return;
	
	var sideWallCollisions : Array[RayCast2D] = [];
	var sideWallCollisionsHit : Array[TileData] = [];
	
	# Check all 3 right and left raycasts to check collision against wall
	for sideRay in sideRaycasts:
		if ( sideRay.is_colliding() ):
			sideWallCollisions.push_back( sideRay );
	
	for sideRay in sideWallCollisions:
		var collider : Object = sideRay.get_collider();
		if (collider is not TileMapLayer): continue;
		var tileLayer : TileMapLayer = collider;
		
		var hitGlobal : Vector2 = sideRay.get_collision_point();
		var hitNormal : Vector2 = sideRay.get_collision_normal();
		var probeGlobal : Vector2 = hitGlobal - hitNormal * 0.5;
		var probeLocal : Vector2 = tileLayer.to_local(probeGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		
		if !tileData || sideWallCollisionsHit.find(tileData) > -1:
			continue;
		sideWallCollisionsHit.push_back(tileData);
		var tileName : String = tileData.get_custom_data("name");
		var rayDirection : Vector2 = sideRay.target_position;
		
		# Wall jumps not allowed on bedrock or one way tiles
		if ( tileName == "bedrock" || tileName == "oneway" || tileName == "bounce" ):
			return;
			
		wallJumpConditionsMet = true;
		
		# decide wall jump direction & count
		if ( rayDirection.x > 0 ) : 
			if ( wallJumpDirection != WallDirection.LEFT ):
				wallJumpCount = 0;
			wallJumpDirection = WallDirection.LEFT;
			
		if ( rayDirection.x < 0 ) : 
			if ( wallJumpDirection != WallDirection.RIGHT ):
				wallJumpCount = 0;
			wallJumpDirection = WallDirection.RIGHT;

		# If no input pressed wall slide is false
		if !( ( Input.is_action_pressed("left") && rayDirection.x < 0 ) || ( Input.is_action_pressed("right") && rayDirection.x > 0 ) ) : 
			return;
			
		wallSlideConditionsMet = true;
		
func wall_jump() :
	if ( wallJumpDirection == WallDirection.NONE ) : 
		return;
	
	wallJumpCount += 1;
	if ! ( wallJumpDecay ) :
		wallJumpCount = 1;
	
	if ( wallJumpDirection == WallDirection.RIGHT ) :
		velocity.x = 1100 * pow(groundSpeed, .55);
	else :
		velocity.x = -1100 * pow(groundSpeed, .55);
	velocity.y = -300 * jumpHeight * sqrt(1.0 / wallJumpCount) / pow(min(groundSpeed, 1), .35);
	justWallJumped = true;	

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tiles() -> void:
	if ( currentState == PlayerState.VICTORY ) :
		return;
	
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
		
		
			# Wall Slide when not on ice
		if ( wallSlideConditionsMet ):
			if tileName != "ice":
				velocity.y *= .94;
			if tileName != "slow":
				currentSlowdown = 1.0;
		
		if ( wallJumpConditionsMet ):		
			if tileName != "ice":
				currentFriction = 1.0;
			# Slow down on slow tiles (and on ice, but you normally wall jump faster anyways)
			if tileName == "slow" || tileName == "ice":
				velocity.x /= 1.5;

		# Bounce tile collisions
		if (tileName == "bounce"):
			isPlayerGrounded = false;
			wallJumpCount = 0;
			AudioManager.play_effect("BounceTile");
			doubleJumpAvailable = doubleJump;
			currentSlowdown = 1.0;
			set_state( PlayerState.BOUNCING );
			# Horizontal bounces
			if ( abs( rayDirection.x ) > abs( rayDirection.y ) ):
				if rayDirection.x < 0:
					velocity.x = 3000 * bounceTileHeight;
				else:
					velocity.x = -3000 * bounceTileHeight;
				if  ( jumpInput ) :
					velocity.y = -500 * bounceTileHeight;
			# Vertical bounces
			else:
				if (rayDirection.y < 0):
					velocity.y = 1000 * bounceTileHeight;
				else:
					#jumpAnimStarted = false;
					coyoteTimeLeft = 0.0;
					velocity.y = -1000 * sqrt(fallSpeed) * bounceTileHeight;
					if ( velocity.x > 0 && leftInput ) :
						velocity.x /= 2;
					elif ( velocity.x < 0 && rightInput ) :
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
				#if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
					#currentState = PlayerState.GROUNDED
				currentSlowdown = .5;
		elif tileName == "hazard":
			var direction : Vector2 = -raycast.target_position;
			# Hurt Player
			if ( currentState != PlayerState.HURT && currentState != PlayerState.DEAD ) :
				if (rayDirection.x < 0) :
					velocity.x = 4500;
				if (rayDirection.x > 0) :
					velocity.x = -4500;
				set_state( PlayerState.HURT, take_damage.bind(1, direction.normalized(), downwardsRaycasts.has(raycast) && Input.is_action_pressed("jump"), true) );

		elif tileName == "death":	
			# Kill Player
			if ( currentState != PlayerState.DEAD ) :
				set_state( PlayerState.DEAD );
		# Only downward rays should drive floor tile effects (except hazard)
		elif downwardsRaycasts.has(raycast):
			#if currentState != PlayerState.JUMPING && currentState != PlayerState.BOUNCING:
				#currentState = PlayerState.GROUNDED;
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
						for downRay in downwardsRaycasts:
							if ( position.y > downRay.get_collision_point().y ) : isPlayerGrounded = false;
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
		#print("Player OOB: ", self.global_position)
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
