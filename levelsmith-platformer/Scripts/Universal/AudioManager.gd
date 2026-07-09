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

## Create all players and connect them properly
func _ready() -> void:
	
	soundLevels = {
		"Tile_Place_Error": 0.5,
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
	var fullPath : String = UI_AUDIO_LIBRARY_PATH + effectName;
	if (FileAccess.file_exists(fullPath + ".mp3")):
		queue.append(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		queue.append(fullPath + ".wav");

## Play the music track
## musicName: name of the sound effect
func play_music(musicName: String) -> void:
	musicPlayer.stop();
	var fullPath : String = audioLibraryPath + musicName;
	if (FileAccess.file_exists(fullPath + ".mp3")):
		musicPlayer.stream = AudioStreamMP3.load_from_file(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		musicPlayer.stream = AudioStreamWAV.load_from_file(fullPath + ".wav");
	else:
		print(musicName, " file not found or doesn't use .wav/.mp3! Reading backup instead.");
		# Under the assumption all backups will be .mp3 for music
		musicPlayer.stream = load(BACKUP_AUDIO_LIBRARY_PATH + musicName + ".mp3");
	musicPlayer.play();

## Add specified SFX to the queue
## effectName: name of the sound effect
func play_effect(effectName: String) -> void:
	if queue.size() >= AUDIO_QUEUE_LIMIT:
		return;
	var fullPath : String = audioLibraryPath + effectName;
	# If the path points to a folder, then one random file from the folder needs to be selected instead.
	if DirAccess.dir_exists_absolute(fullPath + "/"):
		var validFiles : PackedStringArray;
		var files = DirAccess.get_files_at(fullPath);
		# Only non .imports are accepted
		for file in files:
			if !file.ends_with(".import"):
				validFiles.append(file);
		var randomFileIndex = randi() % validFiles.size();
		fullPath += "/" + (validFiles[randomFileIndex]);
		queue.append(fullPath);
	# Else just see if it's a .mp3 or .wav
	elif (FileAccess.file_exists(fullPath + ".mp3")):
		queue.append(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		queue.append(fullPath + ".wav");
	else:
		print(effectName, " file not found or doesn't use .wav/.mp3! Reading backup instead.");
		# Under the assumption all backups will be .wav for effects
		queue.append(BACKUP_AUDIO_LIBRARY_PATH + effectName + ".wav")

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
	var fullPath : String = audioLibraryPath + effectName;
	# If the path points to a folder, then one random file from the folder needs to be selected instead.
	if DirAccess.dir_exists_absolute(fullPath + "/"):
		var validFiles : PackedStringArray;
		var files = DirAccess.get_files_at(fullPath);
		# Only non .imports are accepted
		for file in files:
			if !file.ends_with(".import"):
				validFiles.append(file);
		var randomFileIndex = randi() % validFiles.size();
		fullPath += "/" + (validFiles[randomFileIndex]);
		walkingPlayer.stream = load(fullPath);
	# Else just see if it's a .mp3 or .wav
	elif (FileAccess.file_exists(fullPath + ".mp3")):
		walkingPlayer.stream = load(fullPath + ".mp3");
	elif (FileAccess.file_exists(fullPath + ".wav")):
		walkingPlayer.stream = load(fullPath + ".wav");
	else:
		print(effectName, " file not found or doesn't use .wav/.mp3! Reading backup instead.");
		# Under the assumption all backups will be .wav for effects
		walkingPlayer.stream = load(BACKUP_AUDIO_LIBRARY_PATH + effectName + ".wav")
	walkingPlayer.play();

## Reset and stop all audio
func reset_audio() -> void:
	for i in inusePlayers.size():
		inusePlayers[i].stop();
		availablePlayers.append(inusePlayers[i]);
	queue.clear();
	inusePlayers.clear();
	musicPlayer.stop();

## Play the sound for an asset when in the assetmanager
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
## delta: unused
func _process(_delta: float) -> void:
	# If there aren't any available players, stop the longest running player early.
	if (!queue.is_empty() && availablePlayers.is_empty()):
		inusePlayers[0].stop();
		audio_finished(inusePlayers[0]);
	if (!queue.is_empty() && !availablePlayers.is_empty()):
		var path : String = queue.pop_front(); 
		
		# If the sound level has an adjustment, apply it
		var audioName = path.substr(path.rfind("/") + 1);
		audioName = audioName.erase(audioName.rfind("."), 4);
		print(audioName);
		if soundLevels.has(audioName):
			availablePlayers[0].volume_db = linear_to_db(masterVolume * SFXVolume * soundLevels[audioName]);
		
		if (path.ends_with(".mp3")):
			availablePlayers[0].stream = AudioStreamMP3.load_from_file(path);
		elif (path.ends_with(".wav")):
			availablePlayers[0].stream = AudioStreamWAV.load_from_file(path);
		else:
			print("Error, somehow a different extention made it into here!")
		availablePlayers[0].play();
		inusePlayers.append(availablePlayers[0]);
		availablePlayers.pop_front();
