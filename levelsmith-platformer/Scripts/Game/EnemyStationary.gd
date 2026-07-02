class_name EnemyStationary;
extends Enemy

#true = stationary enemy is affected by gravity
var gravityEnabled : bool = true;
var isFacingRight : bool = true;

@export var sprite : Sprite2D;

## Processes the physics every frame
## delta: Time since previous frame
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if gravityEnabled:
		super._physics_process(delta);
		move_and_slide();
	
	update_flipped();

# Updates the orientation of the enemy
func update_flipped(facingRight: bool = isFacingRight) -> void:
	sprite.flip_h = !facingRight;

func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("res://Resources/Enemies/Stationary" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	name = "Stationary" + id;
	propertyFile.position = assignPosition;
	isFacingRight = propertyFile.isFacingRight;
	gravityEnabled = propertyFile.gravity;
	ResourceSaver.save(propertyFile);

func apply_script(file: Resource) -> void:
	propertyFile = file;
	isFacingRight = propertyFile.isFacingRight; 
	gravityEnabled = propertyFile.gravity;
