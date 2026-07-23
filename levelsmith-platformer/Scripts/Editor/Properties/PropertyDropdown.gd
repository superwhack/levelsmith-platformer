extends VBoxContainer

@export_group("Set in Dropdown Scene")
@export var nameLabel : Label; 
@export var optionButton : OptionButton;

@export_group("Set in Property Menu")
@export var propertyName : String;

signal dropdown_changed;

# Value of the CheckBox
var value : int;
# This enabled isn't used in anything yet, it's here for consistency with Slider and Toggle
var enabled = true;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName + ": ";
	optionButton.item_selected.connect(_option_selected);

## Update the dropdown's value
func update_dropdown() -> void:
	optionButton.select(value);

## Runs when the dropdown gets selected
func _option_selected(index: int) -> void:
	if !enabled:
		optionButton.value = value;
		return;
	value = index;
	dropdown_changed.emit();
