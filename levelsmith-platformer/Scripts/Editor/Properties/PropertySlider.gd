extends VBoxContainer

# Variables for different parts of the slider
@export var propertyName : String;
@export var nameLabel : Label; 
@export var slider : HSlider;
@export var textField : TextEdit;
@export var minLabel : Label;
@export var maxLabel : Label;

@export var minMax : Vector2;
@export var sliderStep : float;
@export var valueAppend : String;

# Signal to emit when the slider is done being dragged
signal drag_ended;

# Value of the slider
var value : float;
var enabled : bool = true;

## When started, set the text of the name label to the name of the property
func _ready() -> void:
	nameLabel.text = propertyName;
	slider.min_value = snapped(minMax.x, 0.01);
	slider.max_value = snapped(minMax.y, 0.01);
	slider.step = sliderStep;
	slider.drag_ended.connect(_drag_ended);
	textField.focus_entered.connect(_text_change_begins);
	textField.focus_exited.connect(_text_change_ended);
	minLabel.text = str(snapped(minMax.x, .01));
	maxLabel.text = str(snapped(minMax.y, .01));
	# Just so _process runs once
	value = slider.value + 1;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("enter"):
		textField.release_focus();
	if !enabled:
		slider.value = value;
		return;
	if value == slider.value:
		return;
	var newLabel = "";
	if int(sliderStep) == sliderStep:
		newLabel += str(int(slider.value));
	else:
		newLabel += str(slider.value);
	if valueAppend:
		newLabel += valueAppend;
	textField.text = newLabel;
	value = slider.value;

## When drag is finished, emit drag ended signal
func _drag_ended(_value_changed: bool) -> void:
	drag_ended.emit();
	
func _text_change_begins() -> void:
	textField.placeholder_text = textField.text;
	textField.text = "";

func _text_change_ended() -> void:
	slider.value = float(textField.text);
	textField.text = "";
	drag_ended.emit();

## Update the slider value
func update_slider() -> void:
	slider.value = value;
