class_name MovingPlatform;
extends AnimatableBody2D;

# Everything it used from the BaseEnemyClass
var propertyFile : Resource;
var active = false;
@export var onScreen : VisibleOnScreenNotifier2D;

# Movement speed of the enemy.
@export var speed : float = 1.0;

@export var animatedSprite : AnimatedSprite2D;

# Movement points, from the spawn position to the preset offset.
var pointA : Vector2;
var pointB : Vector2;
var progress : float;
var velocity : Vector2;

var easing : bool;

# Current destination point.
var targetPoint : Vector2;

const SPEED_MODIFIER : float = 100.0;

@export var previewLine : Line2D;
@export var previewPlatform : Sprite2D;

# Mutes movement after spawning so it can teleport to it's initial position
var muteMove = true;

## Sets up initial points
func _ready() -> void:
	# Set all points to its current position
	pointA = global_position;
	pointB = pointA;
	targetPoint = pointA;
	animatedSprite.sprite_frames = AnimationManager.movingPlatformTemplateSprite.sprite_frames;
	previewPlatform.texture = animatedSprite.sprite_frames.get_frame_texture("PlatformAnimation", 0);

## Processes flying movement and collision handling.
## delta: Time since previous frame.
func _physics_process(delta: float) -> void:
	if !active:
		if !onScreen.is_on_screen():
			return;
		active = true;
	if muteMove:
		move_behavior(delta);
	else:
		muteMove = true;
	
## Moves the platform toward current destination.
func move_behavior(delta: float) -> void:
	# Get the direction and distance of movement
	var directionVector : Vector2 = targetPoint - global_position;
	var move_distance : float = speed * SPEED_MODIFIER * delta;

	if easing:
		if (directionVector.length() <= move_distance * 4):
			velocity *= directionVector.length() / (move_distance * 4);

	# If the enemy is close enough to the point, change direction
	if (directionVector.length() <= move_distance):
		global_position = targetPoint;
		velocity = Vector2.ZERO;
		switch_target();
		return;

	velocity = directionVector.normalized() * speed * SPEED_MODIFIER;
	position += velocity * delta;


## Switches the active destination.
func switch_target() -> void:
	if targetPoint.distance_to(pointA) < 1.0:
		targetPoint = pointB;
	else:
		targetPoint = pointA;

## Assigns a resource file to the enemy.
## id is the unique identifier of the preset.
## position: Tilemap position of the enemy.
func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("user://Resources/Enemies/MovingPlatform" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	name = "MovingPlatform" + id;
	propertyFile.position = assignPosition;
	speed = propertyFile.speed;
	pointA = global_position;
	pointB = pointA + propertyFile.pointBOffset;
	targetPoint = pointB;
	progress = propertyFile.progress;
	easing = propertyFile.easing;
	
	adjust_preview();
	previewLine.update();
	
	ResourceSaver.save(propertyFile);

	apply_script(propertyFile);

## Adjust the current state of the preview platform
func adjust_preview(pointTo : Vector2 = pointB, selectedProgress : float = progress) -> void:
	previewPlatform.show();
	previewPlatform.global_position = lerp(global_position, global_position + pointTo, float(selectedProgress) / 100);

## Apply the progress variable into starting global position
func apply_progress() -> void:
	position = lerp(pointA, pointB, float(progress) / 100.0);
	muteMove = false;

## Applies the values stored in a FlyingPreset.
## file: Resource containing enemy properties.
func apply_script(file: Resource) -> void:
	propertyFile = file;

	speed = file.speed;

	pointA = global_position;
	pointB = pointA + file.pointBOffset;
	progress = file.progress;
	easing = file.easing;
	adjust_preview(file.pointBOffset, progress);
	targetPoint = pointB;
	previewLine.update((pointB - pointA) / Global.TILE_SIZE);
	z_index += 2;
	previewLine.z_index = z_index - 4;
