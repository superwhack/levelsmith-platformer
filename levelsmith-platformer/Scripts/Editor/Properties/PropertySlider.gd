extends VBoxContainer

# Variables for different parts of the slider
@export_group("Set in Slider Scene")
@export var nameLabel : Label;
@export var unit : Label; 
@export var slider : HSlider;
@export var textField : TextEdit;
@export var minLabel : Label;
@export var maxLabel : Label;

@export_group("Set in Property Menu")
@export var propertyName : String;
@export var propertyUnit : String;
@export var minMax : Vector2;
@export var sliderStep : float;
@export var valueAppend : String;

# Signal to emit when the slider is done being dragged
signal drag_ended;

# Signal to emit while the slider is being dragged
signal dragging;

# Value of the slider
var value : float;
var enabled : bool = true;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	slider.rounded = false;
	nameLabel.text = propertyName;
	unit.text = "(" + propertyUnit + ")";
	
	# Use min and max values to determine the extremes
	slider.min_value = snapped(minMax.x, 0.01);
	slider.max_value = snapped(minMax.y, 0.01);
	slider.step = sliderStep;
	minLabel.text = str(snapped(minMax.x, .01));
	maxLabel.text = str(snapped(minMax.y, .01));
	
	# Connect signals
	slider.drag_ended.connect(_drag_ended);
	textField.text_changed.connect(_validate_length);
	textField.focus_entered.connect(_text_change_begins);
	textField.focus_exited.connect(_text_change_ended);
	
	adjust_label();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Enter to confirm when focused
	if Input.is_action_just_pressed("enter"):
		textField.release_focus();
	if (!enabled):
		slider.value = value;
		return;
	if value == slider.value:
		return;
	# If enabled and the value changed, adjust accordingly
	dragging.emit();
	adjust_label();
	value = slider.value;

## When drag is finished, emit drag ended signal
func _drag_ended(_value_changed: bool) -> void:
	drag_ended.emit();

## When the text change beings, clear the text and make the placeholder text what was the text
## this makes it easy to edit
func _text_change_begins() -> void:
	# Await so that text cannot get selected and stay in the field after focus is entered
	await get_tree().process_frame;
	textField.placeholder_text = textField.text;
	textField.text = "";

## When the change is over, verify it then change the value and adjust labels
func _text_change_ended() -> void:
	# Replace is needed since enter also puts a newline into the text field
	textField.text = textField.text.replace("\n", "");
	# If it's invalid, return to previous value
	if (!textField.text.is_valid_float()):
		textField.text = textField.placeholder_text;
	slider.value = float(textField.text);
	adjust_label();
	drag_ended.emit();

const MAX_LENGTH : int = 4;
## Validate the length of the current string
func _validate_length() -> void:
	if (textField.has_focus() && textField.text.length() > MAX_LENGTH):
		textField.text = textField.text.substr(0, MAX_LENGTH);
		textField.set_caret_column(MAX_LENGTH);

## Update the slider value
func update_slider() -> void:
	slider.value = value;
	adjust_label();

## Change the label, adding in appended values or changing the type to int or float
func adjust_label() -> void:
	var newLabel = "";
	if (int(sliderStep) == sliderStep):
		newLabel += str(int(slider.value));
	else:
		newLabel += str(slider.value);
	if (valueAppend):
		newLabel += valueAppend;
	textField.text = newLabel;
