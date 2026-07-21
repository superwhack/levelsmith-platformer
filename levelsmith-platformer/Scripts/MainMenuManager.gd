extends Control

# Master manager
@export var masterManager : Node2D;

# Main menu buttons
@export var buttonNewLevel : Button;
@export var buttonImportLevel : Button;
@export var buttonLoadExample : Button;
@export var buttonQuit : Button;
@export var buttonCredits : Button;
@export var buttonCloseCredits : Button;
@export var buttonOpenLevelFolder : Button;
@export var buttonPlayLevel : Button;
@export var buttonEditLevel : Button;
@export var buttonDuplicateLevel : Button;
@export var buttonDeleteLevel : Button;
@export var buttonFavoriteLevel : Button;
@onready var favoriteButtonIcon : TextureRect = buttonFavoriteLevel.get_node("MarginContainer/TextureRect");

# Overlays
@export var overlayNewLevel : ColorRect;
@export var overlayImportLevel : ColorRect;
@export var overlayDuplicateLevel : ColorRect;
@export var overlayCredits : ColorRect;

# New level overlay children
@export var buttonNewLevelCreate : Button;
@export var buttonNewLevelCancel : Button;
@export var fieldNewLevelName : LineEdit;
@export var fieldNewLevelAuthor : LineEdit;
@export var spinBoxNewLevelX : SpinBox;
@export var spinBoxNewLevelY : SpinBox;
@export var invalidWarning : MarginContainer;
@export var emptyWarning : MarginContainer;

# Import level overlay children
@export var buttonImportLevelOpen : Button;
@export var buttonImportLevelCancel : Button;
@export var buttonImportLevelBrowse : TextureButton;
@export var fieldImportLevelPath : LineEdit;
@export var badImportWarning : PanelContainer;
@export var badImportBody : RichTextLabel;

# Duplicate Level Overlay Children <3
@export var buttonDuplicateLevelCancel : Button;
@export var buttonDuplicateLevelConfirm : Button;
@export var duplicateName : LineEdit;
@export var spinBoxDuplicateLevelX : SpinBox;
@export var spinBoxDuplicateLevelY : SpinBox;
@export var duplicateErrorBanner : PanelContainer;
@export var duplicateEmptyBanner : PanelContainer;
@export var duplicateExistsBanner : PanelContainer;

@export var fileExplorer : FileDialog;

## A reference to the Level List for loading levels.
@export var levelList : VBoxContainer;
## A reference to a packed scene of a clickable Level List Item.
@export var levelListItem : PackedScene;

## Reference to current software version
@export var softwareVersion : Label;

## reference to level check mark
@export var validatedCheckmark : TextureRect;

## References to meta data values.
@export var levelName : Label;
@export var author : Label;
@export var dateCreated : Label;
@export var dateModified : Label;
@export var dimensions : Label;
@export var objectCount : Label;
@export var version : Label;
@export var preview : TextureRect;
@export var previewDefault : Texture2D;
@export var favoriteEmpty : Texture2D;
@export var favoriteFilled : Texture2D;

# Global Settings Button
@export var globalSettingsButton : Button;

# The currently selected level item.
var selectedItem : Control = null;
# Dictionary of all level items. For level list filling.
var levelItems: Dictionary = {} # path -> item

