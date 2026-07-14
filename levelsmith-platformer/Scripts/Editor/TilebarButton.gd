extends Button

# SourceID of this item
@export var thisItemID : int;
# Reference to the container this item is in
@export var tilebar : HBoxContainer;
# Option to enable/disable updating the texture
@export var isTextureUpdating : bool = false;
# Reference to the tile set
@onready var tileSet : TileSet = tilebar.tileMap.tile_set;

@export var isEntity : bool = false;

@export var entityName : String = "";

enum ButtonType {
	TILE,
	ENTITY,
	PROP
}

## The type of object this button selects.
@export var buttonType: ButtonType

@export var image : TextureRect;

func _ready() -> void:
	focus_entered.connect(select);
	pressed.connect(select);
	
	# If an entity, prop, or tile, add to appropriate array.
	match buttonType:
		ButtonType.TILE:
			tilebar.tileButtons.append(self);
		ButtonType.ENTITY:
			tilebar.entityButtons.append(self);
		ButtonType.PROP:
			tilebar.propButtons.append(self);

func _process(_delta: float) -> void:
	# Change the texture to the texture currently set in the tile set
	if (isTextureUpdating): 
		if(isEntity && entityName != ""):
			var templateAnimation : AnimatedSprite2D = AnimationManager.get(entityName + "TemplateSprite");
			image.texture = templateAnimation.sprite_frames.get_frame_texture(templateAnimation.animation, 0);
		else:
			image.texture = tileSet.get_source(thisItemID).texture;

## Select this button.
func select() -> void:
	if (!button_pressed):
		button_pressed = true;
	if (!has_focus()):
		grab_focus();
	
	# Remembers the last button selected, for focus purposes
	tilebar.remember_selected_button(self);
	
	AudioManager.play_UI_effect("UISelection");
	tilebar.toolManager.update_brush_object(thisItemID);
	
	
#func change_brush_object() -> void:
	#AudioManager.play_UI_effect("UISelection");
	#tilebar.toolManager.update_brush_object(thisItemID);
