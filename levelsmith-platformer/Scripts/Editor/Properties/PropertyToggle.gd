extends VBoxContainer

# Variables for different parts of the CheckBox
@export var propertyName: String;
@export var nameLabel: Label; 
@export var checkBox: CheckBox;

signal check_changed;

# Value of the CheckBox
var value: bool;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName;
	checkBox.pressed.connect(_box_clicked);

## Update the checkbox value
func update_checkbox() -> void:
	checkBox.button_pressed = value;

## Runs when the checkbox gets pressed
func _box_clicked() -> void:
	value = checkBox.button_pressed;
	check_changed.emit();
