class_name Tile
extends Panel

signal tile_merged(other_tile)

var tile_value: int = 0 : set = set_value
var row: int = 0
var col: int = 0

# Classic 2048 color palette
const VALUE_COLORS := {
	0: Color(0.776, 0.690, 0.600, 1.0),      # empty
	2: Color(0.929, 0.894, 0.855, 1.0),      # light beige
	4: Color(0.929, 0.878, 0.784, 1.0),      # light tan
	8: Color(0.949, 0.694, 0.475, 1.0),      # orange
	16: Color(0.957, 0.584, 0.388, 1.0),     # dark orange
	32: Color(0.957, 0.486, 0.373, 1.0),     # red-orange
	64: Color(0.957, 0.369, 0.231, 1.0),     # red
	128: Color(0.929, 0.812, 0.447, 1.0),    # gold
	256: Color(0.929, 0.800, 0.380, 1.0),    # darker gold
	512: Color(0.929, 0.784, 0.314, 1.0),    # more gold
	1024: Color(0.929, 0.773, 0.247, 1.0),   # bright gold
	2048: Color(0.929, 0.757, 0.180, 1.0),   # super gold
	4096: Color(0.373, 0.314, 0.800, 1.0),   # purple
	8192: Color(0.498, 0.310, 0.800, 1.0),   # violet
}

# Text colors for different value ranges
const LIGHT_TEXT_COLOR := Color(0.976, 0.961, 0.937, 1.0)
const DARK_TEXT_COLOR := Color(0.365, 0.302, 0.259, 1.0)

@onready var label: Label = $Label
@onready var panel_style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat

func _ready():
	if panel_style == null:
		panel_style = StyleBoxFlat.new()
		panel_style.corner_radius_top_left = 6
		panel_style.corner_radius_top_right = 6
		panel_style.corner_radius_bottom_right = 6
		panel_style.corner_radius_bottom_left = 6
		panel_style.corner_detail = 8
		panel_style.shadow_size = 2
		panel_style.shadow_offset = Vector2(0, 1)
		panel_style.shadow_color = Color(0, 0, 0, 0.2)
		panel_style.content_margin_left = 4
		panel_style.content_margin_top = 4
		panel_style.content_margin_right = 4
		panel_style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", panel_style)
	set_value(tile_value)

func set_value(val: int) -> void:
	tile_value = val
	if not is_inside_tree():
		await ready
	_update_display()

func _update_display() -> void:
	if not label:
		return
		
	if tile_value == 0:
		label.text = ""
	else:
		label.text = str(tile_value)
	
	# Update background color
	var bg_color = get_color_for_value(tile_value)
	panel_style.bg_color = bg_color
	add_theme_stylebox_override("panel", panel_style)
	
	# Update text color based on brightness
	if tile_value >= 128:
		label.add_theme_color_override("font_color", LIGHT_TEXT_COLOR)
	else:
		label.add_theme_color_override("font_color", DARK_TEXT_COLOR)

static func get_color_for_value(val: int) -> Color:
	if val in VALUE_COLORS:
		return VALUE_COLORS[val]
	# For values beyond our defined colors, interpolate
	var log_val = int(floor(log(val) / log(2)))
	var hue = fmod(log_val * 0.1, 1.0)
	return Color.from_hsv(hue, 0.6, 0.8)

func animate_appear() -> void:
	scale = Vector2(0, 0)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)

func animate_merge() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
