extends VBoxContainer

# Variables for different parts of the CheckBox
@export var propertyName: String;
@export var nameLabel: Label; 
@export var optionButton: OptionButton;

signal dropdown_changed;

# Value of the CheckBox
var value: bool;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName + ": ";
	optionButton.item_selected.connect(_option_selected);

## Update the checkbox value
func update_dropdown() -> void:
	optionButton.select(int(value));

## Runs when the checkbox gets pressed
func _option_selected(index: int) -> void:
	value = bool(index);
	emit_signal("dropdown_changed");
