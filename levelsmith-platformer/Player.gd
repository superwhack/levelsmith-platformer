extends CharacterBody2D


const SPEED := 400.0;
const JUMP_VELOCITY := -600.0;

var savedFriction := 0.0;
var savedSlowdown := 1.0;

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var speedMod := SPEED;
	if not is_on_floor():
		velocity += get_gravity() * delta;
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY / savedSlowdown;

	# Handling input with friction assumed initailly, accelerate the player
	var accX := 0.0;
	var direction := Input.get_axis("left", "right");
	if direction:
		accX = direction * SPEED / 10;
	else:
		accX = -velocity.x / 10;
		
	var noSlide = true;
	if get_slide_collision_count() != 0:
		savedFriction = 0.0;
		savedSlowdown = 1.0;
	# Check collisions on all tiles for a physics material
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i);
		var collider := collision.get_collider();
		if collider is TileMapLayer:
			# Use the global coord to find tile collision
			var tilePos = collider.local_to_map(collider.to_local(collision.get_position()));
			var tileData = collider.get_cell_tile_data(tilePos);
			if tileData:
				# Depending on the tile type, apply a different effect
				match (tileData.get_custom_data("name")):
					"bounce":
						velocity.y = JUMP_VELOCITY * tileData.get_custom_data("bounce") * 2;
					"hazard":
						# Temporary stand-in for killing the player
						set_position(Vector2(573.0,833.0));
					"ice":
						savedFriction = tileData.get_custom_data("friction");
						noSlide = false;
						accX *= (1 / savedFriction);
					"slow":
						savedSlowdown = 2;
	if savedSlowdown > 1:
		speedMod = SPEED / 2.0;
	# If there is no friction currently acting, then the velocity.x should be set to Speed
	if noSlide && savedFriction == 0.0:
		if direction:
			velocity.x = direction * speedMod;
		else:
			velocity.x = move_toward(velocity.x, 0, speedMod);
	# Otherwise, modify it by the acceration
	else:
		velocity.x += accX;
		velocity.x = clamp(velocity.x, -SPEED, SPEED);
	move_and_slide();
