extends Node

## References to other nodes
@export var editorManager: Node2D
@export var toolManager: Node2D
@export var entityManager: Node2D;

## Handles keyboard inputs.
## event: The input event to parse.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate"):
		toolManager.rotate_object();
	
	if event.is_action_pressed("brush-tool"):
		if (toolManager.prevEntity != -1):
			entityManager.drop_entity();
		toolManager.change_tool(Global.Tool.BRUSH);
		editorManager.change_current_hotbar(Global.HotbarState.TILES);

	elif event.is_action_pressed("box-brush-tool"):
		if (toolManager.prevEntity != -1):
			entityManager.drop_entity();
		toolManager.change_tool(Global.Tool.BOX_BRUSH);
		editorManager.change_current_hotbar(Global.HotbarState.TILES);

	elif event.is_action_pressed("cursor-tool"):
		toolManager.change_tool(Global.Tool.CURSOR);
	
	# Tile/Entity hotkeys
	match(editorManager.currentHotbarState):
		Global.HotbarState.TILES:
			if event.is_action_pressed("first-select"):
				toolManager.update_brush_object(Global.TileType.SOLID);
			elif event.is_action_pressed("second-select"):
				toolManager.update_brush_object(Global.TileType.ONEWAY);
			elif event.is_action_pressed("third-select"):
				toolManager.update_brush_object(Global.TileType.DEATH);
			elif event.is_action_pressed("fourth-select"):
				toolManager.update_brush_object(Global.TileType.ICE);
			elif event.is_action_pressed("fifth-select"):
				toolManager.update_brush_object(Global.TileType.STICKY);
			elif event.is_action_pressed("sixth-select"):
				toolManager.update_brush_object(Global.TileType.BOUNCE);
			elif event.is_action_pressed("seventh-select"):
				toolManager.update_brush_object(Global.TileType.SLOPE);
		Global.HotbarState.ENTITIES:
			if event.is_action_pressed("first-select"):
				toolManager.update_brush_object(Global.EntityType.GOAL);
			elif event.is_action_pressed("second-select"):
				toolManager.update_brush_object(Global.EntityType.PLAYER);
			elif event.is_action_pressed("third-select"):
				toolManager.update_brush_object(Global.EntityType.PATROLLING);
		Global.HotbarState.PROPS:
			if event.is_action_pressed("first-select"):
				toolManager.update_brush_object(Global.EntityType.PROP1);
			elif event.is_action_pressed("second-select"):
				toolManager.update_brush_object(Global.EntityType.PROP2);
			elif event.is_action_pressed("third-select"):
				toolManager.update_brush_object(Global.EntityType.PROP3);
			elif event.is_action_pressed("fourth-select"):
				toolManager.update_brush_object(Global.EntityType.PROP4);
			elif event.is_action_pressed("fifth-select"):
				toolManager.update_brush_object(Global.EntityType.PROP5);
