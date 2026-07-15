extends Node

# 0% - 100% volume measured in floats 
var masterVolume : float = 0.7;
var musicVolume : float = 0.7;
var SFXVolume : float = 0.7;

var soundLevels : Dictionary;

# Max number of audio players to be running at once (excluding one for music and one for walking)
const AUDIO_PLAYER_COUNT : int = 12;
const AUDIO_QUEUE_LIMIT : int = AUDIO_PLAYER_COUNT;

# All folders for audio
## BUG: UNTIL AUDIO LIBRARY PATH IS READY, IT IS TO BE ASSIGNED TO THE DEFAULT
var audioLibraryPath : String = "res://Assets/Defaults/Assets/Audio/";
#var audioLibraryPath : String = "user://Audio/";
const UI_AUDIO_LIBRARY_PATH : String = "res://Assets/Audio/";
const BACKUP_AUDIO_LIBRARY_PATH : String = "res://Assets/Defaults/Assets/Audio/";

# Players and the queue that holds filepaths to play
var musicPlayer : AudioStreamPlayer;
var walkingPlayer : AudioStreamPlayer;
var availablePlayers : Array[AudioStreamPlayer];
var inusePlayers : Array[AudioStreamPlayer]
var queue : Array[String];
var currentWalkingEffect : Global.WalkingEffect;

# Audio player for the asset manager
var assetManagerPlayer : AudioStreamPlayer

# Preview music timer for the settings menu
var previewMusicTimer : float = -1.0;

# The amount of time in seconds between each ui sound effect
var uiEffectCooldown : float = 0.035;

## Create all players and connect them properly
func _ready() -> void:
	
	soundLevels = {
		"Tile_Place_Error": 0.3,
	}
	
	musicPlayer = AudioStreamPlayer.new();
	walkingPlayer = AudioStreamPlayer.new();
	assetManagerPlayer = AudioStreamPlayer.new();
	process_mode = Node.PROCESS_MODE_ALWAYS;
	add_child(musicPlayer);
	add_child(walkingPlayer);
	add_child(assetManagerPlayer);
	musicPlayer.finished.connect(music_loop.bind(musicPlayer));
	musicPlayer.bus = "master";
	walkingPlayer.bus = "master";
	assetManagerPlayer.bus = "master";
	
	# Loop through and create every potential audioPlayer for use with UI and in game
	for i in AUDIO_PLAYER_COUNT:
		var audioPlayer : AudioStreamPlayer = AudioStreamPlayer.new();
		add_child(audioPlayer);
		availablePlayers.append(audioPlayer);
		audioPlayer.finished.connect(audio_finished.bind(audioPlayer));
		audioPlayer.bus = "master";
	
	update_volume();

## Pause the current music player
## pause: true if the music should be paused
func pause_music(pause : bool) -> void:
	musicPlayer.stream_paused = pause;

## Play the music to preview sound levels
## musicName: music to play
func play_music_preview(musicName:  String) -> void:
	if musicPlayer.playing:
		return;
	play_music(musicName);
	previewMusicTimer = 0;

## Stop playing the music
func stop_music_preview() -> void:
	await get_tree().process_frame;
	if previewMusicTimer >= 1.5:
		musicPlayer.stop();
		previewMusicTimer = -1;
	else:
		stop_music_preview();

## Only done with music, loop instead of ending it
## player: the audio stream player running the music
func music_loop(player: AudioStreamPlayer) -> void:
	player.play();

## Once the audio track is finished
## player: the audio stream player to end
func audio_finished(player: AudioStreamPlayer) -> void:
	availablePlayers.append(player);
	player.volume_db = linear_to_db(masterVolume * SFXVolume);
	inusePlayers.erase(player);

## Update the current volume by adjusting every player. If the volume is set to 0 for anything, mute completely
func update_volume() -> void:
	musicPlayer.volume_db = linear_to_db(masterVolume * musicVolume);
	walkingPlayer.volume_db = linear_to_db(masterVolume * SFXVolume);
	for i in inusePlayers.size():
		inusePlayers[i].volume_db = linear_to_db(masterVolume * SFXVolume);
	for i in availablePlayers.size():
		availablePlayers[i].volume_db = linear_to_db(masterVolume * SFXVolume);

