extends Line2D

# Necessary references
@export var parent : Node2D;

# Texture for start and end points
var hollowCircle : Texture2D = preload("res://Assets/Sprites/UI/PreviewLineEndpoint.png");

# Sprites for the start and end points
var startPoint : Sprite2D;
var endPoint : Sprite2D;

## Updates when this node first generates.
func _ready():
	startPoint = Sprite2D.new(); 
	startPoint.texture = hollowCircle;
	add_child(startPoint);
	
	endPoint = Sprite2D.new(); 
	endPoint.texture = hollowCircle;
	endPoint.hide();
	add_child(endPoint);
	update();

## Updates the preview line and its endpoints.
## offset: The position of the line's ending.
func update(offset : Vector2 = Vector2((parent.pointB.x - parent.pointA.x) / Global.TILE_SIZE, (parent.pointB.y - parent.pointA.y) / Global.TILE_SIZE)) -> void:
	# Displacement: Makes the end of the line slightly behind the circle
	# Size is in pixels
	var displacementSize : float = 12;
	var circleDisplacement : Vector2 = offset.normalized() * displacementSize;
	var endPosition : Vector2 = offset * Global.TILE_SIZE;
	
	global_position = parent.global_position;
	clear_points();
	add_point(Vector2.ZERO);
	add_point(endPosition - circleDisplacement);
	
	endPoint.position = endPosition;
	
	if parent is EnemyFlyer:
		parent.animatedSprites.flip_h = -offset.x > 0

	if endPosition == Vector2.ZERO:
		endPoint.hide();
	else:
		endPoint.show();
