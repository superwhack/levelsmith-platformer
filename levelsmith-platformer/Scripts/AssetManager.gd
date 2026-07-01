extends Panel
class_name AssetManager

# Path to the root folder of all assets
var filePath : String = "user://Assets";

# References to images
var imageToReplace : Image;
var imageNameToReplace : String;

# The currently selected entity types
var selectedEntityType : String;

# The Texture that will be replacing the texture with the preview name
var animationPreviewToReplace : Texture2D;
var animationPreviewNameToReplace : String;

# The current animation index being viewed
var currentAnimationIndex : int = 0;

# The current frame the animation is on
var animationFrameIndex : int = 0;

# The currently selected item and its corresponding animation
var currentSelectedItem : AssetItem;
var currentLoadedAnimation : Array[Texture2D];

# References to audio
var newAudio : AudioStream;
var audioToReplace : AudioStream;

# References to both tile maps
@export var mainTileMap : TileMapLayer;

# References to preview and file dialog
@export var imagePreview : Panel;
@export var imagePreviewTexture : TextureRect;
@export var animationPreview : Panel;
@export var animationPreviewTexture : TextureRect;
@export var audioPreview : Panel;
@export var assetTabs : TabContainer;
@export var fileSelect : FileDialog;

# References to different elements of the menu
@export var imagesTab : VBoxContainer;
@export var animationsTab : VBoxContainer;
@export var currentAssetLabel : Label;

# Button references for connecting signals
@export var loadFileButton : Button;
@export var resetButton : Button;
@export var resetAllButton: Button;

# Reference to the editor manager
@export var editorManager : Node2D;

# References to animation preview controls and visuals
@export var animationPreviewRightButton : Button;
@export var animationPreviewLeftButton : Button;
@export var animationName : Label;
@export var frameRightButton : Button;
@export var frameLeftButton : Button;
@export var frameCountLabel : Label;
@export var playButton : Button;
@export var stopButton : Button;
@export var FPSSpinbox : SpinBox;

# Information about played animation
var playingAnimation : bool;
var FPS : float = 12;
var animTimer : float = 0;

# Keep track of the first selected item
var firstImageSelected : AssetItem = null;
var firstAnimationSelected : AssetItem = null;

# Reference to the asset button scene for instantiating
const ASSET_BUTTON : PackedScene = preload("res://Scenes/UI/AssetItem.tscn");

# Reference to the Missing texture in case the default textures are removed
const MISSING_TEXTURE : String = "res://Assets/Defaults/Assets/Sprites/Missing.png";

# All types of tiles
var tileTypes : Array[String] = ["Solid", "Death","OneWay","Ice", "Sticky", "Bounce", "Slope" ];

# All types of entities
var animatedEntityTypes : Array[String] = ["Player", "StationaryEnemy", "ShootingEnemy", "PatrollingEnemy", "FlyingEnemy"];

# All types of props
var propTypes : Array[String] = ["Prop1", "Prop2", "Prop3", "Prop4", "Prop5", "Prop6"];

# Player Animations
var playerAnimations : Array[String] = ["PlayerRun", "PlayerJump", "PlayerIdle", "PlayerFall", "PlayerHurt", "PlayerDeath"];

# All Enemy Animations
var stationaryEnemyAnimations : Array[String] = ["StationaryIdle", "StationaryDeath"];
var patrollingEnemyAnimations : Array[String] = ["PatrolWalk", "PatrolDeath"];
var flyingEnemyAnimations : Array[String] = ["FlyMove", "FlyDeath"];
var shootingEnemyAnimations : Array[String] = ["EnemyShoot", "ShootIdle", "ShootDeath"];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals
	loadFileButton.pressed.connect(open_image_selector);
	resetButton.pressed.connect(reset_image);
	resetAllButton.pressed.connect(reset_all);
	fileSelect.file_selected.connect(replace_image);
	fileSelect.dir_selected.connect(replace_animation);
	Global.levelCreated.connect(refresh_assets);
	animationPreviewRightButton.pressed.connect(anim_change.bind(true));
	animationPreviewLeftButton.pressed.connect(anim_change.bind(false));
	frameRightButton.pressed.connect(frame_change.bind(true));
	frameLeftButton.pressed.connect(frame_change.bind(false));
	playButton.pressed.connect(play_preview_animation);
	stopButton.pressed.connect(stop_preview_animation);
	FPSSpinbox.value_changed.connect(fps_updated);
	
	assetTabs.tab_changed.connect(on_asset_tab_changed);
	
	# Checks if the user has an assets root folder, creates one if not
	var dir : DirAccess = DirAccess.open(filePath);
	if (!dir):
		create_file_tree();
	# Generate all buttons under their tabs
	generate_buttons("Tiles", imagesTab);
	generate_buttons("Props", imagesTab);
	generate_buttons("Entities", imagesTab);
	generate_buttons("Animations", animationsTab, AssetItem.AssetType.ANIMATION);
	item_selected(firstImageSelected);
	on_asset_tab_changed(assetTabs.current_tab);
	# Refresh all assets
	refresh_assets();
	ImportExportManager.levelImported.connect(refresh_assets);
	ImportExportManager.levelImported.connect(item_selected);