# Level size warning variables
const MAX_LEVEL_AREA := 10000;
@export var areaWarning : PanelContainer;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buttonNewLevel.grab_focus();
	
	softwareVersion.text = str(Global.VERSION);
	# Hides other screens
	overlayImportLevel.hide();
	overlayNewLevel.hide();
	overlayDuplicateLevel.hide();

	# Connect signals
	buttonNewLevel.pressed.connect(overlay_new_level_show);
	buttonNewLevelCreate.pressed.connect(create_new_level);
	buttonOpenLevelFolder.pressed.connect(open_level_folder);
	buttonPlayLevel.pressed.connect(play_current_level);
	buttonEditLevel.pressed.connect(edit_current_level);
	buttonDeleteLevel.pressed.connect(open_delete_popup);
	buttonDuplicateLevel.pressed.connect(overlay_duplicate_level_show);
	buttonFavoriteLevel.pressed.connect(favorite_current_level);
	get_window().focus_entered.connect(fill_level_list);
	
	# Hiding appropriate UI when cancelling level creation
	buttonNewLevelCancel.pressed.connect(overlay_new_level_hide);
	buttonNewLevelCancel.pressed.connect(emptyWarning.hide);
	buttonNewLevelCancel.pressed.connect(invalidWarning.hide);
	
	buttonImportLevel.pressed.connect(overlay_import_level_show);
	buttonImportLevelOpen.pressed.connect(import_level);
	buttonImportLevelCancel.pressed.connect(import_cancel);
	buttonImportLevelCancel.pressed.connect(badImportWarning.hide);
	buttonImportLevelBrowse.pressed.connect(fileExplorer.popup_file_dialog);
	
	# Duplicate buttons
	buttonDuplicateLevelConfirm.pressed.connect(duplicate_current_level);
	buttonDuplicateLevelCancel.pressed.connect(overlay_duplicate_level_hide);
	globalSettingsButton.pressed.connect(masterManager.open_global_settings_menu);
	buttonQuit.pressed.connect(exit_program);
	buttonCredits.pressed.connect(show_credits_screen);
	buttonCloseCredits.pressed.connect(show_credits_screen.bind(false));

	spinBoxNewLevelX.value_changed.connect(update_level_size_warning);
	spinBoxNewLevelY.value_changed.connect(update_level_size_warning);

	var set_directory = func (directory: String) -> void:
		fieldImportLevelPath.text = directory + "/";
	
	fileExplorer.dir_selected.connect(set_directory);

## Functions that just make a menu appear/dissapear, used to attach the sound effects
func overlay_new_level_show() -> void:
	AudioManager.play_UI_effect("UISelection");
	overlayNewLevel.show();
	update_level_size_warning();
	fieldNewLevelName.grab_focus();
func overlay_new_level_hide() -> void:
	AudioManager.play_UI_effect("UISelection");
	overlayNewLevel.hide();
	buttonNewLevel.grab_focus();
func overlay_import_level_show() -> void:
	AudioManager.play_UI_effect("UISelection");
	overlayImportLevel.show();
	fieldImportLevelPath.grab_focus();
func popup_file_dialog() -> void:
	AudioManager.play_UI_effect("UISelection");
	fileExplorer.popup_file_dialog();
	buttonNewLevel.grab_focus();
func overlay_duplicate_level_show() -> void:
	AudioManager.play_UI_effect("UI_Selection");
	overlayDuplicateLevel.show();
	duplicateName.grab_focus();
	
func overlay_duplicate_level_hide() -> void:
	AudioManager.play_UI_effect("UI_Selection");
	overlayDuplicateLevel.hide();
	buttonNewLevel.grab_focus();

## Called when import level button is pressed
func import_level() -> void:
	AudioManager.play_UI_effect("UISelection");
	if (!ImportExportManager.validate_import(fieldImportLevelPath.text)): 
		badImportWarning.show();
		badImportBody.text = "Level Import Failed from directory \"" + fieldImportLevelPath.text + "\"!";
		return;
	
	# Extract the name of the folder from the file path
	var importedLevelArray : Array = fieldImportLevelPath.text.rstrip("/").split("/");
	var importedLevelName : String = importedLevelArray[importedLevelArray.size() - 1];
	var importDirectory : String = "user://Levels/" + importedLevelName + "/";
	masterManager.loadedLevelPath = fieldImportLevelPath.text;

	if (!DirAccess.dir_exists_absolute(importDirectory)):
		DirAccess.make_dir_absolute(importDirectory);
		ImportExportManager.clone_data(fieldImportLevelPath.text + "/", importDirectory);
	masterManager.import_level_and_edit();
	
	# Resets the ui overlay
	fieldImportLevelPath.clear();
	overlayImportLevel.hide();
	pass;

