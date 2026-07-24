extends VBoxContainer

@export_group("Buttons")
## A reference to the Steam button.
@export var steamButton : Button;

## A reference to the itch.io button.
@export var itchButton : Button;

## A reference to the website button.
@export var websiteButton : Button;

## A reference to our GitHub button.
@export var githubButton : Button;

@export_group("Links")
## A string reference to the steam link.
@export var steamLink : String;

## A string reference to the itch link.
@export var itchLink : String;

## A string reference to the website link.
@export var websiteLink : String;

## A string reference to the github link.
@export var githubLink: String;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	steamButton.pressed.connect(_on_button_pressed.bind(steamLink));
	itchButton.pressed.connect(_on_button_pressed.bind(itchLink));
	websiteButton.pressed.connect(_on_button_pressed.bind(websiteLink));
	githubButton.pressed.connect(_on_button_pressed.bind(githubLink));


func _on_button_pressed(link: String) -> void:
	OS.shell_open(str(link));