func _process(delta: float) -> void:
	# Play the animation
	if (playingAnimation):
		animTimer += delta;
		if (animTimer >= 1/FPS):
			frame_change();
			animTimer = 0;

# WARNING Only refreshes all files once, might be worth it later to do individually
## Generate buttons for each asset
## folder: Which folder the assets for a certain group are stored in
## container: Which container the list of assets is stored in
## type: What type the asset is - Image, Animation, or Audio 
func generate_buttons(folder: String, container: VBoxContainer, type: AssetItem.AssetType = AssetItem.AssetType.IMAGE):
	# Set the file path to the folder
	var categoryFilePath : String = FileSearch.find_directory_by_name(folder);
	# Open the folder at the path
	var dir : DirAccess = DirAccess.open(categoryFilePath);
	# If the folder is successfully opened
	if (dir):
		# Get all directories within the folder
		var allDirectories : PackedStringArray = dir.get_directories();
		# For each directory within, instantiate a button and set its properties based on the folder name
		for directory: String in allDirectories:
			var newButton : Button = ASSET_BUTTON.instantiate();
			newButton.assetName = directory;
			newButton.displayName = directory.capitalize();
			container.add_child(newButton);
			newButton.pressed.connect(item_selected.bind(newButton));
			newButton.type = type;
			# Set the default image and animation to be selected
			if (type == AssetItem.AssetType.IMAGE && !firstImageSelected):
				firstImageSelected = newButton;
			if (type == AssetItem.AssetType.ANIMATION && !firstAnimationSelected):
				firstAnimationSelected = newButton;

## Finds an image by its name
## imageName: Name of the image
## returns: Loaded image
func find_image(imageName: String, currentDirectory: String = filePath) -> Image:
	# Get the path to the image
	var imagePath : String = FileSearch.find_file_by_name(imageName, currentDirectory);
	# If the path exists
	if (imagePath):
		# Create and load an image from the path
		var image : Image = Image.new();
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
	var dir : DirAccess = DirAccess.open(folderPath);
	# If a folder was sucessfully opened
	if (dir):
		# Initialize file stream
		dir.list_dir_begin();
		# Get the image name in the folder
		var imageName : String = dir.get_next();
		# If there is no image in the folder, return null
		if (imageName == ""):
			return null;
		else:
			# Initialize an image
			var image : Image = Image.new();
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
		PopUpManager.create_error_popup("Could not open file path", "Could not open file at " + folderPath + ".");
		return null;

# WARNING Get Sten/Bee's input on if it should only be 128x128 or resize
func validate_image(image: Image) -> bool:
	# If there is no valid image, return false
	if (!image): return false;
	var imageWidth : int = image.get_width();
	var imageHeight : int = image.get_height();
	# If the width and height are not 128, resize it to be
	if (imageWidth != 128 || imageHeight != 128):
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS);
	return true;