## Called when import level is closed
func import_cancel() -> void:
	AudioManager.play_UI_effect("UISelection");
	overlayImportLevel.hide();

func update_level_size_warning(value = null) -> void:
	var area := int(spinBoxNewLevelX.value) * int(spinBoxNewLevelY.value)
	if area > MAX_LEVEL_AREA:
		areaWarning.show()
	else:
		areaWarning.hide()

## Opens the menu for setting a name and size for the level
func create_new_level() -> void:
	AudioManager.play_UI_effect("UISelection");
	invalidWarning.hide();
	emptyWarning.hide();
	
	# If the given level name is empty, return early.
	if (fieldNewLevelName.text.strip_edges().is_empty()):
		emptyWarning.show();
		return;
		
	# If the given level name is invalid, return early.
	if (!fieldNewLevelName.text.strip_edges().is_valid_filename() || fieldNewLevelName.text[-1] == "."  || fieldNewLevelName.text.length() > 255):
		emptyWarning.hide();
		invalidWarning.show();
		return;
		
	overlayNewLevel.hide();
	masterManager.level_setup( 
		fieldNewLevelName.text, 
		fieldNewLevelAuthor.text,
		Vector2i( 
			int(spinBoxNewLevelX.value), 
			int(spinBoxNewLevelY.value) 
			)
		);
		
	# Reset leftover data
	fieldNewLevelName.text = "";
	spinBoxNewLevelX.value = 20;
	spinBoxNewLevelY.value = 20;
	

## Exits the program
func exit_program() -> void:
	get_tree().quit();
	
## Fills the level list with currently existing levels from the user's directory.
func fill_level_list() -> void:
	# Get the directory that contains all the level folders
	var levelsPath : String = "user://Levels"
	var levelListDir : DirAccess = DirAccess.open(levelsPath);
	print("Levels path:", levelsPath)
	print("LLD:", levelListDir);
	
	# Return early if there is no directory.
	if (!levelListDir):
		return;
		
	var levelFolders : Dictionary = {};
	
	levelListDir.list_dir_begin();
	
	var folderName : String = levelListDir.get_next();
	# So long as the folder name is not null...
	while folderName != "":
		if (levelListDir.current_is_dir()):
			# Getting and creating the level list item
			var levelPath : String = levelsPath + "/" + folderName;
			# Add the level to the level list and set it up visually.
			if (get_level_valid(levelPath)):
				levelFolders[levelPath] = folderName;

		folderName = levelListDir.get_next();
		
	levelListDir.list_dir_end();
	
	# Remove folders that do not exist anymore
	for levelPath in levelItems.keys().duplicate():
		if (!levelFolders.has(levelPath)):
			var item = levelItems[levelPath];

			if (selectedItem == item):
				clear_selection();

			item.queue_free();
			levelItems.erase(levelPath);
	
	# Get an array of levels sorted by favorite
	var sortedPaths: Array = sort_levels_by_favorite(levelFolders.keys());
	
	for levelPath in sortedPaths:
		if (!levelItems.has(levelPath)):
			setup_level_item(levelFolders[levelPath], levelPath);
		else:
			update_level_item(
				levelItems[levelPath],
				levelFolders[levelPath],
				levelPath
			);

		# Move the item into the correct order
		levelList.move_child(levelItems[levelPath], sortedPaths.find(levelPath));

## Setups each level item in the list.
## folderName: the folder of the level. Used for level title.
## levelPath: the path of the level.
func setup_level_item(folderName : String, levelPath : String) -> void:
	# Instantiate and add to level list.
	var item : Node = levelListItem.instantiate();
	levelList.add_child(item);
	update_level_item(item, folderName, levelPath);


## Load a level when appropriate button is pressed
## path: The path of the level to be loaded.
func _on_level_double_clicked(path: String) -> void:
	AudioManager.play_UI_effect("UISelection");
	masterManager.load_level(path);
	
