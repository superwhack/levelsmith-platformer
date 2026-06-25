extends Control

# Master manager
@export var masterManager : Node2D;

# Main menu buttons
@export var buttonNewLevel : Button;
@export var buttonImportLevel : Button;
@export var buttonLoadExample : Button;
@export var buttonQuit : Button;

# Overlays
@export var overlayNewLevel : ColorRect;
@export var overlayImportLevel : ColorRect;

# New level overlay children
@export var buttonNewLevelCreate : Button;
@export var buttonNewLevelCancel : Button;
@export var fieldNewLevelName : LineEdit;
@export var spinBoxNewLevelX : SpinBox;
@export var spinBoxNewLevelY : SpinBox;

# Import level overlay children
@export var buttonImportLevelCancel : Button;
@export var buttonImportLevelOpen : Button;
@export var buttonImportLevelBrowse : TextureButton;
@export var fieldImportLevelPath : LineEdit;
@export var panelInvalidPath : PanelContainer;

@export var fileExplorer : FileDialog;

## A reference to the Level List for loading levels.
@export var LevelList : VBoxContainer;
## A reference to a packed scene of a clickable Level List Item.
@export var LevelListItem : PackedScene;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hides other screens
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	panelInvalidPath.hide();
	
	# Connect signals
	buttonNewLevel.pressed.connect( overlayNewLevel.show );
	buttonNewLevelCreate.pressed.connect( create_new_level );
	buttonNewLevelCancel.pressed.connect( overlayNewLevel.hide );
	
	buttonImportLevel.pressed.connect( overlayImportLevel.show );
	buttonImportLevelOpen.pressed.connect( import_level );
	buttonImportLevelCancel.pressed.connect( import_cancel );
	buttonImportLevelBrowse.pressed.connect( fileExplorer.popup_file_dialog );
	
	buttonQuit.pressed.connect( exit_program );
	
	# Fill the list of levels
	fill_level_list();
	
## Called when import level button is pressed
func import_level() -> void:
	panelInvalidPath.show();

## Called when import level is closed
func import_cancel() -> void:
	overlayImportLevel.hide();
	panelInvalidPath.hide();

## Opens the menu for setting a name and size for the level
func create_new_level() -> void:
	if (fieldNewLevelName.text.strip_edges().is_empty()):
		PopUpManager.create_error_popup("Creation Failed!", "Level has no name!");
		return;
	overlayNewLevel.hide();
	masterManager.level_setup( 
		fieldNewLevelName.text, 
		Vector2i( 
			int(spinBoxNewLevelX.value), 
			int(spinBoxNewLevelY.value) 
			) 
		);

## Exits the program
func exit_program() -> void:
	get_tree().quit();
	
## Fills the level list with currently existing levels from the user's directory.
func fill_level_list() -> void:
	# First, kill everything inside of the list. Makes refreshing easy
	for item in LevelList.get_children():
		item.queue_free();
		
	# Get the directory that contains all the level folders
	var levelsPath : String = "user://Levels"
	var levelListDir : DirAccess = DirAccess.open(levelsPath);
	
	levelListDir.list_dir_begin();
	
	var folderName : String = levelListDir.get_next();
	
	var iteration : int = 0;
	# So long as the folder name is not null...
	while folderName != "":
		if (levelListDir.current_is_dir() and not folderName.begins_with(".")):
			# Getting and creating the level list item
			var levelPath : String = levelsPath + "/" + folderName;
			var item = LevelListItem.instantiate();
			LevelList.add_child(item);

			# Setting the level list item data
			item.levelTitle.text = folderName;
			
			# Get the csv level size, and add it to the level item
			var levelSize : Vector2i = get_csv_size(levelPath + "/" + "Tiles.CSV");
			item.levelSize.text = (str(levelSize.x) + "x" + str(levelSize.y));
			
			
			# If the thumbnail file exists, replace image (or don't)
			var levelThumbnailPath : String = levelPath + "/thumbnail.png";
			
			if (FileAccess.file_exists(levelThumbnailPath)):
				var image := Image.new();
				
				# If the image returns no error, replace the texture
				if (image.load(levelThumbnailPath) == OK):
					var texture := ImageTexture.create_from_image(image)
					item.levelThumbnail.texture = texture;
				else:
					print("Failed to load image: ", levelThumbnailPath);

			if (iteration % 2 == 1):
				item.buttonColor = item.ButtonColor.WHITE;
			else:
				item.buttonColor = item.ButtonColor.BLUE;
			item.apply_colors();
				
			# Get the next folder
			folderName = levelListDir.get_next();
			iteration += 1;

## Retrieves the world size from a CSV file.
## filePath: the file path of the CSV file.
## Returns a Vector2i of the world size.
func get_csv_size(filePath : String) -> Vector2i: 
	var rows = [];
	var file = FileAccess.open(filePath, FileAccess.READ);
	
	# If the file exists, append rows. If not, return an empty Vector2i
	# for backwards compatibility on folders without a CSV.
	if file != null:
		while not file.eof_reached():
			rows.append(file.get_csv_line());
	else:
		return Vector2i.ZERO;

	# Height is the number of rows we have
	var height = rows.size();
	var width = 0;
	
	# So long as there is one row, get the size of it as width
	if height > 0:
		width = rows[0].size();

	return Vector2i(width, height);