## Retrieve the frames for an animation from a given folder path
## folderName: Name of the folder to check
## Returns: Array of all frames for animation
func get_animation_from_folder(folderName: String) -> Array[Image]:
	# Get the path to the folder
	var pathToFolder : String = FileSearch.find_directory_by_name(folderName);
	# If the path is found, retrieve all files and add to array
	if (pathToFolder):
		var dir : DirAccess = DirAccess.open(pathToFolder);
		var allImageNames : PackedStringArray = dir.get_files();
		var allImages : Array[Image] = [];
		for imageName in allImageNames:
			allImages.append(find_image(imageName));
		return allImages;
	else:
		PopUpManager.create_error_popup("Could not find folder","Could not find folder with name " + folderName + ".");
	return [];


## Refresh all assets in game
func refresh_assets() -> void:
	# Change all tiles to their textures
	for i in range(tileTypes.size()):
		var tileImage : Image = find_image_in_folder(FileSearch.find_directory_by_name(tileTypes[i]));
		var defaultTileImage : Image = find_image(tileTypes[i] + ".png", "res://Assets/Defaults");
		change_tile_texture(i, tileImage if tileImage else defaultTileImage, mainTileMap);
	# Change all props to their textures
	for i in range(propTypes.size()):
		var propImage : Image = find_image_in_folder(FileSearch.find_directory_by_name(propTypes[i]));
		var defaultPropImage : Image = find_image(propTypes[i] + ".png", "res://Assets/Defaults");
		change_tile_texture(Global.EntityType.PROP1 + i, propImage if propImage else defaultPropImage, mainTileMap);
	
## Hadnles the switching of buttons between tab changes
func on_asset_tab_changed(tabIndex: int) -> void:
	imagePreview.hide();
	animationPreview.hide();
	audioPreview.hide();
	
	if tabIndex == 0:
		imagePreview.show();
		item_selected(firstImageSelected);
	elif tabIndex == 1:
		animationPreview.show();
		item_selected(firstAnimationSelected);
	elif tabIndex == 2:
		audioPreview.show();

## Clears any images in the replacement directory
## returns: The replacement directory
func clear_image(nameToClear : String) -> DirAccess:
	var targetFilePath : String = FileSearch.find_directory_by_name(nameToClear);
	var targetDirectory : DirAccess  = DirAccess.open(targetFilePath);
	
	if(!targetDirectory): return;
	var existingFiles : PackedStringArray = targetDirectory.get_files();
	# Remove any files in the directory
	for file in existingFiles:
		targetDirectory.remove(file); 
	return targetDirectory;

## Replaces the currently previewed image with one chosen via file dialog.
## newImagePath: The file path of the new image replacing the old one.x 
func replace_image(newImagePath: String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(imageNameToReplace);
	var targetDirectory : DirAccess = clear_image(imageNameToReplace);
	# If the image is a png, create a copy
	if (newImagePath.get_extension().to_lower() == "png"):
		targetDirectory.copy(newImagePath, targetFilePath + "/replacement.png");
	else:
		PopUpManager.create_error_popup("File type incorrect", "File must be .png format.");
	
	refresh_assets();
	var replacementImage : Image = find_image_in_folder(targetFilePath);
	if (replacementImage):
		imagePreviewTexture.texture = ImageTexture.create_from_image(replacementImage);
	else:
		imagePreviewTexture.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));

## Replaces the currently previewed animation with one chosen via file dialog.
## newAnimationPath: The path to the folder selected
func replace_animation(newAnimationPath : String) -> void:
	var targetFilePath : String = FileSearch.find_directory_by_name(animationPreviewNameToReplace);
	var targetDirectory : DirAccess = clear_image(animationPreviewNameToReplace);
	# Count for which file is being iterated at for naming purposes
	var fileCount : int = 0;
	# Loop through every file at the path
	for file in DirAccess.get_files_at(newAnimationPath):
		var currentFilePath = newAnimationPath + "/" + file;
		# If the file is a png, increase the file count and create a copy in the assets folder with its number
		if (file.get_extension().to_lower() == "png"):
			fileCount += 1;
			targetDirectory.copy(currentFilePath, str(targetFilePath, "/", animationPreviewNameToReplace, str(fileCount).pad_zeros(2), ".png"));
		else:
			if (!file.get_extension().to_lower() == "png.import"):
				PopUpManager.create_error_popup("File type incorrect", "File must be .png format.");
	
	refresh_assets();
	# Replace the preview image if there is one, if not load default
	var replacementImage : Image = find_image_in_folder(targetFilePath);
	if (replacementImage):
		currentLoadedAnimation.clear();
		for image in get_animation_from_folder(animationPreviewNameToReplace):
			currentLoadedAnimation.append(ImageTexture.create_from_image(image));
		update_animation_preview();
	else:
		PopUpManager.create_error_popup("No Defaults", "No default images yet, update this when there are default animations");
