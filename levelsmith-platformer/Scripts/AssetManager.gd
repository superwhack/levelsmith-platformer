extends Panel
class_name AssetManager

# Path to the root folder of all assets
var filePath : String = "";
var defaultsFilePath : String = "res://Assets/Defaults/Assets/Sprites/";

# References to audio
var newAudio : AudioStream;
var audioToReplace : AudioStream;

# References to swapping child nodes
@export var imageSwapping : Control;
@export var animationSwapping : Control;
@export var audioSwapping : Control;

# References to preview and file dialog
@export var audioPreview : Panel;
@export var assetTabs : TabContainer;
@export var fileSelect : FileDialog;

# References to different elements of the menu
@export var imagesTab : VBoxContainer;
@export var animationsTab : VBoxContainer;
@export var audioTab : VBoxContainer;
@export var currentAssetLabel : Label;

# Button references for connecting signals
@export var loadFileButton : Button;
@export var resetButton : Button;
@export var resetAllButton: Button;
@export var refreshAllButton : Button;

# Reference to other nodes
@export var editorManager : Node2D;
@export var mainTileMap : TileMapLayer;
@export var masterManager : Node2D;

# Keep track of the first selected item
var firstAnimationSelected : AssetItem = null;
var firstImageSelected : AssetItem = null;
var firstAudioSelected : AssetItem = null;

# Reference to the asset button scene for instantiating
const ASSET_BUTTON : PackedScene = preload("res://Scenes/UI/AssetItem.tscn");

# Reference to the Missing texture in case the default textures are removed
const MISSING_TEXTURE : String = "res://Assets/Defaults/Assets/Sprites/Missing.png";

var currentSelectedItem : AssetItem;

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals
	loadFileButton.pressed.connect(open_file_selector);
	refreshAllButton.pressed.connect(refresh_all);
	resetButton.pressed.connect(reset_image_popup);
	resetAllButton.pressed.connect(reset_all_popup);
	fileSelect.file_selected.connect(file_selected);
	fileSelect.dir_selected.connect(animationSwapping.replace_animation);
	
	assetTabs.tab_changed.connect(on_asset_tab_changed);
	
	AnimationManager.assetManager = self;
	
	ImportExportManager.levelImported.connect(setup);
	Global.levelCreated.connect(setup);

## Listens for the hotkey to close the asset manager.
func _input( event : InputEvent ) -> void:
	if ( event.is_action_pressed("ui_close_dialog") ):
		editorManager.close_asset_manager();

# WARNING Only refreshes all files once, might be worth it later to do individually
## Generate buttons for each asset
## folder: Which folder the assets for a certain group are stored in
## container: Which container the list of assets is stored in
## type: What type the asset is - Image, Animation, or Audio 
func generate_buttons(folder : String, container : VBoxContainer, type : AssetItem.AssetType = AssetItem.AssetType.IMAGE):
	# Set the file path to the folder
	var categoryFilePath : String = FileSearch.find_directory_by_name(folder);
	# Open the folder at the path
	var fileDirectory : DirAccess = DirAccess.open(categoryFilePath);
	# If the folder is successfully opened
	if (fileDirectory):
		# Get all directories within the folder
		var allDirectories : PackedStringArray = fileDirectory.get_directories();
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
			if (type == AssetItem.AssetType.AUDIO && !firstAudioSelected):
				firstAudioSelected = newButton;

## Removes all buttons from the asset list.
## container: The control node containing the buttons.
func clear_buttons(container : VBoxContainer) -> void:
	for button : AssetItem in container.get_children() :
		if (button.type == AssetItem.AssetType.IMAGE && firstImageSelected):
			firstImageSelected = null;
		if (button.type == AssetItem.AssetType.ANIMATION && firstAnimationSelected):
			firstAnimationSelected = null;
		if (button.type == AssetItem.AssetType.AUDIO && firstAudioSelected):
			firstAudioSelected = null;
		button.queue_free();

