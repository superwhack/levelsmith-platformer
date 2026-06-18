extends Panel

# Path to the root folder of all assets
var filePath: String = "user://Assets";

# References to images
var imageToReplace: Image;
var imageNameToReplace: String;

# References to audio
var newAudio: AudioStream;
var audioToReplace: AudioStream;

# References to both tile maps
@export var mainTileMap: TileMapLayer;
@export var previewTileSet: TileMapLayer;

@export var imagePreview: TextureRect;
@export var imageSelect: FileDialog;

@export var imagesTab: VBoxContainer;
@export var animationsTab: VBoxContainer;
@export var currentAssetLabel: Label;

# Button references for connecting signals
@export var loadFileButton: Button;
@export var resetButton: Button;

var firstSelected: AssetItem = null;

const ASSET_BUTTON = preload("res://Scenes/UI/AssetItem.tscn");

const MISSING_TEXTURE := "res://Assets/Defaults/Assets/Sprites/Missing.png";

# All types of tiles
var tileTypes: Array[String] = ["Solid", "Death","OneWay","Ice", "Sticky", "Bounce", "Slope" ];

# All types of entities
var entityTypes: Array[String] = ["Player", "EnemyStationary", "EnemyShooting", "EnemyPatrol", "EnemyFlying", "Goal"];

# All types of props
var propTypes: Array[String] = ["Prop1", "Prop2", "Prop3", "Prop4", "Prop5"];

#All animations
var animations: Array[String] = ["PlayerRun", "PlayerJump", "PlayerIdle", "EnemyWalk", "EnemyIdle", "EnemyFly"];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	loadFileButton.pressed.connect(open_image_selector);
	resetButton.pressed.connect(reset_image);
	imageSelect.file_selected.connect(replace_image);
	
	# Checks if the user has an assets root folder, creates one if not
	var dir = DirAccess.open(filePath);
	if (!dir):
		create_file_tree();
	# Generate all buttons under their tabs
	generate_buttons("Tiles", imagesTab);
	generate_buttons("Props", imagesTab);
	generate_buttons("Entities", imagesTab);
	generate_buttons("Animations", animationsTab, AssetItem.AssetType.ANIMATION);
	item_selected(firstSelected);
	# Refresh all assets
	refresh_assets();
	ImportExportManager.levelImported.connect(refresh_assets);
	ImportExportManager.levelImported.connect(item_selected);

# WARNING Only refreshes all files once, might be worth it later to do individually
## Generate buttons for each asset
## folder: Which folder the assets for a certain group are stored in
## container: Which container the list of assets is stored in
## type: What type the asset is - Image, Animation, or Audio 
func generate_buttons(folder: String, container: VBoxContainer, type: AssetItem.AssetType = AssetItem.AssetType.IMAGE):
	# Set the file path to the folder
	var categoryFilePath: String = find_directory_by_name(folder);
	# Open the folder at the path
	var dir = DirAccess.open(categoryFilePath);
	# If the folder is successfully opened
	if (dir):
		# Get all directories within the folder
		var allDirectories = dir.get_directories();
		# For each directory within, instantiate a button and set its properties based on the folder name
		for directory: String in allDirectories:
			var newButton = ASSET_BUTTON.instantiate();
			newButton.assetName = directory;
			newButton.displayName = directory.capitalize();
			container.add_child(newButton);
			newButton.pressed.connect(item_selected.bind(newButton));
			newButton.type = type;
			if (!firstSelected):
				firstSelected = newButton;

## Finds an image by its name
## imageName: Name of the image
## returns: Loaded image
func find_image(imageName: String, currentDirectory: String = filePath) -> Image:
	# Get the path to the image
	var imagePath = find_file_by_name(imageName, currentDirectory);
	# If the path exists
	if (imagePath):
		# Create and load an image from the path
		var image = Image.new();
		image.load(imagePath);
		if (imagePath.get_extension().to_lower() == "png"):
			if (validate_image(image)):
				# Return the loaded image
				return image;
		PopUpManager.create_error_popup("Cannot Load Asset","Image not valid. '.png' file required.");
		return null;
		
	# If the path does not exist, print error
	else:
		PopUpManager.create_error_popup("Cannot Load Asset","No file found in '" + filePath + "'.");
		return get_missing_image();


