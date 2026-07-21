extends VBoxContainer

@export_group("Set in Toggle Scene")
@export var nameLabel : Label; 
@export var checkBox : CheckBox;

@export_group("Set in Property Menu")
@export var propertyName : String;

signal check_changed;

# Value of the CheckBox
var value : bool;
var enabled : bool = true;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName;
	checkBox.pressed.connect(_box_clicked);

## Update the checkbox value
func update_checkbox() -> void:
	checkBox.button_pressed = value;

## Runs when the checkbox gets pressed
func _box_clicked() -> void:
	if (!enabled):
		checkBox.button_pressed = value;
		return;
	value = checkBox.button_pressed;
	check_changed.emit();
