extends Node

func get_collision_data(raycast : RayCast2D) -> TileData:
	var collider : Object = raycast.get_collider();
	if (collider is TileMapLayer): 
		var tileLayer : TileMapLayer = collider;
		var hitGlobal : Vector2 = raycast.get_collision_point();
		var hitNormal : Vector2 = raycast.get_collision_normal();
		var probeGlobal : Vector2 = hitGlobal - hitNormal * 0.5;
		var probeLocal : Vector2 = tileLayer.to_local(probeGlobal);
		var tilePos : Vector2i = tileLayer.local_to_map(probeLocal);
		var tileData : TileData = tileLayer.get_cell_tile_data(tilePos);
		if tileData:
			return tileData;
	return null;
