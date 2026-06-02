extends Panel

# Entity currently selected for editing
var selectedEntity: Node2D;

# Name displayed on property menu
@export var entityName: Label;

# Player values
var playerSpeed: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerFallSpeed : float;
var playerCoyoteTime : float;

# Player value sliders
@export var playerSpeedSlider: HSlider;
@export var playerJumpSlider: HSlider;
@export var playerAirControlSlider: HSlider;
@export var playerFallSpeedSlider: HSlider;
@export var playerCoyoteTimeSlider: HSlider;

# Preset Options
@export var presetOptions: OptionButton;
var selectedPreset: Resource;

## When this starts, select the default option
func _ready() -> void:
	_on_preset_options_item_selected(0);

## Close the property menu and set the selected entity to null
func close() -> void:
	hide();
	selectedEntity = null;

func _process(delta: float) -> void:
	# If there is a selected entity, set the name in the property menu, otherwise close
	if (selectedEntity != null):
		entityName.text = selectedEntity.name;
		update_sliders();
		update_labels();
	else:
		hide();

## When the speed slider changes set the player's speed
func _on_speed_changed(value: float) -> void:
	playerSpeed = value;

## When the jump slider changes, set the player's jump height
## value: The value set to the slider
func _on_jump_changed(value: float) -> void:
	playerJumpHeight = value;

## When the air control slider changes, set the player's air control
## value: The value set to the slider
func _on_air_control_slider_value_changed(value: float) -> void:
	playerAirControl = value;

## When the fall speed slider changes, set the player's fall speed
## value: The value set to the slider
func _on_fall_speed_changed(value: float) -> void:
	playerFallSpeed = value;

## When the coyote time slider changes, set the player's coyote time
## value: The value set to the slider
func _on_coyote_time_changed(value: float) -> void:
	playerCoyoteTime = value;

## When a preset option is selected, load that preset and set all values to that preset
## index: the index of the preset selected
func _on_preset_options_item_selected(index: int) -> void:
	selectedPreset = load("res://Resources/PlayerPresets/" + presetOptions.get_item_text(index) + ".tres")
	playerSpeed = selectedPreset.groundSpeed;
	playerJumpHeight = selectedPreset.jumpHeight;
	playerAirControl = selectedPreset.airControl;
	playerFallSpeed = selectedPreset.fallSpeed;
	playerCoyoteTime = selectedPreset.coyoteTime;

## Load and update the custom preset, then save its changes
func update_custom() -> void:
	var customPreset = load("res://Resources/PlayerPresets/Custom.tres");
	customPreset.groundSpeed = playerSpeed;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerFallSpeed;
	customPreset.coyoteTime = playerCoyoteTime;
	ResourceSaver.save(customPreset, "res://Resources/PlayerPresets/Custom.tres");

## Update all sliders according to the values
func update_sliders() -> void:
	playerSpeedSlider.value = playerSpeed;
	playerJumpSlider.value = playerJumpHeight;
	playerAirControlSlider.value = playerAirControl;
	playerFallSpeedSlider.value = playerFallSpeed;
	playerCoyoteTimeSlider.value = playerCoyoteTime;

## When the slider is finished dragging, update the custom preset and switch to this preset
func _on_drag_ended(value_changed: bool) -> void:
	update_custom();
	presetOptions.select(4);
	_on_preset_options_item_selected(4);

func update_labels() -> void:
	playerSpeedSlider.get_node("../Label").text = str(playerSpeedSlider.value);
	playerJumpSlider.get_node("../Label").text = str(playerJumpSlider.value);
	playerAirControlSlider.get_node("../Label").text = str(playerAirControlSlider.value);
	playerFallSpeedSlider.get_node("../Label").text = str(playerFallSpeedSlider.value);
	playerCoyoteTimeSlider.get_node("../Label").text = str(playerCoyoteTimeSlider.value);