#func replace_audio(audioToReplace: AudioStream, newAudio: AudioStream) -> void:
#	pass;

## Clears the image in a given folder and replaces it with a default
func reset_image() -> void:
	clear_image(imageNameToReplace);
	refresh_assets();
	imagePreviewTexture.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));

## Resets everything within the assets manager
func reset_all() -> void:
	FileSearch.delete_folder(filePath);
	create_file_tree();
	reset_menu();
	refresh_assets();

## Deletes and regenerates all buttons
func reset_menu() -> void:
	for button: Button in imagesTab.get_children():
		button.queue_free();
	for button: Button in animationsTab.get_children():
		button.queue_free();
	firstImageSelected = null;
	firstAnimationSelected = null;
	generate_buttons("Tiles", imagesTab);
	generate_buttons("Props", imagesTab);
	generate_buttons("Entities", imagesTab);
	generate_buttons("Animations", animationsTab, AssetItem.AssetType.ANIMATION);
	on_asset_tab_changed(assetTabs.current_tab);


#func reset_audio(audioName: String) -> void:
#	pass;

#func return_all_to_default(categoryName: String) -> void:
#	pass;

## Signal that is emitted when an asset in the menu is selected
## selectedItem: The item that is selected, defaults to the firstImageSelected
func item_selected(selectedItem: AssetItem = firstImageSelected) -> void:
	# Pause the animation
	playingAnimation = false;
	# If the selected item is an image, replace its preview
	if (selectedItem.type == AssetItem.AssetType.IMAGE):
		imageNameToReplace = selectedItem.assetName;
		imageToReplace = find_image_in_folder(FileSearch.find_directory_by_name(imageNameToReplace));
		if (imageToReplace):
			var replacementTexture : Texture2D = ImageTexture.create_from_image(imageToReplace);
			if (replacementTexture): 
				imagePreviewTexture.texture = ImageTexture.create_from_image(imageToReplace);
		else:
			imagePreviewTexture.texture = ImageTexture.create_from_image(find_image(imageNameToReplace + ".png", "res://Assets/Defaults"));
	# If the selected image is an animation, reset the frame and load the animation into currentlyLoadedAnimation
	elif (selectedItem.type == AssetItem.AssetType.ANIMATION):
		currentAnimationIndex = 0;
		animationFrameIndex = 0;
		selectedEntityType = selectedItem.assetName;
		animationPreviewNameToReplace = DirAccess.get_directories_at(FileSearch.find_directory_by_name(selectedEntityType))[currentAnimationIndex];
		currentLoadedAnimation.clear();
		for image in get_animation_from_folder(animationPreviewNameToReplace):
			currentLoadedAnimation.append(ImageTexture.create_from_image(image));
		update_animation_preview();
	currentAssetLabel.text = selectedItem.displayName;
	currentSelectedItem = selectedItem;

## Switch between animations within the entity
## next: Whether the user is switching to the next or previous animation
func anim_change(next : bool):
	# Pause the animation
	playingAnimation = false;
	# Increase or decrease the index accordingly
	if (next):
		currentAnimationIndex += 1;
	else:
		currentAnimationIndex -= 1;
	# Find the amount of animations the entity has
	var animationsCount : int = DirAccess.get_directories_at(FileSearch.find_directory_by_name(selectedEntityType)).size();
	# Clamp the animation index within how many the entity has
	if (currentAnimationIndex >= animationsCount):
		currentAnimationIndex = 0;
	elif (currentAnimationIndex < 0):
		currentAnimationIndex = animationsCount - 1;
	# Set the frame to 0
	animationFrameIndex = 0;
	animationPreviewNameToReplace = DirAccess.get_directories_at(FileSearch.find_directory_by_name(selectedEntityType))[currentAnimationIndex];
	# Load the current animation
	currentLoadedAnimation.clear();
	for image in get_animation_from_folder(animationPreviewNameToReplace):
		currentLoadedAnimation.append(ImageTexture.create_from_image(image));
	update_animation_preview();

