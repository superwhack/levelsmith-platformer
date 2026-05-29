extends Node

# Signals related to current gamestates
signal death;
signal reload;
signal complete;


# Application State
enum State {
	EDIT,
	PLAY
}

# Tools (Editing State)
enum Tool {
	BRUSH,
	BOX_BRUSH,
	CURSOR
}

# Tile Types
enum TileType {
	SOLID = 0,
	DEATH = 1, 
	ONEWAY = 2,
	ICE = 3,
	STICKY = 4,
	BOUNCE = 5, 
}

# Entity Types
enum EntityType {
	SLOPE = 6,
	GOAL = 7,
	SPAWN = 8,
	PATROLLING = 9,
	STATIONARY = 10, 
	FLYING = 11,
	PROP1 = 12,
	PROP2 = 13,
	PROP3 = 14,
	PROP4 = 15,
	PROP5 = 16, 
	PROP6 = 17
}
