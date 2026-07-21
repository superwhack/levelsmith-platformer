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

const DEFAULT_ZOOM : float = 100.0;
const DEFAULT_FOLLOW_SPEEC : float = 100.0;
const DEFAULT_DEADZONE : float = 0.0;
const DEFAULT_CAMERA_CLAMP : bool = false;

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

## When dragging, adjust the values in real time
func _on_drag() -> void:
	# Await needed for values to update from drag_ended
	await get_tree().process_frame;
	
	# Camera
	cameraManager.playZoom = gameplayZoom.value / 100;
	cameraManager.followSpeed = followSpeed.value / 100;
	cameraManager.deadzone = cameraDeadzone.value;
	cameraManager.cameraPlayClamp = cameraClamp.value;

func _input( event: InputEvent ) -> void:
	if (event.is_action_pressed("ui_close_dialog")):
		editorManager.close_level_settings_menu();

## Update sliders visually
func update_sliders() -> void:
	
	gameplayZoom.update_slider();
	followSpeed.update_slider();
	cameraDeadzone.update_slider();
	cameraClamp.update_checkbox();
	
	_on_drag();


## Reset the settings
func reset_settings() -> void:
	gameplayZoom.value = DEFAULT_ZOOM;
	followSpeed.value = DEFAULT_FOLLOW_SPEEC;
	cameraDeadzone.value = DEFAULT_DEADZONE;
	cameraClamp.value = DEFAULT_CAMERA_CLAMP;

	update_sliders();
