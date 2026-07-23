extends Node

## Obtains the tile data of the raycast's destination.
## raycast: The raycast to analyze
## returns: The tile data of the detected tile, or nothing if the collider is something else.
func get_collision_data(raycast : RayCast2D) -> TileData:
	var collider : Object = raycast.get_collider();
	if (collider is TileMapLayer): 
		var tileLayer : TileMapLayer = collider;
		var hitGlobal : Vector2 = raycast.get_collision_point();
		var probeLocal : Vector2 = tileLayer.to_local(hitGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		if tileData:
			return tileData;
	return null;
