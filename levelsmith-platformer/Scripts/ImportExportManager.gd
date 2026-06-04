extends Node
var levelPath : String;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func make_new_level(name: String) -> void:
	levelPath = "user://" + name + "/";
	# Create all necessary folders for the level
	DirAccess.make_dir_absolute(levelPath);
	DirAccess.make_dir_absolute(levelPath + "Assets/");
	DirAccess.make_dir_absolute(levelPath + "Assets/Sprites");
	DirAccess.make_dir_absolute(levelPath + "Assets/Sprites/Tiles");
	DirAccess.make_dir_absolute(levelPath + "Assets/Sprites/Props");
	DirAccess.make_dir_absolute(levelPath + "Assets/Sprites/Entities");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Player");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Player/Idle");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Player/Run");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Player/Jump");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Player/Death");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Stationary");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Stationary/Idle");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Stationary/Death");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Patrolling");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Patrolling/Walk");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Patrolling/Death");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Flying");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Flying/Fly");
	DirAccess.make_dir_absolute(levelPath + "Assets/Animations/Flying/Death");
	DirAccess.make_dir_absolute(levelPath + "Assets/Audio");
	
	#var file = FileAccess.open(levelPath + "/a.txt", FileAccess.WRITE);
	#file.store_string("TESTING");
	#file.close();
