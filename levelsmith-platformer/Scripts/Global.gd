extends Node

# A signal for when the player dies
signal death;

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

# Object Types
enum ObjectType {
	SLOPE = 6,
	GOAL = 7,
	SPAWN = 8,
	MOVING = 9,
	SHOOTING = 10, 
	FLYING = 11,
	PROP1 = 12,
	PROP2 = 13,
	PROP3 = 14,
	PROP4 = 15,
	PROP5 = 16, 
	PROP6 = 17
}
