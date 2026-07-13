extends Line2D

@export var endpoint : Sprite2D;
@export var parent : Node2D;

@onready var pointA : Vector2 = parent.pointA;
@onready var pointB : Vector2 = parent.pointB;

func _ready():
	update();

## Runs every frame and ensures point A and B are synchronized with the parent
func _process(_delta : float) -> void:
	pointA = parent.pointA;
	pointB = parent.pointB;

## Update the preview for the flying enemy
## x: The x to update with
## y: The y to update with
func update(offset : Vector2 = Vector2((pointB.x - pointA.x) / Global.TILE_SIZE, (pointB.y - pointA.y) / Global.TILE_SIZE)) -> void:
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
