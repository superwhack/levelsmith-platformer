extends Camera2D;

enum State {
	EDIT,
	PLAY
}

# Camera movement settings
@export var moveSpeed: float = 500.0;
@export var edgeScrollSpeed: float = 800.0;
@export var edgeScrollMargin: float = 16.0;

# Camera zoom settings
@export var zoomSpeed: float = 0.1;
@export var maxZoomOut: float = 0.5;
@export var maxZoomIn: float = 3.0;

# Camera smoothing
@export var lerpSpeed: float = 8.0;

# Grid bounds
@export var gridMinPos: Vector2 = Vector2(-1000, -1000);
@export var gridMaxPos: Vector2 = Vector2(1000, 1000);

# Current game state
var gameState: State = State.EDIT;

# Reference to player
var playerReference: CharacterBody2D = null;


## Initializes the camera
func _ready() -> void:
	make_current();
	
	# Center camera on grid
	position = (gridMinPos + gridMaxPos) / 2.0;

	# Start zoomed out
	zoom = Vector2.ONE * maxZoomOut;

## Processes camera logic every frame
func _process(delta: float) -> void:

	match gameState:

		State.EDIT:
			process_build_camera(delta);

		State.PLAY:
			process_player_camera(delta);

	clamp_camera_to_grid();


## Handles zoom input
func _unhandled_input(event: InputEvent) -> void:

	if gameState != State.EDIT:
		return;

	if event is InputEventMouseButton:

		if event.pressed:

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				process_zoom(-zoomSpeed);

			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				process_zoom(zoomSpeed);


## Changes the current camera state
## newState: New camera state
func set_state(newState: State) -> void:
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
func process_player_camera(delta: float) -> void:

	if playerReference == null:
		return;

	position = position.lerp(
		playerReference.global_position,
		lerpSpeed * delta
	);


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


## Prevents the camera from leaving the grid
func clamp_camera_to_grid() -> void:

	position.x = clamp(
		position.x,
		gridMinPos.x,
		gridMaxPos.x
	);

	position.y = clamp(
		position.y,
		gridMinPos.y,
		gridMaxPos.y
	);
