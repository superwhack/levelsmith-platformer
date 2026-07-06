extends Panel

# General
@export var editorManager : Node2D;
@export var closeButton : Button;

# Volume
@export var masterVolume : VBoxContainer;
@export var SFXVolume : VBoxContainer;
@export var musicVolume : VBoxContainer;

func _ready() -> void:
	closeButton.pressed.connect(editorManager.close_settings_menu);
	
	# Set current default values
	masterVolume.value = AudioManager.masterVolume * 100;
	SFXVolume.value = AudioManager.SFXVolume * 100;
	musicVolume.value = AudioManager.musicVolume * 100;
	masterVolume.update_slider();
	SFXVolume.update_slider();
	musicVolume.update_slider();
	
	# Sliders connection
	masterVolume.dragging.connect(_on_drag);
	SFXVolume.dragging.connect(_on_drag);
	musicVolume.dragging.connect(_on_drag);

func _on_drag() -> void:
	
	AudioManager.masterVolume = masterVolume.value / 100;
	AudioManager.SFXVolume = SFXVolume.value / 100;
	AudioManager.musicVolume = musicVolume.value / 100;
	AudioManager.update_volume();
