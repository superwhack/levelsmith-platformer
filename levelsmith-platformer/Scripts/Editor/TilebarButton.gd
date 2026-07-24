extends Button

# SourceID of this item
@export var thisItemID : int;
# Reference to the container this item is in
@export var tilebar : HBoxContainer;
# Option to enable/disable updating the texture
@export var isTextureUpdating : bool = false;
# Reference to the tile set
@onready var tileSet : TileSet = tilebar.editorManager.tileMap.tile_set;
# Name of the entity this button selects (If it selects an entity)
@export var entityName : String = "";

enum ButtonType {
	TILE,
	ENTITY,
	PROP
}

## The type of object this button selects.
@export var buttonType: ButtonType

@export var buttonImage : TextureRect;

func _ready() -> void:
	focus_entered.connect(select.bind(false));
	pressed.connect(select);
	
	# If an entity, prop, or tile, add to appropriate array.
	match buttonType:
		ButtonType.TILE:
			tilebar.tileButtons.append(self);
		ButtonType.ENTITY:
			tilebar.entityButtons.append(self);
		ButtonType.PROP:
			tilebar.propButtons.append(self);

## Runs during the editor state and updates the texture.
func _process(_delta : float) -> void:
	if (!isTextureUpdating): return;
	
	# Change the texture to the first frame of the entity's default animation.
	if(buttonType == ButtonType.ENTITY && entityName != ""):
		var templateAnimation : AnimatedSprite2D = AnimationManager.get(entityName + "TemplateSprite");
		buttonImage.texture = templateAnimation.sprite_frames.get_frame_texture(templateAnimation.animation, 0);
	else:
		buttonImage.texture = tileSet.get_source(thisItemID).texture;

## Select this button.
func select(sound : bool = true) -> void:
	if (!button_pressed):
		button_pressed = true;
	if (!has_focus()):
		grab_focus();
	if (sound):
		AudioManager.play_UI_effect("UISelection");
	
	# Remembers the last button selected, for focus purposes
	tilebar.remember_selected_button(self);
	tilebar.toolManager.update_brush_object(thisItemID);
