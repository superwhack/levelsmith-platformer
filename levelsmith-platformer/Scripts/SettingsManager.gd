extends Panel

# General
@export var editorManager : Node2D;
@export var closeButton : Button;

@export var cameraManager : Node2D;

# Volume
@export var masterVolume : VBoxContainer;
@export var SFXVolume : VBoxContainer;
@export var musicVolume : VBoxContainer;

# Camera
@export var gameplayZoom : VBoxContainer;
@export var followSpeed : VBoxContainer;
@export var cameraDeadzone : VBoxContainer;
@export var cameraClamp : VBoxContainer;

func _ready() -> void:
	closeButton.pressed.connect(editorManager.close_settings_menu);
	
	# AUDIO ---
	# Set current default values
	masterVolume.value = AudioManager.masterVolume * 100;
	SFXVolume.value = AudioManager.SFXVolume * 100;
	musicVolume.value = AudioManager.musicVolume * 100;
	masterVolume.update_slider();
	SFXVolume.update_slider();
	musicVolume.update_slider();
	# Sliders connection
	# .dragging also needs a connect so sound changes can be hard while editing them
	masterVolume.dragging.connect(_on_drag);
	SFXVolume.dragging.connect(_on_drag);
	musicVolume.dragging.connect(_on_drag);
	masterVolume.drag_ended.connect(_on_drag);
	SFXVolume.drag_ended.connect(_on_drag);
	musicVolume.drag_ended.connect(_on_drag);
	
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
func _on_drag() -> void:
	# Await needed for values to update from drag_ended
	await get_tree().process_frame;
	# Audio
	AudioManager.masterVolume = masterVolume.value / 100;
	AudioManager.SFXVolume = SFXVolume.value / 100;
	AudioManager.musicVolume = musicVolume.value / 100;
	AudioManager.update_volume();
	# Camera
	cameraManager.playZoom = gameplayZoom.value / 100;
	cameraManager.followSpeed = followSpeed.value / 100;
	cameraManager.deadzone = cameraDeadzone.value;
	cameraManager.cameraPlayClamp = cameraClamp.value;
