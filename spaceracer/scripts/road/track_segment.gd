class_name TrackSegment
extends Resource
## TrackSegment - A single segment of the track with curve and hill data

@export var index: int = 0
@export var start_z: float = 0.0
@export var length: float = 200.0

# Curve: negative = left, positive = right
# This is the 'ddx' from the pseudo-3D tutorial - the curve acceleration
@export var curve: float = 0.0

# Hill: negative = downhill, positive = uphill
# This is the 'ddy' equivalent for vertical displacement
@export var hill: float = 0.0

# Road properties that can vary per segment
@export var road_width_multiplier: float = 1.0

# Roadside sprites/objects attached to this segment
@export var sprites: Array[RoadsideSprite] = []

func _init() -> void:
	sprites = []

func add_sprite(sprite_type: String, x_offset: float, scale: float = 1.0) -> void:
	var sprite = RoadsideSprite.new()
	sprite.sprite_type = sprite_type
	sprite.x_offset = x_offset
	sprite.scale = scale
	sprites.append(sprite)
