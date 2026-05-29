extends Camera2D;

@export var masterManager: Node

# Camera movement settings
@export var moveSpeed: float = 500.0;
@export var edgeScrollSpeed: float = 800.0;
@export var edgeScrollMargin: float = 16.0;

# Camera zoom settings
@export var zoomSpeed: float = 0.1;
@export var maxZoomOut: float = 0.5;
@export var maxZoomIn: float = 3.0;
@export var playZoom: float = 0.7;

# Tilemap bound
@export var tileSet: TileMapLayer
var level_bounds: Rect2

# Reference to player
var playerReference: CharacterBody2D = null;
var playerSearchAttempts := 0;
var maxPlayerSearchAttempts := 60;
var searchForPlayer := true;

## Initializes the camera
func _ready() -> void:
	make_current();
	# Center camera on rect2 of the entire level
	level_bounds = get_level_bounds()
	global_position = level_bounds.get_center()

	# Start zoomed out
	zoom = Vector2.ONE * maxZoomOut;
	Global.reload.connect(reset_player_cam);

#func _input(event):
	#if event is InputEventMouseButton:
		#print("Mouse button:", event.button_index, "pressed:", event.pressed)

## On reloading the game scene, reset the player reference and search again
func reset_player_cam() -> void:
	playerReference = null;
	searchForPlayer = true;

## Processes camera logic every frame
func _process(delta: float) -> void:
	var state = masterManager.state

	#print("RUNNING STATE:", state)

	match state:

		Global.State.EDIT:
			process_build_camera(delta)
			process_zoom_input()
			clamp_camera_to_level()

		Global.State.PLAY:
			if playerReference == null:
				try_find_player()

			if playerReference != null:
				process_player_camera(delta)
				zoom = Vector2.ONE * playZoom

## find the 1st node in the group called "player"
func try_find_player() -> void:
	if !searchForPlayer:
		return

	playerReference = get_tree().get_nodes_in_group("Player")[get_tree().get_node_count_in_group("Player") - 1] as CharacterBody2D

	if playerReference != null:
		print("From CameraManager: player found")
		searchForPlayer = false;
		return
	
	playerSearchAttempts += 1
	
	if playerSearchAttempts >= maxPlayerSearchAttempts:
		print("From CameraManager: ERROR - fail to find player")
		searchForPlayer = false

## Processes editor camera keypress movement
func process_build_camera(delta: float) -> void:
	var inputVector: Vector2 = Vector2.ZERO;

	inputVector.x = Input.get_action_strength("right") - Input.get_action_strength("left");

	inputVector.y = Input.get_action_strength("down") - Input.get_action_strength("up");

	# Keyboard movement
	if inputVector != Vector2.ZERO:
		global_position += inputVector.normalized() * moveSpeed * delta;

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
		global_position += edgeMovement.normalized() * edgeScrollSpeed * delta;


## Processes player follow camera
func process_player_camera(_delta: float) -> void:

	if playerReference == null:
		return;

	global_position = playerReference.global_position;


## Adjusts camera zoom
## zoomAmount: Zoom change amount
func process_zoom(zoomAmount: float) -> void:

	# Mouse world position BEFORE zoom
	var mouse_world_before: Vector2 = get_global_mouse_position()

	# Fallback to level center if mouse outside map
	if !level_bounds.has_point(mouse_world_before):
		mouse_world_before = level_bounds.get_center()

	# Calculate new zoom first
	var new_zoom: float = clamp(
		zoom.x + zoomAmount,
		maxZoomOut,
		maxZoomIn
	)

	# STOP if already at zoom limit
	if is_equal_approx(new_zoom, zoom.x):
		return

	# Apply zoom
	zoom = Vector2.ONE * new_zoom

	# Mouse world position AFTER zoom
	var mouse_world_after: Vector2 = get_global_mouse_position()

	if !level_bounds.has_point(mouse_world_after):
		mouse_world_after = level_bounds.get_center()

	# Offset camera so zoom focuses on mouse
	global_position += mouse_world_before - mouse_world_after

	clamp_camera_to_level()

func process_zoom_input() -> void:
	if masterManager.state != Global.State.EDIT:
		return

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
	var viewport_size: Vector2 = get_viewport_rect().size

	# Visible world size based on zoom
	var visible_size: Vector2 = viewport_size * 0.5 / zoom

	var min_x = level_bounds.position.x + visible_size.x
	var max_x = level_bounds.position.x + level_bounds.size.x - visible_size.x

	var min_y = level_bounds.position.y + visible_size.y
	var max_y = level_bounds.position.y + level_bounds.size.y - visible_size.y

	# If level smaller than camera view, center camera
	if min_x > max_x:
		global_position.x = level_bounds.get_center().x
	else:
		global_position.x = clamp(global_position.x, min_x, max_x)

	if min_y > max_y:
		global_position.y = level_bounds.get_center().y
	else:
		global_position.y = clamp(global_position.y, min_y, max_y)