## Finds and loads the first image found in given folder
## folderPath: Path to the folder
## returns: Image loaded if it is found
func find_image_in_folder(folderPath: String) -> Image:
	# Opens the folder at the given folderName path
	var dir = DirAccess.open(folderPath);
	# If a folder was sucessfully opened
	if (dir):
		# Initialize file stream
		dir.list_dir_begin();
		# Get the image name in the folder
		var imageName: String = dir.get_next();
		# If there is no image in the folder, return null
		if (imageName == ""):
			return null;
		else:
			# Initialize an image
			var image: Image = Image.new();
			# Load the image based on it's file path
			image.load(folderPath + "/" + imageName);
			# Close file stream
			dir.list_dir_end();
			if (imageName.get_extension().to_lower() == "png"):
				if (validate_image(image)):
					# Return loaded image
					return image;
			PopUpManager.create_error_popup("Image not valid", "Image must be .png");
			return null;
	else:
		print("Could not open file path");
		PopUpManager.create_error_popup("Could not open file path", "Could not open file at " + folderPath + ".");
		return null;

# WARNING Get Sten/Bee's input on if it should only be 128x128 or resize
func validate_image(image: Image) -> bool:
	if (!image): return false;
	var imageWidth = image.get_width();
	var imageHeight = image.get_height();
	if (imageWidth != 128 || imageHeight != 128):
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS);
	return true;

func get_animation_from_folder(folderName: String) -> Array[Image]:
	var pathToFolder: String = find_directory_by_name(folderName);
	if (pathToFolder):
		var dir = DirAccess.open(pathToFolder);
		var allImageNames = dir.get_files();
		var allImages: Array[Image] = [];
		for imageName in allImageNames:
			allImages.append(find_image(imageName));
		return allImages;
	else:
		PopUpManager.create_error_popup("Could not find folder","Could not find folder with name " + folderName + ".");
	return [];

## Gets the amount of files within a folder
## folderName: Name of the folder to check
## returns: The amount of files in the folder
func file_count_in_folder(folderName: String) -> int:
	# Get the path to the folder
	var pathToFolder: String = find_directory_by_name(folderName);
	# If there is a path to the folder
	if (pathToFolder):
		# Open the directory at the path
		var dir = DirAccess.open(pathToFolder);
		# Store all files in that path in an array
		var allFiles = dir.get_files();
		# Return the size of that array
		return allFiles.size();
	# If there is no path to the folder
	else:
		# Print error
		PopUpManager.create_error_popup("Folder not found", "Could not find folder with name " + folderName + ".")
	return -1;

func refresh_assets() -> void:
	for i in range(tileTypes.size()):
		var tileImage: Image = find_image_in_folder(find_directory_by_name(tileTypes[i]));
		var defaultTileImage: Image = find_image(tileTypes[i] + ".png", "res://Assets/Defaults");
		change_tile_texture(i, tileImage if tileImage else defaultTileImage, mainTileMap);
	for i in range(propTypes.size()):
		var propImage: Image = find_image_in_folder(find_directory_by_name(propTypes[i]));
		var defaultPropImage: Image = find_image(propTypes[i] + ".png", "res://Assets/Defaults");
		change_tile_texture(Global.EntityType.PROP1 + i, propImage if propImage else defaultPropImage, mainTileMap);
	pass;

## Clears any images in the replacement directory
## returns: The replacement directory
func clear_image() -> DirAccess:
	var targetFilePath: String = find_directory_by_name(imageNameToReplace);
	var targetDirectory: DirAccess  = DirAccess.open(targetFilePath);
	
	if(!targetDirectory): return;
	var existingFiles: PackedStringArray = targetDirectory.get_files();
	# Remove any files in the directory
	for file in existingFiles:
		targetDirectory.remove(file); 
	return targetDirectory;

## Replaces the currently previewed image with one chosen via file dialog.
## newImagePath: The file path of the new image replacing the old one.x 
func replace_image(newImagePath: String) -> void:
	var targetFilePath: String = find_directory_by_name(imageNameToReplace);
	var targetDirectory: DirAccess = clear_image();
	if (newImagePath.get_extension().to_lower() == "png"):
		targetDirectory.copy(newImagePath, targetFilePath + "/replacement.png");
	else:
		print("File must be PNG format");
		PopUpManager.create_error_popup("File type incorrect", "File must be .png format.");
	
	refresh_assets();
	var replacementImage = find_image_in_folder(targetFilePath);
	if (replacementImage):
		imagePreview.texture = ImageTexture.create_from_image(replacementImage);
	else:
		imagePreview.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));

func replace_audio(audioToReplace: AudioStream, newAudio: AudioStream) -> void:
	pass;

func reset_image() -> void:
	clear_image();
	refresh_assets();
	imagePreview.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));

func reset_audio(audioName: String) -> void:
	pass;

func return_all_to_default(categoryName: String) -> void:
	pass;

