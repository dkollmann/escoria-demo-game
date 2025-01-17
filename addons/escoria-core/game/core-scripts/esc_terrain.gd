@tool
@icon("res://addons/escoria-core/design/esc_terrain.svg")
# A walkable Terrains
extends Node2D
class_name ESCTerrain


# Logger class
const Logger = preload("res://addons/escoria-core/game/esc_logger.gd")


# Visualize scales or the lightmap for debugging purposes
enum DebugMode {
	NONE,
	SCALES,
	LIGHTMAP
}


# Scaling texture
@export var scales: Texture2D: set = _set_scales

# Minimum scaling
@export var scale_min: float = 0.3

# Maximum scaling
@export var scale_max: float = 1.0

# Lightmap texture
@export var lightmap: Texture2D: set = _set_lightmap

# The scaling factor for the scale and light maps
@export var bitmaps_scale: Vector2 = Vector2(1,1): set = _set_bm_scale

# Multiplier applied to the player speed on this terrain
@export var player_speed_multiplier: float = 1.0

# Multiplier how much faster the player will walk when fast mode is on
# (double clicked)
@export var player_doubleclick_speed_multiplier: float = 1.5

# Additional modulator to the lightmap texture
@export var lightmap_modulate: Color = Color(1, 1, 1, 1)

# Currently selected debug visualize mode
@export var debug_mode = DebugMode.NONE: # (int, "None", "Scales", "Lightmap")
		set = _set_debug_mode


# The currently activ navigation polygon
var current_active_navigation_instance: NavigationRegion2D = null

# Currently visualized texture for debug mode
var _texture = null

# The image from the lightmap texture
var _lightmap_data: Image

# The image from the scales texture
var _scales_data: Image

# Prohibits multiple calls to update_texture
var _texture_in_update = false

# Logger instance
@onready var logger = Logger.ESCLoggerFile.new()

# Set a reference to the active navigation polygon, register to Escoria
# and update the texture
func _ready():
	connect("child_entered_tree", Callable(self, "_check_multiple_enabled_navpolys"))
	connect("child_exiting_tree", Callable(self, "_check_multiple_enabled_navpolys").bind(true))

	_check_multiple_enabled_navpolys()
	if !Engine.is_editor_hint():
		escoria.room_terrain = self
	_update_texture()


# Checks whether multiple navigation polygons are enabled.
# Shows a warning in the terminal if this happens.
# TODO: change this "simple" console log for an editor warning
# by overriding Node._get_configuration_warning() after we get rid of
# deprecated Navigation2D.
#
# #### Parameters
#
# - node: if this method is triggered by child_entered_tree or
# child_exited_tree signals, parameter is the added node.
func _check_multiple_enabled_navpolys(node: Node = null, is_exiting: bool = false) -> void:
	var navigation_enabled_found = false
	if node != null \
			and not is_exiting \
			and node is NavigationRegion2D \
			and node.enabled:
		navigation_enabled_found = true

	for n in get_children():
		if is_exiting and n == node:
			continue
		if n is NavigationRegion2D and n.enabled:
			if navigation_enabled_found:
				if Engine.is_editor_hint():
					logger.warn(
						self,
						"Multiple NavigationPolygonInstances enabled " + \
						"at the same time."
					)
				else:
					logger.error(
						self,
						"Multiple NavigationPolygonInstances enabled " + \
						"at the same time."
					)
				return
			else:
				navigation_enabled_found = true
				current_active_navigation_instance = n


func get_simple_path(from: Vector2, to: Vector2, optimize: bool = true, layers: int = 1) -> PackedVector2Array:
	return NavigationServer2D.map_get_path(get_world_2d().navigation_map, from, to, optimize, layers)


# Return the Color of the lightmap pixel for the specified position
#
# #### Parameters
#
# - pos: Position to calculate lightmap for
# **Returns** The color of the given point
func get_light(pos: Vector2) -> Color:
	if not _lightmap_data or _lightmap_data.is_empty():
		return Color(1, 1, 1, 1)
	var c = _get_color(_lightmap_data, pos)
	return _get_color(_lightmap_data, pos) * lightmap_modulate


# Calculate the scale inside the scale range for a given scale factor
#
# #### Parameters
#
# - factor: The factor for the scaling according to the scale map
# **Returns** The scaling
func get_scale_range(factor: float) -> Vector2:
	factor = scale_min + (scale_max - scale_min) * factor
	return Vector2(factor, factor)


# Get the terrain scale factor for a given position
#
# #### Parameters
#
# - pos: The position to calculate for
# **Returns** The scale factor for the given position
func get_terrain(pos: Vector2) -> float:
	if _scales_data == null || _scales_data.is_empty():
		return 1.0
	return _get_color(_scales_data, pos).v


# Small helper to get the color of an image at a position
func _get_color(image: Image, pos: Vector2) -> Color:
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var color=image.get_pixel(pos.x, pos.y)
	false # image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	return color


# Set the bitmap scaling
#
# #### Parameters
#
# - p_scale: Scale to set
func _set_bm_scale(p_scale: Vector2):
	bitmaps_scale = p_scale
	_update_texture()


# Set the lightmap texture
#
# #### Parameters
#
# - p_lightmap: Lightmap texture to set
func _set_lightmap(p_lightmap: Texture2D):
	var need_init = (lightmap != p_lightmap) or (lightmap and not _lightmap_data)

	lightmap = p_lightmap

	# It's bad enough a new copy is created when reading a pixel, we don't
	# also need to get the data for every read to make yet another copy
	if need_init:
		_lightmap_data = lightmap.get_image()

	_update_texture()


# Set the scales texture
#
# #### Parameters
#
# - p_scales: Scale texture to set
func _set_scales(p_scales: Texture2D):
	scales = p_scales
	_scales_data = scales.get_image()
	_update_texture()


# Set the debug mode
#
# #### Parameters
#
# - p_mode: Debug mode to set
func _set_debug_mode(p_mode: int):
	debug_mode = p_mode
	_update_texture()


# Update the debug texture, if it is dirty
func _update_texture():
	if _texture_in_update:
		return
	_texture_in_update = true
	call_deferred("_do_update_texture")


# Update the texture and optionally set the debug texture
func _do_update_texture():
	_texture_in_update = false
	if !is_inside_tree() or !Engine.is_editor_hint():
		return

	if debug_mode == DebugMode.NONE:
		queue_redraw()
		return

	_texture = ImageTexture.new()
	if debug_mode == DebugMode.SCALES:
		if scales != null:
			_texture = scales
	elif debug_mode == DebugMode.LIGHTMAP:
		if lightmap != null:
			_texture = lightmap

	queue_redraw()


# Draw debugging visualizations
func _draw():
	if _texture == null or \
			not Engine.is_editor_hint() or \
			debug_mode == DebugMode.NONE:
		if current_active_navigation_instance:
			current_active_navigation_instance.visible = true
		return

	var scale_vect = bitmaps_scale

	if current_active_navigation_instance:
		current_active_navigation_instance.visible = false

	var src = Rect2(0, 0, _texture.get_width(), _texture.get_height())
	var dst = Rect2(
		0,
		0,
		_texture.get_width() * scale_vect.x,
		_texture.get_height() * scale_vect.y
	)

	draw_texture_rect_region(_texture, dst, src)