## Finds an image by its name
## imageName: Name of the image
## returns: Loaded image
func find_image(imageName : String, currentDirectory : String = filePath) -> Image:
	var image : Image = Image.new();
	# Get the path to the image
	var imagePath : String = FileSearch.find_file_by_name(imageName, currentDirectory);
	# If the path exists
	if (imagePath):
		if (imagePath.begins_with("res://")):
			var texture : Texture2D = load(imagePath);
			image = texture.get_image();
			return image;
		else:
			# Create and load an image from the path
			image.load(imagePath);
			if (imagePath.get_extension().to_lower() == "png"):
				if (validate_image(image)):
					# Return the loaded image
					return image;
			PopUpManager.create_error_popup("Cannot Load Asset","Image not valid. '.png' file required.");
			return null;
		
	# If the path does not exist, print error
	else:
		PopUpManager.create_error_popup("Cannot Load Asset","No file found in '" + currentDirectory + "'.");
		return get_missing_image();

## Finds and loads the first image found in given folder
## folderPath: Path to the folder
## returns: Image loaded if it is found
func find_image_in_folder(folderPath: String) -> Image:
	# Opens the folder at the given folderName path
	var imageDirectory : DirAccess = DirAccess.open(folderPath);
	# If a folder was sucessfully opened
	if (imageDirectory):
		# Initialize file stream
		imageDirectory.list_dir_begin();
		# Get the image name in the folder
		var imageName : String = imageDirectory.get_next();
		# If there is no image in the folder, return null
		if (imageName == ""):
			return null;
		else:
			# Initialize an image
			var image : Image = Image.new();
			# Load the image based on it's file path
			image.load(folderPath + "/" + imageName);
			# CloseClose file stream
			imageDirectory.list_dir_end();
			if (imageName.get_extension().to_lower() == "png"):
				if (validate_image(image)):
					# Return loaded image
					return image;
			PopUpManager.create_error_popup("Image not valid", "Image must be .png");
			return null;
	else:
		PopUpManager.create_error_popup("Could not open file path", "Could not open file at " + folderPath + ".");
		return null;

## Checks if the image exists
## image: The image to be checked.
## returns: True if the image exists and is properly sized
## WARNING: Get Sten/Bee's input on if it should only be 128x128 or resize
func validate_image(image: Image) -> bool:
	# If there is no valid image, return false
	if (!image): return false;
	var imageWidth : int = image.get_width();
	var imageHeight : int = image.get_height();
	# If the width and height are not 128, resize it to be
	if (imageWidth != 128 || imageHeight != 128):
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS);
	return true;

## Handles the switching of buttons between tab changes
## tabIndex: The tab being swapped to
func on_asset_tab_changed(tabIndex: int) -> void:
	imageSwapping.imagePreview.hide();
	animationSwapping.animationPreview.hide();
	audioPreview.hide();
	
	# Tab indices:
	# 0 - images
	# 1 - animations
	# 2 - audio
	if tabIndex == 0:
		imageSwapping.imagePreview.show();
		item_selected(firstImageSelected);
	elif tabIndex == 1:
		animationSwapping.animationPreview.show();
		item_selected(firstAnimationSelected);
	elif tabIndex == 2:
		audioPreview.show();
		item_selected(firstAudioSelected);

## Resets the currently selected asset.
func reset() -> void:
	if (currentSelectedItem.type == AssetItem.AssetType.IMAGE):
		imageSwapping.reset_image();
	elif (currentSelectedItem.type == AssetItem.AssetType.ANIMATION):
		animationSwapping.reset_animation();
	elif (currentSelectedItem.type == AssetItem.AssetType.AUDIO):
		audioSwapping.reset_audio();

## Creates the refresh asset popup.
func reset_image_popup() -> void:
	PopUpManager.create_reset_image_popup(Callable(self, "reset"), currentSelectedItem.displayName);

## Creates the reset all assets popup.
func reset_all_popup() -> void:
	PopUpManager.create_reset_asset_popup(Callable(self, "reset_all"));

## Resets everything within the assets manager
func reset_all() -> void:
	AudioManager.play_UI_effect("UISelection");
	FileSearch.delete_folder(filePath);
	create_file_tree();
	reset_menu();
	refresh_all();

## Deletes and regenerates all buttons
func reset_menu() -> void:
	for button: Button in imagesTab.get_children():
		button.queue_free();
	for button: Button in animationsTab.get_children():
		button.queue_free();
	for button: Button in audioTab.get_children():
		button.queue_free();
	firstImageSelected = null;
	firstAnimationSelected = null;
	firstAudioSelected = null;
	generate_buttons("Tiles", imagesTab);
	generate_buttons("Props", imagesTab);
	generate_buttons("Animations", animationsTab, AssetItem.AssetType.ANIMATION);
	generate_buttons("Audio", audioTab, AssetItem.AssetType.AUDIO);
	on_asset_tab_changed(assetTabs.current_tab);