func item_selected(selectedItem: AssetItem = firstSelected) -> void:
	imageNameToReplace = selectedItem.assetName;
	imageToReplace = find_image_in_folder(find_directory_by_name(imageNameToReplace));
	if (imageToReplace):
		var replacementTexture = ImageTexture.create_from_image(imageToReplace);
		if (replacementTexture): 
			imagePreview.texture = ImageTexture.create_from_image(imageToReplace);
	else:
		imagePreview.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));
	
	currentAssetLabel.text = selectedItem.displayName;

## Change the texture of an atlas tile to a new image texture
## sourceID: Source ID of the tile being changed
## newImage: Image being switched to
## tileMap: The tileMap being changed
## NOTE: Only works with images >= 128px x 128px
func change_tile_texture(sourceID: int, newImage: Image, tileMap: TileMapLayer):
	if (newImage == null):
		return;
	# Create a Texture2D from the image
	var newTexture: Texture2D = ImageTexture.create_from_image(newImage);
	# Set a reference to the tile map's tile set
	var tileSet = tileMap.tile_set;
	# Set a reference to the source in the tile set
	var source = tileSet.get_source(sourceID) as TileSetAtlasSource;
	# If the source is found, set the texture to the image
	if source:
		source.texture = newTexture;
		# NOTE: TEMPORARY FIX PT 2
		for frame in range(0, 5):
			await get_tree().process_frame;
		mainTileMap.get_parent().clear_enemies();


## Recursively searches directories for a file of a specific name
## targetFileName: The name of the target file
## currentDirectory: The file path currently being checked
## returns: File path to the file with that name
func find_file_by_name(targetFileName: String, currentDirectory: String = filePath) -> String:
	# Opens the folder at the given currentDirectory path
	var dir = DirAccess.open(currentDirectory);
	# If the directory opened successfully
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the current file name to the next file in the directory
		var currentFileName = dir.get_next();
		# Loop if the current name exists
		while (currentFileName != ""):
			# Instantiate a variable to represent the full path currently being accessed
			var fullPath = currentDirectory + "/" + currentFileName;
			# If the current item is a directory
			if (dir.current_is_dir()):
				# Call this function on the directory currently being accessed
				var result = find_file_by_name(targetFileName, fullPath);
				# If the result is something, return it
				if (result != ""):
					return result;
			# If the current item is not a directory
			else:
				# If the current file being accessed is the correct name, return the full path to it
				if (currentFileName == targetFileName):
					return fullPath;
			# set the current file name to the next file
			currentFileName = dir.get_next();
	return "";

## Recursively finds the path to a specific directory based on its name
## targetDirectoryName: Name of the target directory
## currentDirectory: Path to the directory currently being checked
## returns: Path to the directory
func find_directory_by_name(targetDirectoryName: String, currentDirectory: String = filePath) -> String:
	# Opens the directory at the currentDirectory path
	var dir = DirAccess.open(currentDirectory);
	# If there is a directory at that path
	if (dir):
		# Initialize the file stream
		dir.list_dir_begin();
		# Set the currentFileName to the next item being checked
		var currentFileName = dir.get_next();
		# Loop as long as the currentFileName is not empty
		while (currentFileName != ""):
			# Track the full path to the file being checked
			var fullPath = currentDirectory + "/" + currentFileName;
			# If the current item being checked is a folder
			if (dir.current_is_dir()):
				# If the folder name is equal to the target name, return the path
				if (currentFileName == targetDirectoryName):
					return fullPath;
				# If the folder name is not the target
				else:
					# Call this function with the new path
					var result = find_directory_by_name(targetDirectoryName, fullPath);
					if (result != ""):
						return result;
			# Update the currentFileName to be the next file
			currentFileName = dir.get_next();
	return "";

## Creates all folders in tree for the user
func create_file_tree() -> void:
	# Open the user root directory
	var dir = DirAccess.open("user://");
	# Create all folders for tile types
	for type: String in tileTypes:
		dir.make_dir_recursive(filePath + "/Images/Tiles/" + type);
	# Create all folders for prop types
	for type: String in propTypes:
		dir.make_dir_recursive(filePath + "/Images/Props/" + type);	
	# Create all folders for enitity types
	for type: String in entityTypes:
		dir.make_dir_recursive(filePath + "/Images/Entities/" + type);
	# Create all folders for animations
	for animation: String in animations:
		dir.make_dir_recursive(filePath + "/Animations/" + animation);
	# TODO: Add folders for audio

func open_image_selector() -> void:
	imageSelect.title = "Replace " + imageNameToReplace;
	imageSelect.popup_file_dialog();
	
## Creates a new missing texture for use when a texture is... missing.
func get_missing_image() -> Image:
	var image := Image.new();
	image.load(MISSING_TEXTURE);
	validate_image(image);
	return image;
