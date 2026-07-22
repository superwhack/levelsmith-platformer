class_name MovingPlatform;
extends AnimatableBody2D;

# Everything it used from the BaseEnemyClass
var propertyFile : Resource;
var active = false;
@export var onScreen : VisibleOnScreenNotifier2D;

# Movement speed of the platform.
@export var speed : float = 1.0;

# Reference to the animated sprite
@export var animatedSprite : AnimatedSprite2D;

# Movement points, from the spawn position to the preset offset.
var pointA : Vector2;
var pointB : Vector2;
var progress : float;
var velocity : Vector2;

var easing : bool;

# Current destination point.
var targetPoint : Vector2;
var movementDistance : float;

# Modifier to the speed
const SPEED_MODIFIER : float = 100.0;

# Preview references
@export var previewLine : Line2D;
@export var previewPlatform : Sprite2D;

# Mutes movement after spawning so it can teleport to it's initial position
var muteMove = true;

# Delay, in seconds, when reaching the current targetPoint before moving again
var delay : float = 0.0;
var delayLeft = 0.0;

# Bools relating to the properties
var visiblePath : bool = false;
var momentumShare : bool = false;
var alwaysActive : bool = false;

## Sets up initial points, updates sprites to templates
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
	# If the path should be visible, show it
	if visiblePath:
		previewLine.show();
		previewLine.global_position = pointA;
	# If not currently active and not always supposed to be active, check if on screen
	if !active && !alwaysActive:
		# If not on screen, return, otherwise set to active
		if !onScreen.is_on_screen():
			return;
		active = true;
	# Move platform
	if muteMove:
		move_behavior(delta);
	else:
		muteMove = true;
	
## Moves the platform toward current destination.
func move_behavior(delta: float) -> void:
	# Waits for the delay to finish
	if delayLeft > 0.0:
		delayLeft -= delta;
		if delayLeft <= 0.0:
			animatedSprite.play();
		return;
	# Get the direction and distance of movement
	var directionVector : Vector2 = targetPoint - global_position;
	var move_distance : float = speed * SPEED_MODIFIER * delta;
	# If the platform is close enough to the point, change direction
	if (directionVector.length() <= move_distance):
		global_position = targetPoint;
		velocity = Vector2.ZERO;
		switch_target();
		return;
	# Set the velocity
	velocity = directionVector.normalized() * speed * SPEED_MODIFIER;
	# Ease the movement
	if easing:
		velocity = (velocity / 1.5) + (velocity * min((pointA-position).length(), (pointB-position).length()) / movementDistance * 2);
	# Move based on the velocity
	position += velocity * delta;

## Switches the active destination.
func switch_target() -> void:
	if delay > 0:
		animatedSprite.pause();
	delayLeft = delay;
	if targetPoint.distance_to(pointA) < 1.0:
		targetPoint = pointB;
	else:
		targetPoint = pointA;

## Assigns a resource file to the platform.
## id is the unique identifier of the preset.
## position: Tilemap position of the platform.
func assign_script(id: String, assignPosition: Vector2i) -> void:
	propertyFile = ResourceLoader.load("user://Resources/Enemies/MovingPlatform" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	# Set the properties based on the file values
	name = "MovingPlatform" + id;
	propertyFile.position = assignPosition;
	speed = propertyFile.speed;
	pointA = global_position;
	pointB = pointA + propertyFile.pointBOffset;
	targetPoint = pointB;
	progress = propertyFile.progress;
	delay = propertyFile.delay;
	easing = propertyFile.easing;
	alwaysActive = propertyFile.active;
	visiblePath = propertyFile.visible;
	momentumShare = propertyFile.momentum;
	# Adjust the preview and line
	adjust_preview();
	previewLine.update();
	# Save the property file
	ResourceSaver.save(propertyFile);
	# Apply the script
	apply_script(propertyFile);

## Adjust the current state of the preview platform
## pointTo : The point that the preview is pointing at
## selectedProgress : The progress along the path that the platform is at
func adjust_preview(pointTo : Vector2 = pointB, selectedProgress : float = progress) -> void:
	previewPlatform.show();
	previewPlatform.global_position = lerp(global_position, global_position + pointTo, float(selectedProgress) / 100);

## Apply the progress variable into starting global position
func apply_progress() -> void:
	position = lerp(pointA, pointB, float(progress) / 100.0);
	muteMove = false;

## Applies the values stored in a MovingPlatformPreset.
## file: Resource containing enemy properties.
func apply_script(file: Resource) -> void:
	propertyFile = file;
	
	# Set all values based on the file
	speed = file.speed;
	pointA = global_position;
	pointB = pointA + file.pointBOffset;
	movementDistance = pointA.distance_to(pointB)
	progress = file.progress;
	delay = file.delay;
	easing = file.easing;
	alwaysActive = file.active;
	adjust_preview(file.pointBOffset, progress);
	targetPoint = pointB;
	previewLine.update((pointB - pointA) / Global.TILE_SIZE);
	z_index += 2;
	previewLine.z_index = z_index - 5;
	visiblePath = propertyFile.visible;
	momentumShare = propertyFile.momentum;
