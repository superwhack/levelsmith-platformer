extends Panel
class_name SettingsMenu;

# General
@export var editorManager : Node2D;
@export var closeButton : Button;
@export var resetButton : Button;

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

var musicPreviewing = false;

func _ready() -> void:
	closeButton.pressed.connect(editorManager.close_settings_menu);
	resetButton.pressed.connect(reset_settings);
	
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
	masterVolume.dragging.connect(_on_dragging_SFX);
	SFXVolume.dragging.connect(_on_dragging_SFX);
	musicVolume.dragging.connect(_on_drag_start_music);
	masterVolume.drag_ended.connect(_on_dragging_SFX);
	SFXVolume.drag_ended.connect(_on_dragging_SFX);
	musicVolume.drag_ended.connect(_on_drag_end_music);
	
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

func _on_dragging_SFX() -> void:
	_on_drag();
	AudioManager.play_UI_effect("UISelection");
	
func _on_drag_end_music() -> void:
	_on_drag();
	await get_tree().process_frame;
	if musicPreviewing:
		musicPreviewing = false;
		AudioManager.stop_music_preview();

func _on_drag_start_music() -> void:
	_on_drag();
	if !musicPreviewing:
		musicPreviewing = true;
		AudioManager.play_music_preview("LevelMusic");

## Update sliders visually
func update_sliders() -> void:
	masterVolume.update_slider();
	SFXVolume.update_slider();
	musicVolume.update_slider();
	
	gameplayZoom.update_slider();
	followSpeed.update_slider();
	cameraDeadzone.update_slider();
	cameraClamp.update_checkbox();
	_on_drag();

## Reset the settings
func reset_settings() -> void:
	gameplayZoom.value = 100.0;
	followSpeed.value = 100.0;
	cameraDeadzone.value = 0.0;
	cameraClamp.value = false;
	
	masterVolume.value = 70.0;
	SFXVolume.value = 70.0;
	musicVolume.value = 70.0;
	update_sliders();
