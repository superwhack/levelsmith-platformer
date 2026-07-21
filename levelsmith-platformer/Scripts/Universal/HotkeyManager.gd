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
	if (editorManager.masterManager.state != Global.State.EDIT): return;
	
	if event.is_action_pressed("level_save"):
		editorManager.export_level();
	
	if event.is_action_pressed("rotate"):
		toolManager.rotate_object();
	if event.is_action_pressed("toggle-background"):
		toolManager.isBackground = !toolManager.isBackground;
	
	# Switching Tools
	if event.is_action_pressed("brush-tool"):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolSwitch.swap_to_brush();
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	elif event.is_action_pressed("box-brush-tool"):
		if (toolManager.prevBrushObject != -1):
			entityManager.drop_entity();
		toolSwitch.swap_to_box_brush();
		editorManager.change_current_hotbar(Global.HotbarState.TILES);
	elif event.is_action_pressed("cursor-tool"):
		toolSwitch.swap_to_cursor();
		# Selected id is 0 for entities and 1 for props;
		var dropdownState = tileSwitch.entityPropDropdown.get_selected_id();
		editorManager.change_current_hotbar(dropdownState + 1);
	
	# Tile/Entity hotkeys
	match(editorManager.currentHotbarState):
		Global.HotbarState.TILES:
			if event.is_action_pressed("first-select"):
				tileSwitch.tileButtons[0].select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.tileButtons[1].select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.tileButtons[2].select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.tileButtons[3].select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.tileButtons[4].select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.tileButtons[5].select();
			elif event.is_action_pressed("seventh-select"):
				tileSwitch.tileButtons[6].select();
			elif event.is_action_pressed("eighth-select"):
				tileSwitch.tileButtons[7].select();
		Global.HotbarState.ENTITIES:
			# Switch dropdown
			if (event.is_action_pressed("switch-entity-prop-dropdown")):
				tileSwitch.entity_dropdown_select(1);
			# Switch selected entity
			if event.is_action_pressed("first-select"):
				tileSwitch.entityButtons[0].select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.entityButtons[1].select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.entityButtons[2].select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.entityButtons[3].select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.entityButtons[4].select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.entityButtons[5].select();
			elif event.is_action_pressed("seventh-select"):
				tileSwitch.entityButtons[6].select();
			elif event.is_action_pressed("eighth-select"):
				tileSwitch.entityButtons[7].select();
			elif event.is_action_pressed("ninth-select"):
				tileSwitch.entityButtons[8].select();
		Global.HotbarState.PROPS:
			# Switch dropdown
			if (event.is_action_pressed("switch-entity-prop-dropdown")):
				tileSwitch.entity_dropdown_select(0);
			# Switch current selected prop
			if event.is_action_pressed("first-select"):
				tileSwitch.propButtons[0].select();
			elif event.is_action_pressed("second-select"):
				tileSwitch.propButtons[1].select();
			elif event.is_action_pressed("third-select"):
				tileSwitch.propButtons[2].select();
			elif event.is_action_pressed("fourth-select"):
				tileSwitch.propButtons[3].select();
			elif event.is_action_pressed("fifth-select"):
				tileSwitch.propButtons[4].select();
			elif event.is_action_pressed("sixth-select"):
				tileSwitch.propButtons[5].select();
