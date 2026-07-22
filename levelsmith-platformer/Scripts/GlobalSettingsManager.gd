extends Panel
class_name GlobalSettingsMenu;

# General
@export var masterManager : Node2D;
@export var closeButton : Button;
@export var resetButton : Button;

var settingsPath := "user://settings.cfg";

# Volume
@export var masterVolume : VBoxContainer;
@export var SFXVolume : VBoxContainer;
@export var musicVolume : VBoxContainer;

var musicPreviewing := false;

const BASE_VOLUME_VALUE : float = 70.0;

func _ready() -> void:
	closeButton.pressed.connect(masterManager.close_global_settings_menu);
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
	
	load_settings();

func _process(_delta: float) -> void:
	pass;

## When closed with esc, close with mastermanager
func _input( event: InputEvent ) -> void:
	if (event.is_action_pressed("ui_close_dialog")):
		masterManager.close_global_settings_menu();

## When dragging, adjust the values in real time
func _on_drag() -> void:
	# Await needed for values to update from drag_ended
	await get_tree().process_frame;
	
	save_settings();
	# Audio
	AudioManager.masterVolume = masterVolume.value / 100;
	AudioManager.SFXVolume = SFXVolume.value / 100;
	AudioManager.musicVolume = musicVolume.value / 100;
	AudioManager.update_volume();

## Every time the SFX slider gets adjusted, play a sound as a demo
func _on_dragging_SFX() -> void:
	_on_drag();
	AudioManager.play_UI_effect("UISelection");

## When drag on music slider ends, it stops if 1.5seconds has based, checked in AudioMaager
func _on_drag_end_music() -> void:
	_on_drag();
	await get_tree().process_frame;
	if musicPreviewing:
		musicPreviewing = false;
		AudioManager.stop_music_preview();

## When dragging music, start playing a demo while it's held down.
func _on_drag_start_music() -> void:
	_on_drag();
	if (!musicPreviewing):
		musicPreviewing = true;
		AudioManager.play_music_preview("LevelMusic");

## Update sliders visually
func update_sliders() -> void:
	masterVolume.update_slider();
	SFXVolume.update_slider();
	musicVolume.update_slider();
	
	_on_drag();

## Reset the settings
func reset_settings() -> void:
	masterVolume.value = BASE_VOLUME_VALUE;
	SFXVolume.value = BASE_VOLUME_VALUE;
	musicVolume.value = BASE_VOLUME_VALUE;
	update_sliders();

## Load the settings from a config file, create the file if needed
func load_settings() -> void:
	if FileAccess.file_exists(settingsPath):
		var configFile = ConfigFile.new();
		configFile.load(settingsPath);
		masterVolume.value = configFile.get_value("Audio", "master_volume");
		SFXVolume.value = configFile.get_value("Audio", "sfx_volume");
		musicVolume.value = configFile.get_value("Audio", "music_volume");
		update_sliders();

## Save current settings in the config file
func save_settings() -> void:
	var configFile = ConfigFile.new();
	configFile.set_value("Audio", "master_volume", masterVolume.value);
	configFile.set_value("Audio", "sfx_volume", SFXVolume.value);
	configFile.set_value("Audio", "music_volume", musicVolume.value);
	configFile.save(settingsPath);
