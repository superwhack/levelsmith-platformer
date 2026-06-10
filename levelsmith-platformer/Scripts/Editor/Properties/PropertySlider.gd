extends VBoxContainer

# Variables for different parts of the slider
@export var propertyName: String;
@export var nameLabel: Label; 
@export var slider: HSlider;
@export var label: Label;

@export var minMax: Vector2i;

# Signal to emit when the slider is done being dragged
signal drag_ended;

# Value of the slider
var value: float;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName;
	slider.min_value = minMax.x;
	slider.max_value = minMax.y;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	label.text = str(slider.value);
	value = slider.value;

## When drag is finished, emit drag ended signal
func _drag_ended(value_changed: bool) -> void:
	emit_signal("drag_ended");

## Update the slider value
func update_slider() -> void:
	slider.value = value;
