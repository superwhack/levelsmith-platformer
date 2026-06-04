extends Node

var masterVolume := 1.0;
var musicVolume := 1.0;
var SFXVolume := 1.0;
# Lowest DB, should be inaudible (it's negative)
const lowestDB = 80;

const audioPlayerCount := 6;
# NOTE: This would be a folder alongside the other assets in the user's local directory, it needs to be changed
const audioLibraryPath := "user://Audio/";
const UIAudioLibraryPath := "res://Assets/Audio/";
const backupAudioLibraryPath := "res://Assets/Audio/Default/";

var musicPlayer : AudioStreamPlayer;
var availablePlayers : Array[AudioStreamPlayer];
var inusePlayers : Array[AudioStreamPlayer]
var queue : Array[String];

##
func _ready() -> void:
	musicPlayer = AudioStreamPlayer.new();
	add_child(musicPlayer);
	musicPlayer.finished.connect(music_loop.bind(musicPlayer));
	musicPlayer.bus = "master";
	
	# Loop through and create every potential audioPlayer for use with UI and in game
	for i in audioPlayerCount:
		var audioPlayer = AudioStreamPlayer.new();
		add_child(audioPlayer);
		availablePlayers.append(audioPlayer);
		audioPlayer.finished.connect(audio_finished.bind(audioPlayer));
		audioPlayer.bus = "master";

## Only done with music, loop instead of ending it
## player: the audio stream player running the music
func music_loop(player: AudioStreamPlayer) -> void:
	player.play();

## Once the audio track is finished
## player: the audio stream player to end
func audio_finished(player: AudioStreamPlayer) -> void:
	availablePlayers.append(player);
	inusePlayers.erase(player);

## Update the current volume by adjusting every player.
func update_volume() -> void:
	musicPlayer.volume_db = (lowestDB * masterVolume * musicVolume) - lowestDB;
	print(musicPlayer.volume_db);
	for i in inusePlayers.size():
		inusePlayers[i].volume_db = (lowestDB * masterVolume * SFXVolume) - lowestDB;
	for i in availablePlayers.size():
		availablePlayers[i].volume_db = (lowestDB * masterVolume * SFXVolume) - lowestDB;

## NOTE: These two functions can probably be shortened since we know that the associated files have specific filePaths
## Add specified SFX to the queue from builder sounds
## effectName: name of the effect to play
func play_UI_effect(effectName: String) -> void:
	var fullPath : String = UIAudioLibraryPath + effectName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		queue.append(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		queue.append(fullPath + ".wav");

## Play the music track for the builder
## musicName: name of the song to play
func play_UI_music(musicName: String) -> void:
	musicPlayer.stop();
	var fullPath : String = UIAudioLibraryPath + musicName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		musicPlayer.stream = load(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		musicPlayer.stream = load(fullPath + ".wav");
	musicPlayer.play();

## Play the music track
## musicName: name of the sound effect
func play_music(musicName: String, isDefault: bool = false) -> void:
	musicPlayer.stop();
	var fullPath : String;
	if isDefault:
		fullPath = backupAudioLibraryPath + musicName;
	else:
		fullPath = audioLibraryPath + musicName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		musicPlayer.stream = AudioStreamMP3.load_from_file(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		musicPlayer.stream = AudioStreamWAV.load_from_file(fullPath + ".wav");
	else:
		print(musicName, "file not found or doesn't use .wav/.mp3! Reading backup instead.");
		play_music(musicName, true);
		return;
	musicPlayer.play();

## Add specified SFX to the queue
## effectName: name of the sound effect
func play_effect(effectName: String, isDefault: bool = false) -> void:
	var fullPath : String;
	if (isDefault):
		fullPath = backupAudioLibraryPath + effectName;
	else:
		fullPath = audioLibraryPath + effectName;
	if FileAccess.file_exists(fullPath + ".mp3"):
		queue.append(fullPath + ".mp3");
	elif FileAccess.file_exists(fullPath + ".wav"):
		queue.append(fullPath + ".wav");
	else:
		print(effectName, " file not found or doesn't use .wav/.mp3! Reading backup instead.");
		play_effect(effectName, true);
		return;

## Reset and stop all audio
func reset_audio() -> void:
	for i in inusePlayers.size():
		inusePlayers[i].stop();
		availablePlayers.append(inusePlayers[i]);
	inusePlayers.clear();
	musicPlayer.stop();

## If there are any current sounds in the queue and any avaliable players, start playing the sound.
## delta: unused
func _process(delta: float) -> void:
	if !queue.is_empty() && !availablePlayers.is_empty():
		var path = queue.pop_front(); 
		if path.ends_with(".mp3"):
			availablePlayers[0].stream = AudioStreamMP3.load_from_file(path);
		elif path.ends_with(".wav"):
			availablePlayers[0].stream = AudioStreamWAV.load_from_file(path);
		else:
			print("Error, somehow a different extention made it into here!")
		availablePlayers[0].play();
		availablePlayers.pop_front();
