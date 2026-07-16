extends Camera2D;

# A direct reference to the Master Manager.
@export var masterManager : Node2D;

# Camera movement settings
@export var roamCellCount : float = 4.0;
@export var moveSpeed : float = 500.0;
@export var edgeScrollSpeed : float = 800.0;
@export var edgeScrollMargin : float = 100.0;
var isPanning : bool = false;
var panSpeed : float = 1.0;

# Camera zoom settings
@export var zoomSpeed : float = 0.1;
@export var maxZoomOut : float = 0.5;
@export var maxZoomIn : float = 2.0;

# Tilemap bound
@export var gridLines : TileMapLayer;
var levelBounds : Rect2;
var roamBounds : Rect2;

# Reference to player
var playerReference : CharacterBody2D = null;
var playerSearchAttempts : int = 0;
const maxPlayerSearchAttempts : int = 60;
var searchForPlayer : bool = true;#

# Settings for camera during play
var playZoom : float = 1.0;
var followSpeed : float = 1.0;
var deadzone : float = 0.0;
var cameraPlayClamp : bool = false;

## Initializes the camera
func _ready() -> void:
	make_current();
	# Center camera on rect2 of the entire level
	refresh_bounds();
	
	zoom = Vector2.ONE * maxZoomOut;
	global_position = levelBounds.get_center();
	
	
	# Start zoomed out
	Global.reload.connect(reset_camera);
	Global.levelCreated.connect(refresh_bounds);
	ImportExportManager.levelImported.connect(refresh_bounds);

#func _input(event):
	#if event is InputEventMouseButton:
		#print("Mouse button:", event.button_index, "pressed:", event.pressed)
		
## For initializing a camera on level load/creation. 
## Almost the same as _ready(), but called not just on ready.
func initialize_camera() -> void:
	refresh_bounds();
	zoom = Vector2.ONE * get_min_zoom_to_fit_roam();
	global_position = levelBounds.get_center();
	clamp_camera(roamBounds);
	#print("center:", levelBounds.get_center());
	#print("camera:", global_position);
	#print("zoom:", zoom);

## Retrieve the level bounds and the camera roaming bounds.
func refresh_bounds() -> void:
	levelBounds = Rect2(Vector2.ZERO, masterManager.worldSize * Global.TILE_SIZE);
	# This is so the top and bottom bedrock border are visible when clamped.
	levelBounds.position.x -= Global.TILE_SIZE;
	levelBounds.size.x += Global.TILE_SIZE * 2;
	levelBounds.position.y -= Global.TILE_SIZE;
	levelBounds.size.y += Global.TILE_SIZE * 2;
	roamBounds = get_camera_bounds();

## Remove the player reference and restart the search for the player.
func reset_camera() -> void:
	playerReference = null;
	searchForPlayer = true;
	panSpeed = 1.0;

## Processes camera logic every frame
## delta: time since previous frame
func _process(delta: float) -> void:
	match masterManager.state:
		Global.State.EDIT:
			position_smoothing_enabled = false;
			process_build_camera(delta);
			process_zoom_input();
			clamp_camera(roamBounds);
		Global.State.PLAY:
			position_smoothing_speed = followSpeed * 8;
			if playerReference == null:
				try_find_player();
			else:
				process_player_camera();
				zoom = Vector2.ONE * playZoom;

## find the 1st node in the group called "player"
func try_find_player() -> void:
	if !searchForPlayer:
		return;
	
	playerReference = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1] as CharacterBody2D;
	
	if playerReference != null:
		#print("From CameraManager: player found");
		searchForPlayer = false;
		return;
	
	playerSearchAttempts += 1
	
	if playerSearchAttempts >= maxPlayerSearchAttempts:
		#print("From CameraManager: ERROR - fail to find player");
		searchForPlayer = false;

## Handles mouse middle-click panning
## event: the captured input event that has occurred
func _input(event: InputEvent) -> void:
	# Start/stop middle-click panning
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			isPanning = event.pressed;

	# Pan while dragging
	if event is InputEventMouseMotion and isPanning:
		global_position -= event.relative / zoom * (1.8);
		clamp_camera(roamBounds);
		
	if Input.is_action_just_pressed("shift"):
		panSpeed = 3.0;
		
	if Input.is_action_just_released("shift"):
		panSpeed = 1.0;

## Processes editor camera keypress movement
## delta: time since previous frame
func process_build_camera(delta: float) -> void:
	var inputVector : Vector2;
	var speedModifier : int = 1;
	
	# Prevents camera moving down when saving
	if Input.is_key_pressed(KEY_CTRL):
		return;
	
	
	inputVector.x = Input.get_action_strength("right") - Input.get_action_strength("left");
	
	inputVector.y = Input.get_action_strength("down") - Input.get_action_strength("up");
	
	# If shift is being held, make it move faster.
	if Input.is_action_pressed("shift"): speedModifier = 3;
	
	global_position += inputVector.normalized() * moveSpeed * speedModifier * delta * (1.8 / zoom.x);
	
	# Edge scrolling currently commented out
	#if (!get_viewport().gui_get_hovered_control()):
		#process_edge_scrolling(delta);

## Processes editor edge scrolling
## delta: time since previous frame
## NOTE: Currently edge scrolling is unused as it leads to more issues than it's worth
func process_edge_scrolling(delta: float) -> void:
	var mousePos : Vector2 = get_viewport().get_mouse_position();
	var viewportSize : Vector2 = get_viewport_rect().size;

	var edgeMovement : Vector2 = Vector2.ZERO;

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
		global_position += edgeMovement.normalized() * edgeScrollSpeed * delta;