## Occurs when an asset is chosen in the list. Displays the preview for the selected item.
## selectedItem: The item that is selected, defaults to the firstImageSelected
func item_selected(selectedItem: AssetItem) -> void:
	AudioManager.play_UI_effect("UISelection");
	# Pause the animation
	animationSwapping.play_preview_animation(false);
	audioSwapping.preview_audio_finished();
	# If the selected item is an image, replace its preview
	if (selectedItem.type == AssetItem.AssetType.IMAGE):
		imageSwapping.imageNameToReplace = selectedItem.assetName;
		imageSwapping.imageToReplace = find_image_in_folder(FileSearch.find_directory_by_name(imageSwapping.imageNameToReplace));
		if (imageSwapping.imageToReplace):
			var replacementTexture : Texture2D = ImageTexture.create_from_image(imageSwapping.imageToReplace);
			if (replacementTexture): 
				imageSwapping.imagePreviewTexture.texture = ImageTexture.create_from_image(imageSwapping.imageToReplace);
		else:
			imageSwapping.imagePreviewTexture.texture = ImageTexture.create_from_image(imageSwapping.get_default_image(imageSwapping.imageNameToReplace))
	# If the selected image is an animation, reset the frame and load the animation into currentlyLoadedAnimation
	elif (selectedItem.type == AssetItem.AssetType.ANIMATION):
		animationSwapping.currentAnimationIndex = 0;
		animationSwapping.animationFrameIndex = 0;
		animationSwapping.selectedEntityType = selectedItem.assetName;
		animationSwapping.animationPreviewNameToReplace = DirAccess.get_directories_at(
			FileSearch.find_directory_by_name(
				animationSwapping.selectedEntityType))[animationSwapping.currentAnimationIndex];
		animationSwapping.currentLoadedAnimation.clear();
		animationSwapping.FPSSpinbox.value_changed.disconnect(animationSwapping.fps_updated.bind(true));
		animationSwapping.FPSSpinbox.value_changed.connect(animationSwapping.fps_updated);
		animationSwapping.FPSSpinbox.value = AnimationManager.get_template_sprite(animationSwapping.selectedEntityType).sprite_frames.get_animation_speed(animationSwapping.animationPreviewNameToReplace);
		animationSwapping.FPSSpinbox.value_changed.disconnect(animationSwapping.fps_updated);
		animationSwapping.FPSSpinbox.value_changed.connect(animationSwapping.fps_updated.bind(true));
		
		var animation : Array[Image]= animationSwapping.get_animation_from_folder(animationSwapping.animationPreviewNameToReplace);
		if (animation.is_empty()):
			animation = AnimationManager.get_default_animation_by_name(animationSwapping.animationPreviewNameToReplace);
		for image in animation:
			animationSwapping.currentLoadedAnimation.append(ImageTexture.create_from_image(image));
		animationSwapping.update_animation_preview();
	elif (selectedItem.type == AssetItem.AssetType.AUDIO):
		audioSwapping.audioNameToReplace = selectedItem.assetName;
		audioSwapping.load_preview_audio();

	currentAssetLabel.text = selectedItem.displayName;
	currentSelectedItem = selectedItem;

## Creates all folders in tree for the user
func create_file_tree() -> void:
	# Open the user root directory
	var dir : DirAccess = DirAccess.open("user://");
	# Create all folders for tile types
	for type: String in imageSwapping.tileTypes:
		dir.make_dir_recursive(filePath + "/Images/Tiles/" + type);
	# Create all folders for prop types
	for type: String in imageSwapping.propTypes:
		dir.make_dir_recursive(filePath + "/Images/Props/" + type);
	# Create folder for goal
	dir.make_dir_recursive(filePath + "/Animations/Goal/GoalAnimation");
	dir.make_dir_recursive(filePath + "/Animations/MovingPlatform/PlatformAnimation");
	dir.make_dir_recursive(filePath + "/Animations/Coin/CoinAnimation");
	# Create all folders for animations
	for animation: String in animationSwapping.playerAnimations:
		dir.make_dir_recursive(filePath + "/Animations/Player/" + animation);
	# Create all folders for enemy animations
	for animation: String in animationSwapping.stationaryEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/StationaryEnemy/" + animation);
	for animation: String in animationSwapping.patrollingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/PatrollingEnemy/" + animation);
	for animation: String in animationSwapping.shootingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/ShootingEnemy/" + animation);
	for animation: String in animationSwapping.flyingEnemyAnimations:
		dir.make_dir_recursive(filePath + "/Animations/FlyingEnemy/" + animation);
	for animation: String in animationSwapping.checkpointAnimations:
		dir.make_dir_recursive(filePath + "/Animations/Checkpoint/" + animation);
	# TODO: Add folders for audio
	for audio: String in audioSwapping.audioTypes:
		dir.make_dir_recursive(filePath + "/Audio/" + audio);