## Change the animation frame currently shown
## next: Whether the user is changing to the next or previous frame
func frame_change(next : bool = true):
	# Change the animation frame index accordingly
	if (next):
		animationFrameIndex += 1;
	else:
		animationFrameIndex -= 1;
	var frameCount : int = currentLoadedAnimation.size();
	# Clamp the current index between 0 and the currently loaded animation amount
	if (animationFrameIndex >= frameCount):
		animationFrameIndex = 0;
	elif (animationFrameIndex < 0):
		animationFrameIndex = frameCount - 1;
	update_animation_preview();

## Update all parts of the animation preview
func update_animation_preview() -> void:
	animationName.text = animationPreviewNameToReplace;
	var frameCount = currentLoadedAnimation.size();
	frameCountLabel.text = str("Frame ", animationFrameIndex + 1, "/", frameCount)
	if (frameCount > 0):
		animationPreviewToReplace = currentLoadedAnimation[animationFrameIndex];
	else:
		animationPreviewToReplace = null;
	if (animationPreviewToReplace):
			animationPreviewTexture.texture = animationPreviewToReplace;

## Change the texture of an atlas tile to a new image texture
## sourceID: Source ID of the tile being changed
## newImage: Image being switched to
## tileMap: The tileMap being changed
## NOTE: Only works with images >= 128px x 128px
func change_tile_texture(sourceID: int, newImage: Image, tileMap: TileMapLayer) -> void:
	if (newImage == null):
		return;
	# Create a Texture2D from the image
	var newTexture : Texture2D = ImageTexture.create_from_image(newImage);
	# Set a reference to the tile map's tile set
	var tileSet : TileSet = tileMap.tile_set;
	# Set a reference to the source in the tile set
	var source : TileSetAtlasSource = tileSet.get_source(sourceID) as TileSetAtlasSource;
	# If the source is found, set the texture to the image
	if (source):
		source.texture = newTexture;
		# NOTE: TEMPORARY FIX PT 2
		for frame in range(0, 5):
			await get_tree().process_frame;
		editorManager.clear_enemies();



## Creates all folders in tree for the user
func create_file_tree() -> void:
	# Open the user root directory
	var dir : DirAccess = DirAccess.open("user://");
	# Create all folders for tile types
	for type: String in tileTypes:
		dir.make_dir_recursive(filePath + "/Images/Tiles/" + type);
	# Create all folders for prop types
	for type: String in propTypes:
		dir.make_dir_recursive(filePath + "/Images/Props/" + type);
	# Create folder for goal
	dir.make_dir_recursive(filePath + "/Images/Entities/Goal");
	# Create all folders for animations
	for animation: String in playerAnimations:
		dir.make_dir_recursive(filePath + "/Animations/Player/" + animation);
	# Create all folders for enemy animations
	for animation: String in stationaryEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/StationaryEnemy/" + animation);
	for animation: String in patrollingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/PatrollingEnemy/" + animation);
	for animation: String in shootingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/ShootingEnemy/" + animation);
	for animation: String in flyingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/FlyingEnemy/" + animation);
	# TODO: Add folders for audio

func open_image_selector() -> void:
	if (currentSelectedItem.type == AssetItem.AssetType.IMAGE):
		fileSelect.title = "Replace " + imageNameToReplace;
		fileSelect.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	elif (currentSelectedItem.type == AssetItem.AssetType.ANIMATION):
		fileSelect.title = "Replace " + animationPreviewNameToReplace;
		fileSelect.file_mode = FileDialog.FILE_MODE_OPEN_DIR;
	fileSelect.popup_file_dialog();

## Creates a new missing texture for use when a texture is... missing.
func get_missing_image() -> Image:
	var image : Image = Image.new();
	image.load(MISSING_TEXTURE);
	validate_image(image);
	return image;

func play_preview_animation() -> void:
	playingAnimation = !playingAnimation;

func stop_preview_animation() -> void:
	playingAnimation = false;
	animationFrameIndex = 0;
	update_animation_preview();

func fps_updated(value: float) -> void:
	FPS = value;