## Snap the camera
## snapTo: the positon to snap to
func snap_camera(snapTo: Vector2) -> void:
	zoom = Vector2.ONE * playZoom;
	global_position = snapTo;
	if cameraPlayClamp:
		clamp_camera(levelBounds);
	reset_smoothing();

## Processes player follow camera
## snap: if true, the camera will snap to the player without deadzone logic
func process_player_camera(snap : bool = false) -> void:
	if playerReference == null:
		return;
	if deadzone == 0 || snap:
		global_position = playerReference.global_position;
	else:
		var differenceVector = (playerReference.global_position - global_position);
		if abs(differenceVector.x) > deadzone * 300:
			global_position.x += differenceVector.x - sign(differenceVector.normalized().x) * deadzone * 300;
		if abs(differenceVector.y) > deadzone * 200:
			global_position.y += differenceVector.y - sign(differenceVector.normalized().y) * deadzone * 200;
	if cameraPlayClamp:
		clamp_camera(levelBounds);

## Adjusts camera zoom
## zoomAmount: Zoom change amount
func process_zoom(zoomAmount: float) -> void:
	# Mouse world position BEFORE zoom
	var mouseWorldBefore : Vector2 = get_global_mouse_position();
	
	var newZoom : float = zoom.x + zoomAmount;
	
	# Get the minimum zoom to fit the roaming bounds
	var fitZoom : float = get_min_zoom_to_fit_roam();
	
	# clamp the zoom to either the roam bound limits (fitZoom) or the maxZoomIn
	newZoom = clamp(newZoom, fitZoom, maxZoomIn);
	
	zoom = Vector2.ONE * newZoom;
	
	#if (zoom.x <= 0.3):
		#gridLines.visible = false;
	#else:
		#gridLines.visible = true;
	
	# Mouse world position AFTER zoom
	var mouseWorldAfter : Vector2 = get_global_mouse_position();
	
	# Offset camera so zoom focuses on mouse
	global_position += mouseWorldBefore - mouseWorldAfter;
	# If zoomed out enough, hide the grid layer.

## Change the smoothing value, used by GameManager when followSpeed is less than 1
## toEnable: if it's enabled, by default it's determined by the followSpeed
func adjust_smoothing(toEnable : bool = followSpeed < 1.0) -> void:
	position_smoothing_enabled = toEnable;
	

func process_zoom_input() -> void:
	if masterManager.state != Global.State.EDIT:
		return;
	
	if (Input.is_action_pressed("zoom_in")):
		process_zoom(zoomSpeed / 8);
		
	if (Input.is_action_pressed("zoom_out")):
		process_zoom(-zoomSpeed / 8);
	
	if (Input.is_action_just_pressed("scroll_up")):
		process_zoom(zoomSpeed);
		
	if (Input.is_action_just_pressed("scroll_down")):
		process_zoom(-zoomSpeed);

## Determine the bounds of camera panning.
## Returns a rect of the limits of where the camera is able to go.
func get_camera_bounds() -> Rect2:
	# Roam marg
	var roamMargin = roamCellCount * Global.TILE_SIZE;
	var margin = Vector2.ONE * roamMargin;

	# Returns roam bounds based on level bounds accurately
	return Rect2(
		levelBounds.position - margin,
		levelBounds.size + margin * 2
	);

## Prevents the camera from leaving the given rect2.
## bounds: The bounds within which the camera must remain.
func clamp_camera(bounds: Rect2) -> void:
	var viewportSize : Vector2 = get_viewport_rect().size;
	
	# visible world size
	var visibleSize : Vector2 = viewportSize * 0.5 / zoom;
	
	var minX : float = bounds.position.x + visibleSize.x + Global.TILE_SIZE / 2.0;
	var maxX : float = bounds.end.x - visibleSize.x - Global.TILE_SIZE / 2.0;
	
	var minY : float = bounds.position.y + visibleSize.y + Global.TILE_SIZE / 2.0;
	var maxY : float = bounds.end.y - visibleSize.y - Global.TILE_SIZE / 2.0;
	
	# If zoom too far out, just center
	if minX > maxX:
		global_position.x = bounds.get_center().x;
	else:
		global_position.x = clamp(global_position.x, minX, maxX);
	
	if minY > maxY:
		global_position.y = bounds.get_center().y;
	else:
		global_position.y = clamp(global_position.y, minY, maxY);
		
	
		
## Determine if self contains a given rect2.
## roamingBounds: A rect2 of the camera panning limits
## Returns a true or false bool.
func camera_encloses_roam(roamingBounds: Rect2) -> bool:
	return get_camera_rect().encloses(roamingBounds);

## Get a rect of the camera.
## Returns a Rect2 of the camera viewport.
func get_camera_rect() -> Rect2:
	var pos : Vector2 = self.global_position;
	var halfSize : Vector2 = get_viewport_rect().size * 0.5 / zoom;
	
	var topLeft : Vector2 = pos - halfSize;
	var size : Vector2 = get_viewport_rect().size / zoom;
	
	return Rect2(topLeft, size);
	
## Getting the maximum possible zoom out for the roam bounds to be contained.
## Returns a float of the max zoom.
func get_min_zoom_to_fit_roam() -> float:
	# Getting the viewport and roaming area (where the camera can go) sizes
	var viewportSize : Vector2 = get_viewport_rect().size;
	var roamSize : Vector2 = roamBounds.size;

	# Get the scale ratio between the x/y values for the minimum zoom
	var zoomX : float = viewportSize.x / roamSize.x;
	var zoomY : float = viewportSize.y / roamSize.y;

	# Get the minimum between both options
	return min(zoomX, zoomY);
