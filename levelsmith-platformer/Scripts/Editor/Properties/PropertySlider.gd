extends VBoxContainer

# Variables for different parts of the slider
@export var propertyName: String;
@export var nameLabel: Label; 
@export var slider: HSlider;
@export var label: Label;

@export var minMax: Vector2;
@export var sliderStep: float;
@export var valueAppend: String;

# Signal to emit when the slider is done being dragged
signal drag_ended;

# Value of the slider
var value: float;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName;
	slider.min_value = snapped(minMax.x, 0.01);
	slider.max_value = snapped(minMax.y, 0.01);
	slider.step = sliderStep;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var newLabel = "";
	if int(sliderStep) == sliderStep:
		newLabel += str(int(slider.value));
	else:
		newLabel += str(slider.value);
	if valueAppend:
		newLabel += valueAppend;
	label.text = newLabel;
	value = slider.value;

## When drag is finished, emit drag ended signal
func _drag_ended(value_changed: bool) -> void:
	emit_signal("drag_ended");

## Update the slider value
func update_slider() -> void:
	slider.value = value;
