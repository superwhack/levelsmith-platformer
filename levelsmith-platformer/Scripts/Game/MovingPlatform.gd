class_name MovingPlatform;
extends AnimatableBody2D;

# Everything it used from the BaseEnemyClass
var propertyFile : Resource;
var active = false;
@export var onScreen : VisibleOnScreenNotifier2D;

# Movement speed of the enemy.
@export var speed : float = 1.0;

# Movement points, from the spawn position to the preset offset.
var pointA : Vector2;
var pointB : Vector2;
var progress : float;
var velocity : Vector2;

# Current destination point.
var targetPoint : Vector2;

const SPEED_MODIFIER : float = 100.0;

@export var previewLine : Line2D;
@export var previewLineEndpoint : Sprite2D;
@export var previewPlatform : Sprite2D;

var temporaryFixTimer = 3;
## Sets up initial points
func _ready() -> void:
	# Set all points to its current position
	pointA = global_position;
	pointB = pointA;
	targetPoint = pointA;

## Processes flying movement and collision handling.
## delta: Time since previous frame.
func _physics_process(delta: float) -> void:
	if !active:
		if !onScreen.is_on_screen():
			return;
		active = true;
	if temporaryFixTimer > 0:
		temporaryFixTimer -= 1;
		apply_progress();
	else:
		move_behavior(delta);
	
## Moves the platform toward current destination.
func move_behavior(delta: float) -> void:
	# Get the direction and distance of movement
	var directionVector : Vector2 = targetPoint - global_position;
	var move_distance : float = speed * SPEED_MODIFIER * delta;

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
	propertyFile = ResourceLoader.load("res://Resources/Enemies/MovingPlatform" + id + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	name = "MovingPlatform" + id;
	propertyFile.position = assignPosition;
	speed = propertyFile.speed;
	pointA = global_position;
	pointB = pointA + propertyFile.pointBOffset;
	targetPoint = pointB;
	progress = propertyFile.progress;
	
	adjust_preview();
	update_line_preview();
	
	ResourceSaver.save(propertyFile);

	apply_script(propertyFile);

## Adjust the current state of the preview platform
func adjust_preview(pointTo : Vector2 = pointB, selectedProgress : float = progress) -> void:
	previewPlatform.show();
	previewPlatform.global_position = lerp(global_position, global_position + pointTo, float(selectedProgress) / 100);

## Update the preview for the moving platform
## x: The x to update with
## y: The y to update with
func update_line_preview(x : int = int((pointB.x - pointA.x) / Global.TILE_SIZE) , y : int = int((pointB.y - pointA.y) / Global.TILE_SIZE)) -> void:
	var offset : Vector2 = Vector2(x * Global.TILE_SIZE, y * Global.TILE_SIZE);
	previewLine.modulate.a = .5;
	previewLine.global_position = global_position;
	previewLine.clear_points();
	previewLine.add_point(Vector2.ZERO);
	previewLine.add_point(offset);
	if previewLine.get_point_count() > 0:
		var last_point_index: int = previewLine.get_point_count() - 1;
		if previewLine.get_point_position(last_point_index) == previewLine.get_point_position(0):
			previewLineEndpoint.hide();
		else:
			previewLineEndpoint.show();
			previewLineEndpoint.position = previewLine.get_point_position(last_point_index);

## Apply the progress variable into starting global position
func apply_progress() -> void:
	previewPlatform.hide();
	position = lerp(pointA, pointB, float(progress) / 100.0);
	

## Applies the values stored in a FlyingPreset.
## file: Resource containing enemy properties.
func apply_script(file: Resource) -> void:
	propertyFile = file;

	speed = file.speed;

	pointA = global_position;
	pointB = pointA + file.pointBOffset;
	progress = file.progress;
	adjust_preview(file.pointBOffset, progress);
	targetPoint = pointB;
	update_line_preview();
