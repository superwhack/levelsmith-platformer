extends Node

# Signals related to current gamestates
signal death;
signal reload;
signal complete;

# Tile size
const tileSize: int = 128;

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
	GOAL = 7,
	PLAYER = 8,
	PATROLLING = 9,
	SHOOTING = 10, 
	FLYING = 11,
	STATIONARY = 12, 
	PROP1 = 13,
	PROP2 = 14,
	PROP3 = 15,
	PROP4 = 16,
	PROP5 = 17, 
	PROP6 = 18
}

const ERASING_TILE: int = 99;