## Fills in metadata labels with appropriate data when hovered.
## item: the level list button item.
func _on_level_hovered(item: Node) -> void:
	if (!selectedItem):
		update_metadata(item);
	
func _on_level_pressed(item: Node) -> void:
	if (selectedItem == item):
		return;
		
	if (selectedItem):
		selectedItem.levelButton.button_pressed = false
	else:
		toggle_level_buttons()

	selectedItem = item;
	update_metadata(item);


## Deselecting a level with right-click removes metadata.
## item: The button item being deselected.
func _on_level_deselected(item: Node) -> void:
	if (selectedItem == item):
		item.levelButton.button_pressed = false;
		toggle_level_buttons();
		clear_selection();

## When a level is selected, toggle the buttons being disabled
func toggle_level_buttons() -> void:
	buttonDeleteLevel.disabled = !buttonDeleteLevel.disabled;
	buttonDuplicateLevel.disabled = !buttonDuplicateLevel.disabled;
	buttonEditLevel.disabled = !buttonEditLevel.disabled;
	buttonPlayLevel.disabled = !buttonPlayLevel.disabled;
	buttonFavoriteLevel.disabled = !buttonFavoriteLevel.disabled;

func set_favorite_button_icon(is_favorited: bool) -> void:
	favoriteButtonIcon.texture = favoriteFilled if is_favorited else favoriteEmpty;

func update_level_item(item: Node, folderName : String, levelPath : String) -> void:
	item.levelPath = levelPath + "/";
	levelItems[levelPath] = item;

	# Setting the level list item data
	item.levelTitle.text = folderName;
	item.levelButton.tooltip_text = folderName; 
	
	# Connect the level button signal to the double clicked function
	if (!item.level_double_clicked.is_connected(_on_level_double_clicked)):
		item.level_double_clicked.connect(_on_level_double_clicked);	# Hovering an item populates the metadata field.
	#item.level_hovered.connect(_on_level_hovered);
	# Selecting an item toggles.
	if (!item.level_pressed.is_connected(_on_level_pressed)):
		item.level_pressed.connect(_on_level_pressed);

	if (!item.level_deselected.is_connected(_on_level_deselected)):
		item.level_deselected.connect(_on_level_deselected);
	
	# Fetch thumbnail, if it exists
	var levelThumbnailPath : String = levelPath + "/Preview.PNG";
	
	# Fetch the level's metadata.
	var metadata : Dictionary = ImportExportManager.get_metadata(levelPath);
	
	
	# Adding metadata to the actual buttons themselves.
	item.levelDate.text = metadata.get("dateCreated", "01.01.1967");
	item.levelTime.text = metadata.get("timeCreated", "00:00");
	
	# Storing metadata in the buttons, for hovering/selecting.
	item.author = str(metadata.get("author", ""));
	item.dateCreated = "%s %s" % [
		metadata.get("dateCreated", "01.01.1967"),
		metadata.get("timeCreated", "00:00")];
	item.dateModified = "%s %s" % [
		metadata.get("dateModified", "01.01.1967"),
		metadata.get("timeModified", "00:00")];
	item.dimensions = str(metadata.get("dimensions", str([20, 20])));
	item.objectCount = str(int(metadata.get("objects", str(0))));
	item.version = str(metadata.get("version", Global.VERSION));
	if (item.version != str(Global.VERSION)):
		item.levelErrorIcon.show();
		item.levelErrorIcon.tooltip_text = "This level's version is " + item.version + ". You are currently on version " + str(Global.VERSION) + ".";
	else:
		item.levelErrorIcon.hide();
	item.favorited = metadata.get("favorited", false);
	item.validated = metadata.get("validated", false);
	if (item.favorited):
		item.levelFavoriteIcon.show();
	else:
		item.levelFavoriteIcon.hide();
	
	# If the the thumbnail exists, add it to the 
	if (FileAccess.file_exists(levelThumbnailPath)):
		var image : Image = Image.new();
		# If the image returns, add to item script
		if (image.load(levelThumbnailPath) == OK):
			var texture : ImageTexture = ImageTexture.create_from_image(image);
			item.thumbnail = texture;


