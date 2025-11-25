class_name RoadsideSprite
extends Resource
## RoadsideSprite - A sprite/object placed alongside the road

# Type identifier for the sprite (e.g., "tree", "rock", "sign", "building")
@export var sprite_type: String = "tree"

# X offset from road center (negative = left, positive = right)
# Values > 1.0 or < -1.0 place objects beyond the road edge
@export var x_offset: float = 1.5

# Scale multiplier for the sprite
@export var scale: float = 1.0

# Optional: specific Z offset within the segment
@export var z_offset: float = 0.0

# Collision enabled?
@export var collidable: bool = true

# Collision radius (in world units)
@export var collision_radius: float = 50.0
