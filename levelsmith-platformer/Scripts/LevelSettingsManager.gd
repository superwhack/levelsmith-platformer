extends Panel
class_name LevelSettingsMenu;

# General
@export var editorManager : Node2D;
@export var closeButton : Button;
@export var resetButton : Button;

@export var cameraManager : Node2D;
# Camera
@export var gameplayZoom : VBoxContainer;
@export var followSpeed : VBoxContainer;
@export var cameraDeadzone : VBoxContainer;
@export var cameraClamp : VBoxContainer;

# Tiles
@export var iceFriction : VBoxContainer;
@export var bounceHeight : VBoxContainer;
@export var stickySlowdown : VBoxContainer;
@export var hazardDamage : VBoxContainer;

func _ready() -> void:
	closeButton.pressed.connect(editorManager.close_level_settings_menu);
	resetButton.pressed.connect(reset_settings);
	
	# CAMERA ---
	# Set current default values
	gameplayZoom.value = cameraManager.playZoom * 100;
	followSpeed.value = cameraManager.followSpeed * 100;
	cameraDeadzone.value = cameraManager.deadzone;
	cameraClamp.value = cameraManager.cameraPlayClamp;
	gameplayZoom.update_slider();
	followSpeed.update_slider();
	cameraDeadzone.update_slider();
	cameraClamp.update_checkbox();
	# Sliders connection
	gameplayZoom.drag_ended.connect(_on_drag);
	followSpeed.drag_ended.connect(_on_drag);
	cameraDeadzone.drag_ended.connect(_on_drag);
	cameraClamp.check_changed.connect(_on_drag);

	# TILE PROPERTIES ---
	# Set current default values
	iceFriction.value = editorManager.tileMap.iceFriction * 100;
	bounceHeight.value = editorManager.tileMap.bounceHeight;
	stickySlowdown.value = editorManager.tileMap.stickySlowdown * 100;
	hazardDamage.value = editorManager.tileMap.hazardDamage;
	iceFriction.update_slider();
	bounceHeight.update_slider();
	stickySlowdown.update_slider();
	hazardDamage.update_slider();
	# Sliders connection
	iceFriction.drag_ended.connect(_on_drag);
	bounceHeight.drag_ended.connect(_on_drag);
	stickySlowdown.drag_ended.connect(_on_drag);
	hazardDamage.drag_ended.connect(_on_drag);

## When dragging, adjust the values in real time
func _on_drag() -> void:
	# Await needed for values to update from drag_ended
	await get_tree().process_frame;
	
	# Camera
	cameraManager.playZoom = gameplayZoom.value / 100;
	cameraManager.followSpeed = followSpeed.value / 100;
	cameraManager.deadzone = cameraDeadzone.value;
	cameraManager.cameraPlayClamp = cameraClamp.value;
	
	# Tile Properties
	editorManager.tileMap.iceFriction = iceFriction.value;
	editorManager.tileMap.bounceHeight = bounceHeight.value;
	editorManager.tileMap.stickySlowdown = stickySlowdown.value;
	editorManager.tileMap.hazardDamage = hazardDamage.value;

## Update sliders visually
func update_sliders() -> void:
	
	gameplayZoom.update_slider();
	followSpeed.update_slider();
	cameraDeadzone.update_slider();
	cameraClamp.update_checkbox();
	
	iceFriction.update_slider();
	bounceHeight.update_slider();
	stickySlowdown.update_slider();
	hazardDamage.update_slider();
	
	_on_drag();

## Reset the settings
func reset_settings() -> void:
	gameplayZoom.value = 100.0;
	followSpeed.value = 100.0;
	cameraDeadzone.value = 0.0;
	cameraClamp.value = false;
	
	iceFriction.value = 50;
	bounceHeight.value = 1.0;
	stickySlowdown.value = 40;
	hazardDamage.value = 1;

	update_sliders();
