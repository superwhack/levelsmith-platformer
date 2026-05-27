extends Camera2D;

# Camera movement settings
@export var moveSpeed: float = 500.0;
@export var edgeScrollSpeed: float = 800.0;
@export var edgeScrollMargin: float = 16.0;

# Camera zoom settings
@export var zoomSpeed: float = 0.1;
@export var maxZoomOut: float = 0.5;
@export var maxZoomIn: float = 3.0;

# Tilemap bound
@export var tileSet: TileMapLayer
var level_bounds: Rect2

# Current game state
var gameState: Global.State = Global.State.EDIT;

# Reference to player
var playerReference: CharacterBody2D = null;


## Initializes the camera
func _ready() -> void:
	make_current();
	
	# Center camera on rect2 of the entire level
	level_bounds = get_level_bounds()
	position = level_bounds.get_center()

	# Start zoomed out
	zoom = Vector2.ONE * maxZoomOut;

func _input(event):
	if event is InputEventMouseButton:
		print("Mouse button:", event.button_index, "pressed:", event.pressed)

## Processes camera logic every frame
func _process(delta: float) -> void:
	match gameState:

		Global.State.EDIT:
			process_build_camera(delta)
			process_zoom_input()
			clamp_camera_to_level()

		Global.State.PLAY:
			process_player_camera(delta)


## Changes the current camera state
## newState: New camera state
func set_state(newState: Global.State) -> void:
	gameState = newState;


## Assigns the player reference
## newPlayerReference: Player node
func set_player(newPlayerReference: CharacterBody2D) -> void:
	playerReference = newPlayerReference;


## Processes editor camera keypress movement
func process_build_camera(delta: float) -> void:

	#var inputVector: Vector2 = Vector2.ZERO;
#
	#inputVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left");
#
	#inputVector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up");
#
	## Keyboard movement
	#if inputVector != Vector2.ZERO:
		#position += inputVector.normalized() * moveSpeed * delta;

	process_edge_scrolling(delta);


## Processes editor edge scrolling
func process_edge_scrolling(delta: float) -> void:

	var mousePos: Vector2 = get_viewport().get_mouse_position();
	var viewportSize: Vector2 = get_viewport_rect().size;

	var edgeMovement: Vector2 = Vector2.ZERO;

	# Left edge
	if mousePos.x <= edgeScrollMargin:
		edgeMovement.x -= 1.0;

	# Right edge
	elif mousePos.x >= viewportSize.x - edgeScrollMargin:
		edgeMovement.x += 1.0;

	# Top edge
	if mousePos.y <= edgeScrollMargin:
		edgeMovement.y -= 1.0;

	# Bottom edge
	elif mousePos.y >= viewportSize.y - edgeScrollMargin:
		edgeMovement.y += 1.0;

	if edgeMovement != Vector2.ZERO:
		position += edgeMovement.normalized() * edgeScrollSpeed * delta;


## Processes player follow camera(not tested yet)
func process_player_camera(_delta: float) -> void:

	if playerReference == null:
		return;

	global_position = playerReference.global_position;


## Adjusts camera zoom
## zoomAmount: Zoom change amount
func process_zoom(zoomAmount: float) -> void:

	zoom += Vector2.ONE * zoomAmount;

	zoom.x = clamp(
		zoom.x,
		maxZoomOut,
		maxZoomIn
	);

	zoom.y = clamp(
		zoom.y,
		maxZoomOut,
		maxZoomIn
	);

func process_zoom_input() -> void:
	if (Input.is_action_just_pressed("zoom_in")):
		process_zoom(zoomSpeed)

	if (Input.is_action_just_pressed("zoom_out")):
		process_zoom(-zoomSpeed)

## Calculates the world-space bounding rectangle of all occupied tiles in the TileMapLayer
## Returns a Rect2 in global coordinates representing the level's outer boundaries
func get_level_bounds() -> Rect2:
	var used_rect: Rect2i = tileSet.get_used_rect()

	# Convert tile coords to world coords
	var top_left: Vector2 = tileSet.to_global(tileSet.map_to_local(used_rect.position))
	var bottom_right: Vector2 = tileSet.to_global(tileSet.map_to_local(used_rect.position + used_rect.size))

	return Rect2(top_left, bottom_right - top_left)

## Prevents the camera from leaving the level
func clamp_camera_to_level() -> void:
	var half_screen: Vector2 = get_viewport_rect().size * 0.5 * zoom

	position.x = clamp(
		position.x,
		level_bounds.position.x + half_screen.x,
		level_bounds.position.x + level_bounds.size.x - half_screen.x
	)

	position.y = clamp(
		position.y,
		level_bounds.position.y + half_screen.y,
		level_bounds.position.y + level_bounds.size.y - half_screen.y
	)