## Reusable function for updating metadata based on given item.
## item: Level item to be used for updating metadata.
func update_metadata(item: Node) -> void:
	levelName.text = item.levelTitle.text;
	author.text = item.author;
	dateCreated.text = item.dateCreated;
	dateModified.text = item.dateModified;
	dimensions.text = item.dimensions;
	objectCount.text = item.objectCount;
	version.text = item.version;
	
	if (item.thumbnail):
		preview.texture = item.thumbnail;
	else:
		preview.texture = previewDefault;
	set_favorite_button_icon(item.favorited);
	if (item.validated):
		validatedCheckmark.show();
	else:
		validatedCheckmark.hide();

## Clears the metadata selection.
func clear_selection() -> void:
		selectedItem = null;
		levelName.text = "";
		author.text = "";
		dateCreated.text = "";
		dateModified.text = "";
		dimensions.text = "";
		objectCount.text = "";
		version.text = "";
		preview.texture = previewDefault;
		set_favorite_button_icon(false);
		validatedCheckmark.hide();

## Opens OS file explorer to the users Level folder.
func open_level_folder() -> void:
	var path : String = ProjectSettings.globalize_path("user://Levels");
	OS.shell_open(path);


## Play the currently selected level.
func play_current_level() -> void:
	if (!selectedItem):
		return;
	AudioManager.play_UI_effect("UI_Selection");
	masterManager.load_level(selectedItem.levelPath, true);

## Edit the currently selected level.
func edit_current_level() -> void:
	if (!selectedItem):
		return;

	AudioManager.play_UI_effect("UI_Selection");
	masterManager.load_level(selectedItem.levelPath);

## Opens a delete popup when the delete button is pressed
func open_delete_popup() -> void:
	if (!selectedItem):
		return;
	
	PopUpManager.create_delete_popup(delete_current_level, selectedItem.levelTitle.text);

## Deletes the currently selected level.
func delete_current_level() -> void:
	if (!selectedItem):
		return;

	AudioManager.play_UI_effect("UI_Selection");
	
	var levelPath : String = selectedItem.levelPath.rstrip("/");

	# Delete all files and folders inside the level directory
	# Thank you: https://tinyurl.com/ak58bfvd
	remove_recursively(selectedItem.levelPath);

	var item = levelItems[levelPath];
	item.queue_free();
	levelItems.erase(levelPath);
	
	clear_selection();
	toggle_level_buttons();

## Duplicates the currently selected level.
func duplicate_current_level() -> void:
	var newLevelName : String = duplicateName.text.strip_edges()

	# If the given level name is empty, return early.
	if (newLevelName.strip_edges().is_empty()):
		duplicateEmptyBanner.show();
		duplicateErrorBanner.hide();
		duplicateExistsBanner.hide();
		return;
		
	# If the given level name is invalid, return early.
	if (!newLevelName.strip_edges().is_valid_filename() || newLevelName[-1] == "."  || newLevelName.length() > 255):
		duplicateErrorBanner.show();
		duplicateEmptyBanner.hide();
		duplicateExistsBanner.hide();
		return;

	var itemLevelPath : String = selectedItem.levelPath;
	var destination : String = "user://Levels/" + newLevelName + "/";

	# Don't overwrite an existing level!!!
	if DirAccess.dir_exists_absolute(destination):
		duplicateExistsBanner.show();
		duplicateErrorBanner.hide();
		duplicateEmptyBanner.hide();
		return;

	# Create the directory and clone our data right there
	DirAccess.make_dir_absolute(destination);
	ImportExportManager.clone_data(itemLevelPath, destination);

	# Reset duplicate metadata
	var now : Dictionary = Time.get_datetime_dict_from_system()
	var meridiem : String = "AM";
	if (now.hour >= 12):
		meridiem = "PM";
		
	# So that time cannot equal 0:15 AM
	now.hour %= 12;
	if (now.hour == 0):
		now.hour = 12;

	var date := "%02d.%02d.%04d" % [now.month, now.day, now.year];
	var time := "%02d:%02d %s" % [now.hour, now.minute, meridiem];

	# set all metadata when duplicating appropriately
	ImportExportManager.set_metadata(destination.rstrip("/"), "favorited", false);
	ImportExportManager.set_metadata(destination.rstrip("/"), "dateCreated", date);
	ImportExportManager.set_metadata(destination.rstrip("/"), "timeCreated", time);
	ImportExportManager.set_metadata(destination.rstrip("/"), "dateModified", date);
	ImportExportManager.set_metadata(destination.rstrip("/"), "timeModified", time);

	overlayDuplicateLevel.hide();
	duplicateName.clear();
	fill_level_list();
	
	# Select the new level automatically
	var newLevelPath: String = destination.rstrip("/");
	if (levelItems.has(newLevelPath)):
		var newItem = levelItems[newLevelPath];
		newItem.levelButton.button_pressed = true;
		_on_level_pressed(newItem);


