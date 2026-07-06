extends Panel

@export var closeButton : Button;

@export var masterVolume : VBoxContainer;
@export var SFXVolume : VBoxContainer;
@export var musicVolume : VBoxContainer;

func _ready() -> void:
	closeButton.pressed.connect(close_menu);
	
	# Sliders connection
	masterVolume.drag_ended.connect(_on_drag_ended);
	SFXVolume.drag_ended.connect(_on_drag_ended);
	musicVolume.drag_ended.connect(_on_drag_ended);

func close_menu() -> void:
	hide();

func _on_drag_ended() -> void:
	AudioManager.masterVolume = masterVolume.value;
	AudioManager.SFXVolume = SFXVolume.value;
	AudioManager.musicVolume = musicVolume.value;
