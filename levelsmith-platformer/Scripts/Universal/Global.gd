extends Node

# Signals related to current gamestates
signal death;
signal reload;
signal complete;
signal levelCreated;

# Tile size
const TILE_SIZE : int = 128;

# Application State
enum State {
	MAIN_MENU,
	EDIT,
	PLAY
}

# Tools (Editing State)
enum Tool {
	BRUSH,
	BOX_BRUSH,
	CURSOR
}

# Hotbar state (primarily for hotkeys)
enum HotbarState {
	TILES,
	ENTITIES,
	PROPS
}

# Box brush state (for previewing and confirmation)
enum BoxBrushState {
	INACTIVE,
	PLACE,
	DELETE,
	PLACE_CONFIRM,
	DELETE_CONFIRM
}

# Tile Types
enum TileType {
	SOLID = 0,
	DEATH = 1, 
	ONEWAY = 2,
	ICE = 3,
	STICKY = 4,
	BOUNCE = 5, 
	SLOPE = 6,
}

# Entity Types
enum EntityType {
	GOAL = 500,
	PLAYER = 501,
	PATROLLING = 502,
	SHOOTING = 503, 
	FLYING = 504,
	STATIONARY = 505, 
	COIN = 506,
	MOVING_PLATFORM = 507,
	PROP1 = 600,
	PROP2 = 601,
	PROP3 = 602,
	PROP4 = 603,
	PROP5 = 604, 
	PROP6 = 605,
}

const BEDROCK_TILE: int = 9998;
const ERASING_TILE: int = 9999;
