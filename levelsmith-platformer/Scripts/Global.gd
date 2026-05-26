extends Node

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
	SOLID,
	DEATH, 
	ONEWAY,
	ICE,
	STICKY,
	BOUNCE, 
	SLOPE
}
