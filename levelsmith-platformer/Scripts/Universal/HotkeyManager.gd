extends Node

## References to other nodes
@export var editorManager : Node2D
@export var toolManager : Node2D
@export var entityManager : Node2D;
@export var tileSwitch : BoxContainer;
@export var toolSwitch : BoxContainer;

## Handles keyboard inputs.
## event: The input event to parse.
func _unhandled_key_input(event : InputEvent) -> void:
	# Runs the level so long as we aren't in a line edit box.
	if (event.is_action_pressed("enter")):
		if (!get_viewport().gui_get_focus_owner() is LineEdit && editorManager.masterManager.state == Global.State.EDIT):
			editorManager.masterManager.play();

			
	# If not in edit mode, return
	if (editorManager.masterManager.state != Global.State.EDIT): return;
	# If level save button is pressed, call the editorManager's export function
	if (event.is_action_pressed("level_save")):
		editorManager.export_level();
	# If the rotate button is pressed, call the toolManager's rotate_object function
	if (event.is_action_pressed("rotate")):
		toolManager.rotate_object();
	# If the toggle background button is pressed, toggle the toolManager's isBackground 
	if (event.is_action_pressed("toggle-background")):
		toolManager.isBackground = !toolManager.isBackground;
		
	
	# Switching Tools
	# When switching to the brush tool, drops the entity being held, switches the tool and sets the hotbar
	if (event.is_action_pressed("brush-tool")):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolSwitch.swap_to_brush();
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	# When switching to the box brush tool, drops the entity being held, switches the tool and sets the hotbar
	elif (event.is_action_pressed("box-brush-tool")):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolSwitch.swap_to_box_brush();
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	# When switching to the cursor tool, call toolSwitch's swap_to_cursor function and set the dropdown state
	elif (event.is_action_pressed("cursor-tool")):
		toolSwitch.swap_to_cursor();
		# Selected id is 0 for entities and 1 for props;
		var dropdownState = tileSwitch.entityPropDropdown.get_selected_id();
		editorManager.change_current_hotbar(dropdownState + 1);
	
	# Tile/Entity hotkeys
	match(editorManager.currentHotbarState):
		# If in the tile hotbar state, set the selected tile to the hotkey input
		Global.HotbarState.TILES:
			if (event.is_action_pressed("first-select")):
				tileSwitch.tileButtons[0].select();
			elif (event.is_action_pressed("second-select")):
				tileSwitch.tileButtons[1].select();
			elif (event.is_action_pressed("third-select")):
				tileSwitch.tileButtons[2].select();
			elif (event.is_action_pressed("fourth-select")):
				tileSwitch.tileButtons[3].select();
			elif (event.is_action_pressed("fifth-select")):
				tileSwitch.tileButtons[4].select();
			elif (event.is_action_pressed("sixth-select")):
				tileSwitch.tileButtons[5].select();
			elif (event.is_action_pressed("seventh-select")):
				tileSwitch.tileButtons[6].select();
			elif (event.is_action_pressed("eighth-select")):
				tileSwitch.tileButtons[7].select();
		# If in the entity hotbar state, set the selected tile to the hotkey input
		Global.HotbarState.ENTITIES:
			# Switch dropdown
			if (event.is_action_pressed("switch-entity-prop-dropdown")):
				tileSwitch.entity_dropdown_select(1);
			# Switch selected entity
			if (event.is_action_pressed("first-select")):
				tileSwitch.entityButtons[0].select();
			elif (event.is_action_pressed("second-select")):
				tileSwitch.entityButtons[1].select();
			elif (event.is_action_pressed("third-select")):
				tileSwitch.entityButtons[2].select();
			elif (event.is_action_pressed("fourth-select")):
				tileSwitch.entityButtons[3].select();
			elif (event.is_action_pressed("fifth-select")):
				tileSwitch.entityButtons[4].select();
			elif (event.is_action_pressed("sixth-select")):
				tileSwitch.entityButtons[5].select();
			elif (event.is_action_pressed("seventh-select")):
				tileSwitch.entityButtons[6].select();
			elif (event.is_action_pressed("eighth-select")):
				tileSwitch.entityButtons[7].select();
			elif (event.is_action_pressed("ninth-select")):
				tileSwitch.entityButtons[8].select();
		# If in the prop hotbar state, set the selected prop to the hotkey input
		Global.HotbarState.PROPS:
			# Switch dropdown
			if (event.is_action_pressed("switch-entity-prop-dropdown")):
				tileSwitch.entity_dropdown_select(0);
			# Switch current selected prop
			if (event.is_action_pressed("first-select")):
				tileSwitch.propButtons[0].select();
			elif (event.is_action_pressed("second-select")):
				tileSwitch.propButtons[1].select();
			elif (event.is_action_pressed("third-select")):
				tileSwitch.propButtons[2].select();
			elif (event.is_action_pressed("fourth-select")):
				tileSwitch.propButtons[3].select();
			elif (event.is_action_pressed("fifth-select")):
				tileSwitch.propButtons[4].select();
			elif (event.is_action_pressed("sixth-select")):
				tileSwitch.propButtons[5].select();
