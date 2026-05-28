extends CharacterBody2D

# The player settings that can be changed in editor
@export var groundSpeed := 1.0;
@export var jumpHeight := 2.0;
# Friction in midair
@export var airControl := 1.0;
@export var fallSpeed := 1.0;
# Determines how long after leaving a platform you can still jump
@export var coyoteTime := 0.2;
var coyoteTimeLeft = coyoteTime;
# TODO: Make FPS dependant on a global FPS initailly instead of being set to 24
# TODO: Impliment animations and use this
@export var FPS := 24;

var spawnpoint := Vector2(0, 0);

# STRETCH: Make maxHealth an export so the player doesn't always die in one hit
const maxHealth := 1;
var health := maxHealth

# Stored friction and slowdown, saved so they are maintained while in midair
var currentFriction := 1.0;
var currentSlowdown := 1.0;

# Speed with constant multiplier and slowdown appended in
var trueSpeed : float;

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
	detect_tile();
	move_and_slide();

## Make the player jump
func jump() -> void:
	 #if is_on_floor():
	velocity.y = -jumpHeight * 360 * currentSlowdown;
	
## Handle left and right movement logic, with the inclusion of if there is no input
## amount: damage to deal
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
	
## Kill the player, for now it just sends them back to start
func die() -> void:
	# Temporary stand-in for killing the player, should be replaced with actual death logic
	health = maxHealth;
	print(spawnpoint);
	set_position(spawnpoint);
	
func set_start(point: Vector2) -> void:
	spawnpoint = point;
	print(spawnpoint);

## Detect tiles the player is colliding with, and have the player interact with tiles below it
func detect_tile() -> void:
	# If there is a collision then reset savedFriction and savedSlowdown
	if get_slide_collision_count() != 0:
		currentFriction = 1.0;
		currentSlowdown = 1.0;
	
	# Check all current collisions
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i);
		var collider := collision.get_collider();
		# Only have collisions confer effects if they are below the player
		if collider is TileMapLayer:
			# Use the global coord to find tile collision
			var tilePos = collider.local_to_map(collider.to_local(collision.get_position()));
			var tileData = collider.get_cell_tile_data(tilePos);
			if tileData and (tileData.get_custom_data("name") == "hazard" or collision.get_position().y > self.get_position().y + 63):
				# Depending on the tile type, apply a different effect
				match (tileData.get_custom_data("name")):
					# Bounce the player up
					"bounce":
						velocity.y = -jumpHeight * 600 * tileData.get_custom_data("bounce");
					# Deal damage to the player
					"hazard":
						take_damage(1);
					# Set friction for the player to slide
					"ice":
						currentFriction = tileData.get_custom_data("friction");
					# Apply a slowdown to player movement and jumps
					"slow":
						currentSlowdown = .5;