## Add specified SFX to the queue from builder sounds
## effectName: name of the effect to play
func play_UI_effect(effectName: String) -> void:
	if queue.size() >= AUDIO_QUEUE_LIMIT:
		return;
	# Check all players in use, if any are playing the same audio, check if the cooldown is up, return if not
	for player in inusePlayers:
		if (player.stream.has_meta("audioName")):
			if (player.stream.get_meta("audioName") == effectName):
				if (player.get_playback_position() + AudioServer.get_time_since_last_mix() <= uiEffectCooldown):
					return;
	var fullPath : String = UI_AUDIO_LIBRARY_PATH + effectName;
	if (FileAccess.file_exists(fullPath + ".mp3")):
		queue.append(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		queue.append(fullPath + ".wav");



## Play the music track
## musicName: name of the sound effect
func play_music(musicName: String) -> void:
	musicPlayer.stop();
	var fullPath : String = audioLibraryPath + musicName + "/" + musicName;
	if (FileAccess.file_exists(fullPath + ".mp3")):
		musicPlayer.stream = AudioStreamMP3.load_from_file(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		musicPlayer.stream = AudioStreamWAV.load_from_file(fullPath + ".wav");
	else:
		# Under the assumption all backups will be .mp3 for music
		musicPlayer.stream = AudioStreamMP3.load_from_file(BACKUP_AUDIO_LIBRARY_PATH + "LevelMusic/LevelMusic.mp3");
	musicPlayer.play();

## Add specified SFX to the queue
## effectName: name of the sound effect
func play_effect(effectName: String) -> void:
	if queue.size() >= AUDIO_QUEUE_LIMIT:
		return;
	var fullPath : String = audioLibraryPath + effectName + "/" + effectName;
	# If the path points to a folder, then one random file from the folder needs to be selected instead.
	# NOTE : This code is used for choosing a random sound effect from a folder of multiple sound effects. This is currently not implemented.
	#if DirAccess.dir_exists_absolute(fullPath + "/"):
		#var validFiles : PackedStringArray;
		#var files = DirAccess.get_files_at(fullPath);
		## Only non .imports are accepted
		#for file in files:
			#if !file.ends_with(".import"):
				#validFiles.append(file);
		#var randomFileIndex = randi() % validFiles.size();
		#fullPath += "/" + (validFiles[randomFileIndex]);
		#queue.append(fullPath);
	# Else just see if it's a .mp3 or .wav
	if (FileAccess.file_exists(fullPath + ".mp3")):
		queue.append(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		queue.append(fullPath + ".wav");
	else:
		# Under the assumption all backups will be .wav for effects
		queue.append(BACKUP_AUDIO_LIBRARY_PATH + effectName + "/" + effectName + ".wav")
	# Iterate through each in use audio player, if any are playing the current audio, stop the other one.
	for player in inusePlayers:
		if (player.stream != null):
			if (player.stream.has_meta("audioName")):
				if (player.stream.get_meta("audioName") == effectName):
					player.stop();

## Add and play a new walking effect, only one at a time
## effectName: name of the walking effect
func play_effect_walking(walkingEffect: Global.WalkingEffect) -> void:
	if walkingPlayer.playing && currentWalkingEffect == walkingEffect:
		return;
	currentWalkingEffect = walkingEffect;
	var effectName = "";
	match walkingEffect:
		Global.WalkingEffect.NONE:
			walkingPlayer.stop();
			return;
		Global.WalkingEffect.GENERAL:
			effectName = "WalkingGeneral";
		Global.WalkingEffect.ICE:
			effectName = "WalkingIce";
		Global.WalkingEffect.SLIME:
			effectName = "WalkingSlime";
	var fullPath : String = audioLibraryPath + effectName + "/" + effectName;
	# If the path points to a folder, then one random file from the folder needs to be selected instead.
	# NOTE : This code is used for choosing a random sound effect from a folder of multiple sound effects. This is currently not implemented.
	#if (DirAccess.dir_exists_absolute(fullPath + "/") && FileSearch.file_count_in_folder(effectName) > 0):
		#var validFiles : PackedStringArray;
		#var files = DirAccess.get_files_at(fullPath);
		## Only non .imports are accepted
		#for file in files:
			#if !file.ends_with(".import"):
				#validFiles.append(file);
		#var randomFileIndex = randi() % validFiles.size();
		#fullPath += "/" + (validFiles[randomFileIndex]);
		#walkingPlayer.stream = load(fullPath);
	# Else just see if it's a .mp3 or .wav
	if (FileAccess.file_exists(fullPath + ".mp3")):
		walkingPlayer.stream = load(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		walkingPlayer.stream = load(fullPath + ".wav");
	else:
		# Under the assumption all backups will be .wav for effects
		walkingPlayer.stream = load(BACKUP_AUDIO_LIBRARY_PATH + effectName + "/" + effectName + ".wav")
	walkingPlayer.play();

## Reset and stop all audio
func reset_audio() -> void:
	for i in inusePlayers.size():
		inusePlayers[i].stop();
		availablePlayers.append(inusePlayers[i]);
	queue.clear();
	inusePlayers.clear();
	musicPlayer.stop();
	walkingPlayer.stop();

## Play the sound for an asset when in the AssetManager
## assetName: the name of the file to play from, no extentions
func play_asset(assetName: String) -> void:
	var fullPath : String = audioLibraryPath + assetName;
	if (FileAccess.file_exists(fullPath + ".mp3")):
		assetManagerPlayer.stream = AudioStreamMP3.load_from_file(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		assetManagerPlayer.stream = AudioStreamWAV.load_from_file(fullPath + ".wav");
	else:
		print(assetName, " file not found or doesn't use .wav/.mp3! Reading backup instead.");
	assetManagerPlayer.play();

## If there are any current sounds in the queue and any avaliable players, start playing the sound.
## delta: used for tracking preview timer
func _process(delta: float) -> void:
	if previewMusicTimer >= 0:
		previewMusicTimer += delta;
	# If there aren't any available players, stop the longest running player early.
	if (!queue.is_empty() && availablePlayers.is_empty()):
		inusePlayers[0].stop();
		audio_finished(inusePlayers[0]);
	if (!queue.is_empty() && !availablePlayers.is_empty()):
		var path : String = queue.pop_front(); 
		
		# If the sound level has an adjustment, apply it
		var audioName = path.substr(path.rfind("/") + 1);
		audioName = audioName.erase(audioName.rfind("."), 4);
		if soundLevels.has(audioName):
			availablePlayers[0].volume_db = linear_to_db(masterVolume * SFXVolume * soundLevels[audioName]);
		
		if (path.ends_with(".mp3")):
			availablePlayers[0].stream = AudioStreamMP3.load_from_file(path);
		elif (path.ends_with(".wav")):
			availablePlayers[0].stream = AudioStreamWAV.load_from_file(path);
		else:
			print("Error, somehow a different extention made it into here!")
		if (availablePlayers[0].stream):
			availablePlayers[0].stream.set_meta("audioName", audioName);
		availablePlayers[0].play();
		inusePlayers.append(availablePlayers[0]);
		availablePlayers.pop_front();

func find_audio_in_folder(folderPath : String) -> AudioStream:
# Opens the folder at the given folderName path
	var dir : DirAccess = DirAccess.open(folderPath);
	# If a folder was sucessfully opened
	if (dir):
		# Initialize file stream
		dir.list_dir_begin();
		# Get the image name in the folder
		var audioName : String = dir.get_next();
		# If there is no image in the folder, return null
		if (audioName == ""):
			return null;
		else:
			var audio : AudioStream;
			if (audioName.get_extension().to_lower() == "mp3"):
				audio = AudioStreamMP3.new();
				audio = AudioStreamMP3.load_from_file(folderPath + "/" + audioName);
			elif (audioName.get_extension().to_lower() == "wav"):
				audio = AudioStreamWAV.new();
				audio = AudioStreamWAV.load_from_file(folderPath + "/" + audioName);
			else:
				PopUpManager.create_error_popup("File not valid", "Non mp3/wav file in audio folder");
			if (audio != null):
				return audio;
			return null;
	else:
		PopUpManager.create_error_popup("Could not open file path", "Could not open file at " + folderPath + ".");
		return null;
#func find_effect_name(path: String) -> String:
