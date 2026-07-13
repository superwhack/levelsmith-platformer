extends Line2D

# Necessary references
@export var endpoint : Sprite2D;
@export var parent : Node2D;

## Updates when this node first generates.
func _ready():
	update();

## Updates the preview line and its endpoints.
## offset: The position of the line's ending.
func update(offset : Vector2 = Vector2((parent.pointB.x - parent.pointA.x) / Global.TILE_SIZE, (parent.pointB.y - parent.pointA.y) / Global.TILE_SIZE)) -> void:
	modulate.a = .5;
	global_position = parent.global_position;
	clear_points();
	add_point(Vector2.ZERO);
	add_point(offset * Global.TILE_SIZE);
	
	var last_point_index: int = get_point_count() - 1;
	if get_point_position(last_point_index) == get_point_position(0):
		endpoint.hide();
	else:
		endpoint.show();
		endpoint.position = get_point_position(last_point_index);
		endpoint.rotation = offset.angle();
