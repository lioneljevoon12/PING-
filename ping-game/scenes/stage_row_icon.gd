class_name StageRowIcon
extends PanelContainer

# Reusable component for Stage Row Icons
# Guarantees a square frame with fixed minimum size, keep-aspect-centered icon,
# uniform padding, and prevents any clipping.

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		if is_node_ready():
			_update_visuals()

@export var is_locked: bool = false:
	set(val):
		is_locked = val
		if is_node_ready():
			_update_visuals()

var icon_rect: TextureRect

func _ready() -> void:
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	
	if not has_node("IconRect"):
		icon_rect = TextureRect.new()
		icon_rect.name = "IconRect"
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.clip_contents = false
		add_child(icon_rect)
	else:
		icon_rect = get_node("IconRect")
		
	_update_visuals()

func setup(p_texture: Texture2D, p_is_locked: bool) -> void:
	icon_texture = p_texture
	is_locked = p_is_locked
	_update_visuals()

func _update_visuals() -> void:
	if not icon_rect and has_node("IconRect"):
		icon_rect = get_node("IconRect")
		
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.WHITE if not is_locked else Color("#e2e8f0")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 8
	sb.content_margin_top = 8
	sb.content_margin_right = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	
	if icon_rect:
		icon_rect.texture = icon_texture
