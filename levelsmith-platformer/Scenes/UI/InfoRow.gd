extends HBoxContainer

@export_group("Buttons")
## A reference to the info button.
@export var infoButton : Button;

## A reference to the bug report button.
@export var bugButton : Button;

@export_group("Links")
## A string reference to the info link.
@export var infoLink : String;

## A string reference to the bug report form link.
@export var bugLink : String;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	infoButton.pressed.connect(_on_button_pressed.bind(infoLink));
	bugButton.pressed.connect(_on_button_pressed.bind(bugLink));


func _on_button_pressed(link: String) -> void:
	AudioManager.play_UI_effect("UISelection");
	OS.shell_open(str(link));