## Opens the file dialog for selecting a replacement asset
func open_file_selector() -> void:
	AudioManager.play_UI_effect("UISelection");
	if (currentSelectedItem.type == AssetItem.AssetType.IMAGE):
		fileSelect.title = "Replace " + imageSwapping.imageNameToReplace;
		fileSelect.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
		fileSelect.clear_filters();
		fileSelect.add_filter("*.png");
	elif (currentSelectedItem.type == AssetItem.AssetType.ANIMATION):
		fileSelect.title = "Replace " + animationSwapping.animationPreviewNameToReplace;
		fileSelect.file_mode = FileDialog.FILE_MODE_OPEN_DIR;
	elif (currentSelectedItem.type == AssetItem.AssetType.AUDIO):
		fileSelect.title = "Replace " + audioSwapping.audioNameToReplace;
		fileSelect.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
		fileSelect.clear_filters();
		fileSelect.add_filter("*.mp3");
		fileSelect.add_filter("*.wav");
		fileSelect.add_filter("*.ogg");
	fileSelect.popup_file_dialog();

## Selects a new file, replacing it depending on it's type
## path: the path of the file
func file_selected(path : String) -> void:
	if (currentSelectedItem.type == AssetItem.AssetType.IMAGE):
		imageSwapping.replace_image(path);
	elif (currentSelectedItem.type == AssetItem.AssetType.AUDIO):
		audioSwapping.replace_audio(path);

## Creates a new missing texture for use when a texture is... missing.
## returns: An image using the missing texture.
func get_missing_image() -> Image:
	var image : Image = Image.new();
	image.load(MISSING_TEXTURE);
	validate_image(image);
	return image;

## Clears any images in the replacement directory
## nameToClear: The name of the image being deleted.
## returns: The replacement directory
func clear_files(nameToClear : String) -> DirAccess:
	var targetFilePath : String = FileSearch.find_directory_by_name(nameToClear);
	var targetDirectory : DirAccess  = DirAccess.open(targetFilePath);
	
	if(!targetDirectory): return;
	var existingFiles : PackedStringArray = targetDirectory.get_files();
	# Remove any files in the directory
	for file in existingFiles:
		targetDirectory.remove(file); 
	return targetDirectory;

## Refreshes all images, animations and audio assets.
func refresh_all() -> void:
	AnimationManager.update_template_sprites();
	AnimationManager.refresh_animations();
	imageSwapping.refresh_images();
	animationSwapping.update_animation_preview();

## Initializes the buttons and custom assets when a level is imported or created.   
func setup() -> void:
	print("Setup");
	filePath = masterManager.loadedLevelPath + "Assets";
	FileSearch.filePath = filePath;
	AudioManager.audioLibraryPath = filePath + "/Audio/";
	# Checks if the user has an assets root folder, creates one if not
	var dir : DirAccess = DirAccess.open(filePath);
	if (!dir || dir.get_directories().is_empty()):
		create_file_tree();
	# Clear all buttons;
	clear_buttons(imagesTab);
	clear_buttons(animationsTab);
	clear_buttons(audioTab);
	# Generate all buttons under their tabs
	generate_buttons("Tiles", imagesTab);
	generate_buttons("Props", imagesTab);
	generate_buttons("Animations", animationsTab, AssetItem.AssetType.ANIMATION);
	generate_buttons("Audio", audioTab, AssetItem.AssetType.AUDIO);
	on_asset_tab_changed(assetTabs.current_tab);
	refresh_all();