## Sets whether the currently selected level is favorited or not.
func favorite_current_level() -> void:
	if (!selectedItem):
		return;

	selectedItem.favorited = !selectedItem.favorited;

	# Set the metadata value for favorited in the file
	ImportExportManager.set_metadata(
		selectedItem.levelPath.rstrip("/"),
		"favorited",
		selectedItem.favorited
	);
	
	set_favorite_button_icon(selectedItem.favorited);
		
	if (selectedItem.favorited):
		selectedItem.levelFavoriteIcon.show();
	else:
		selectedItem.levelFavoriteIcon.hide();
	
	update_metadata(selectedItem);
	fill_level_list();


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

## Sorts the levels by favorites first.
## levelPaths: An array of every level path.
func sort_levels_by_favorite(levelPaths: Array) -> Array:
	# Custom callable built-in to arrays
	levelPaths.sort_custom(func(a, b):
		var aMetadata = ImportExportManager.get_metadata(a);
		var bMetadata = ImportExportManager.get_metadata(b);

		# get favorite state from metadata
		var aFavorite: bool = aMetadata.get("favorited", false);
		var bFavorite: bool = bMetadata.get("favorited", false);

		# Favorites first
		if (aFavorite != bFavorite):
			return aFavorite;
			
		# Since we do date american way, need to rearrange for easy comparison
		var aDate = str(aMetadata.get("dateModified", "01.01.1970")).split(".");
		var aTime = str(aMetadata.get("timeModified", "00:00")).split(":");
		
		var bDate = str(bMetadata.get("dateModified", "01.01.1970")).split(".");
		var bTime = str(bMetadata.get("timeModified", "00:00")).split(":");
		
		var aModified = {
			"year": int(aDate[2]),
			"month": int(aDate[0]),
			"day": int(aDate[1]),
			"hour": int(aTime[0]),
			"minute": int(aTime[1])
		};
		
		var bModified = {
			"year": int(bDate[2]),
			"month": int(bDate[0]),
			"day": int(bDate[1]),
			"hour": int(bTime[0]),
			"minute": int(bTime[1])
		};
		
		# convenient function for time comparison :D
		return Time.get_unix_time_from_datetime_dict(aModified) > Time.get_unix_time_from_datetime_dict(bModified);;
	);
	# return sorted array
	return levelPaths;

## Removes all files in a directory, recursively.
## Credit: https://github.com/godotengine/godot-proposals/issues/11598
## directory: The directory to delete all files within.
func remove_recursively(directory: String) -> void:
	for directoryName in DirAccess.get_directories_at(directory):
		remove_recursively(directory.path_join(directoryName));
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file));

	DirAccess.remove_absolute(directory)

func show_credits_screen(show : bool = true) -> void:
	if (show):
		AudioManager.play_UI_effect("UISelection")
		overlayCredits.show();
	else:
		AudioManager.play_UI_effect("UISelection")
		overlayCredits.hide();
