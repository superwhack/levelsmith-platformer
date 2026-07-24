extends HBoxContainer

# Reference to tool manager
@export var toolManager : Node2D;
@export var editorManager : Node2D;

# References to button bars
@export var tilePanel : PanelContainer;
@export var entityPanel : PanelContainer;

# References to tabs in Entity picker
@export var entityTab : HBoxContainer;
@export var propTab : HBoxContainer;

# Misc object references
@export var entityPropDropdown : OptionButton;

# Buttons will save themselves into these arrays on creation.
var tileButtons : Array[Button] = [];
var entityButtons : Array[Button] = [];
var propButtons : Array[Button] = [];

# Last tile, entity, and prop buttons.
@onready var lastTileButton : Button = tileButtons[0];
@onready var lastEntityButton : Button = entityButtons[0];
@onready var lastPropButton : Button = propButtons[0];

func _ready() -> void:
	entityPropDropdown.item_selected.connect(entity_dropdown_select);
	entityPropDropdown.get_popup().add_theme_constant_override("v_separation", 20);

## Toggles visibility of tile selection bar
## visibility: desired visibility
func display_tiles(visibility : bool):
	tilePanel.visible = visibility;
	print(entityButtons)
	# If visible, select button if last applicable, otherwise the first.
	if (visibility):
		if (lastTileButton):
			lastTileButton.select(false);

## Toggles visibility of entity selection bar
## visibility: desired visibility
func display_entities(visibility : bool):
	entityPanel.visible = visibility;
	if (visibility):
		match (editorManager.currentHotbarState):
			Global.HotbarState.ENTITIES:
				lastEntityButton.select(false);
			Global.HotbarState.PROPS:
				lastPropButton.select(false);

## Toggles visibility of tabs
## index: index of tab selected
func entity_dropdown_select(index : int):
	AudioManager.play_UI_effect("UISelection");
	match index:
		0:
			entityPropDropdown.select(index);
			editorManager.change_current_hotbar(Global.HotbarState.ENTITIES);
			toolManager.currentObjectRotation = 0;
			entityTab.visible = true;
			propTab.visible = false;
			lastEntityButton.select(false);
		1:
			entityPropDropdown.select(index);
			editorManager.change_current_hotbar(Global.HotbarState.PROPS);
			entityTab.visible = false;
			propTab.visible = true;
			lastPropButton.select(false);

## Sets the last selected button, so that it remains selected
func remember_selected_button(button: Button):
	match (button.buttonType):
		button.ButtonType.TILE:
			lastTileButton = button;
		button.ButtonType.ENTITY:
			lastEntityButton = button;
		button.ButtonType.PROP:
			lastPropButton = button;
