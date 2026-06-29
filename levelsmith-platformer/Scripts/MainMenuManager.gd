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

@export var fileExplorer : FileDialog;
var importedLevelPath : String;

## A reference to the Level List for loading levels.
@export var levelList : GridContainer;
## A reference to a packed scene of a clickable Level List Item.
@export var levelListItem : PackedScene;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hides other screens
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	
	# Connect signals
	buttonNewLevel.pressed.connect(overlayNewLevel.show);
	buttonNewLevelCreate.pressed.connect(create_new_level);
	buttonNewLevelCancel.pressed.connect(overlayNewLevel.hide);
	buttonImportLevel.pressed.connect(overlayImportLevel.show);
	buttonImportLevelOpen.pressed.connect(import_level);
	buttonImportLevelCancel.pressed.connect(import_cancel);
	buttonImportLevelBrowse.pressed.connect(fileExplorer.popup_file_dialog);
	buttonQuit.pressed.connect(exit_program);

	# Fill the list of levels
	fill_level_list();
	
	var set_directory = func (directory: String) -> void:
		importedLevelPath = directory;
		fieldImportLevelPath.text = importedLevelPath;
	
	fileExplorer.dir_selected.connect(set_directory);
	
## Called when import level button is pressed
func import_level() -> void:
	if (!ImportExportManager.validate_import(importedLevelPath)): return;
	
	# Extract the name of the folder from the file path
	var importedLevelArray : Array = importedLevelPath.split("/");
	var importedLevelName : String = importedLevelArray[importedLevelArray.size() - 1];
	var importDirectory : String = "user://Levels/" + importedLevelName + "/";
	
	if !DirAccess.dir_exists_absolute(importDirectory):
		DirAccess.make_dir_absolute(importDirectory);
		ImportExportManager.clone_data(importedLevelPath + "/", importDirectory);
	masterManager.import_level_and_edit();
	
	# Resets the ui overlay
	fieldImportLevelPath.clear();
	overlayImportLevel.hide();
	pass;

## Called when import level is closed
func import_cancel() -> void:
	overlayImportLevel.hide();

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
	for item in levelList.get_children():
		item.queue_free();
		
	# Get the directory that contains all the level folders
	var levelsPath : String = "user://Levels"
	var levelListDir : DirAccess = DirAccess.open(levelsPath);
	
	levelListDir.list_dir_begin();
	
	var folderName : String = levelListDir.get_next();
	
	# So long as the folder name is not null...
	while folderName != "":
		if (levelListDir.current_is_dir()):
			# Getting and creating the level list item
			var levelPath : String = levelsPath + "/" + folderName;
			
			# Add the level to the level list and set it up visually.
			if (get_level_valid(levelPath)):
				setup_level_item(folderName, levelPath);

		folderName = levelListDir.get_next();

## Setups each level item in the list.
## folderName: the folder of the level. Used for level title.
## levelPath: the path of the level.
func setup_level_item(folderName : String, levelPath : String) -> void:
	# Instantiate and add to level list.
	var item = levelListItem.instantiate();
	levelList.add_child(item);
	item.levelPath = levelPath + "/";

	# Setting the level list item data
	item.levelTitle.text = folderName;
	item.levelButton.tooltip_text = folderName; 
	
	# Connect the level button signal to the double clicked function
	item.level_double_clicked.connect(_on_level_double_clicked);
	
	# Get the csv level size, and add it to the level item
	var levelSize : Vector2i = get_csv_size(levelPath + "/" + "Tiles.CSV");
	item.levelSize.text = "size: [" + (str(levelSize.x) + "," + str(levelSize.y) + "]");
	
	# If the thumbnail file exists, replace image (or don't)
	var levelThumbnailPath : String = levelPath + "/thumbnail.png";
	
	if (FileAccess.file_exists(levelThumbnailPath)):
		var image : Image = Image.new();
		
		# If the image returns ok, replace the texture
		if (image.load(levelThumbnailPath) == OK):
			var texture := ImageTexture.create_from_image(image)
			item.levelThumbnail.texture = texture;


## Load a level when appropriate button is pressed
## path: The path of the level to be loaded.
func _on_level_double_clicked(path: String) -> void:
	masterManager.load_level(path);

## Retrieves the world size from a CSV file.
## filePath: the file path of the CSV file.
## Returns a Vector2i of the world size.
func get_csv_size(filePath : String) -> Vector2i: 
	var rows = [];
	var file = FileAccess.open(filePath, FileAccess.READ);
	
	# If the file exists, append rows. If not, return an empty Vector2i
	if (file != null):
		while not file.eof_reached():
			# Since CSV files have trailing empty lines, we need to check if 
			# the line has any data in it.
			var currentRow = file.get_csv_line();
			if (currentRow.size() > 0 && currentRow[0] != ""):
				rows.append(currentRow);
	else:
		return Vector2i.ZERO;

	# Height is the number of rows we have
	var height = rows.size();
	var width = 0;
	
	# So long as there is one row, get the size of it as width
	if height > 0:
		width = rows[0].size();

	return Vector2i(width, height);
	
## Checks if a level folder is valid with the correct files.
## filePath: The file path of the folder.
## Returns a bool based on the folder being valid.
func get_level_valid(filePath : String) -> bool:
	if (!FileAccess.file_exists(filePath)):
		# Check if settings file doesn't exist
		if (!FileAccess.file_exists(filePath + "/Settings.json")):
			return false;
			
		# Check if CSV file doesn't exist
		if (!FileAccess.file_exists(filePath + "/Tiles.CSV")):
			return false;
	return true;
