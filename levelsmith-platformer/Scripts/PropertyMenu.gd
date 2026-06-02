extends Panel

# Entity currently selected for editing
var selectedEntity: Node2D;

# Name displayed on property menu
@export var entityName: Label;

@export var playerProperties: VBoxContainer;
var playerSpeed: float;
var playerJumpHeight : float;
var playerAirControl : float;
var playerFallSpeed : float;
var playerCoyoteTime : float;

@export var playerSpeedSlider: HSlider;
@export var playerJumpSlider: HSlider;
@export var playerAirControlSlider: HSlider;
@export var playerFallSpeedSlider: HSlider;
@export var playerCoyoteTimeSlider: HSlider;


@export var presetOptions: OptionButton;
var selectedPreset: Resource;

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
	else:
		hide();


func _on_speed_changed(value: float) -> void:
	playerSpeed = value;

func _on_jump_changed(value: float) -> void:
	playerJumpHeight = value;

func _on_air_control_slider_value_changed(value: float) -> void:
	playerAirControl = value;

func _on_fall_speed_changed(value: float) -> void:
	playerFallSpeed = value;

func _on_coyote_time_changed(value: float) -> void:
	playerCoyoteTime = value;

func _on_preset_options_item_selected(index: int) -> void:
	selectedPreset = load("res://Resources/PlayerPresets/" + presetOptions.get_item_text(index) + ".tres")
	playerSpeed = selectedPreset.groundSpeed;
	playerJumpHeight = selectedPreset.jumpHeight;
	playerAirControl = selectedPreset.airControl;
	playerFallSpeed = selectedPreset.fallSpeed;
	playerCoyoteTime = selectedPreset.coyoteTime;
	
func update_custom() -> void:
	var customPreset = load("res://Resources/PlayerPresets/Custom.tres");
	customPreset.groundSpeed = playerSpeed;
	customPreset.jumpHeight = playerJumpHeight;
	customPreset.airControl = playerAirControl;
	customPreset.fallSpeed = playerFallSpeed;
	customPreset.coyoteTime = playerCoyoteTime;
	ResourceSaver.save(customPreset, "res://Resources/PlayerPresets/Custom.tres");

func update_sliders() -> void:
	playerSpeedSlider.value = playerSpeed;
	playerJumpSlider.value = playerJumpHeight;
	playerAirControlSlider.value = playerAirControl;
	playerFallSpeedSlider.value = playerFallSpeed;
	playerCoyoteTimeSlider.value = playerCoyoteTime;


func _on_drag_ended(value_changed: bool) -> void:
	update_custom();
	presetOptions.select(4);
	_on_preset_options_item_selected(4);
