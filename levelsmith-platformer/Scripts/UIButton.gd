extends PanelContainer

@onready var button: Button = $Button
@onready var icon: TextureRect = $TextureRect

@export var panel_default: StyleBox
@export var panel_hover: StyleBox
@export var panel_selected: StyleBox

var _hovered := false

func _ready() -> void:
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.toggle_mode = true # remove if you do not need selected/persistent state

	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.toggled.connect(_on_toggled) # use pressed if not toggle_mode

	_apply_visual_state()

func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()

func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()

func _on_toggled(_pressed: bool) -> void:
	_apply_visual_state()

func _apply_visual_state() -> void:
	# Priority: selected > hover > default
	if button.button_pressed:
		panel.add_theme_stylebox_override("panel", panel_selected)
	elif _hovered:
		panel.add_theme_stylebox_override("panel", panel_hover)
	else:
		panel.add_theme_stylebox_override("panel", panel_default)
