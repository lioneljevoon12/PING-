class_name ClassBin
extends PanelContainer

# Komponen reusable untuk keranjang sortir kelas IPv4 (Kelas A, B, atau C).
# Mendukung deteksi drop area (overlap) dan klik/tap langsung.

signal bin_selected(target_class: String)

@export var target_class: String = "A":
	set(val):
		target_class = val.to_upper()
		_update_theme()

var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var tex_router: Texture2D = null

var border_color: Color = Color("#0d9488")
var bg_color: Color = Color("#ffffff")
var pill_bg_color: Color = Color("#99f6e4")
var pill_text_color: Color = Color("#0f766e")
var range_text: String = "Rentang: 1 - 126"

var is_highlighted: bool = false
var is_animating: bool = false

@onready var router_rect: TextureRect = %RouterRect
@onready var class_pill_btn: Button = %ClassPillBtn
@onready var range_panel: PanelContainer = %RangePanel
@onready var range_label: Label = %RangeLabel

func _ready() -> void:
	custom_minimum_size = Vector2(240, 260)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	tex_router = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/router objects 1.png")
	if router_rect and tex_router:
		router_rect.texture = tex_router
		
	if class_pill_btn:
		class_pill_btn.pressed.connect(_on_bin_clicked)
		
	gui_input.connect(_on_gui_input)
	_update_theme()

func _update_theme() -> void:
	match target_class:
		"A":
			border_color = Color("#0d9488")
			pill_bg_color = Color("#a7f3d0")
			pill_text_color = Color("#065f46")
			range_text = "Rentang: 1 - 126"
		"B":
			border_color = Color("#0284c7")
			pill_bg_color = Color("#bae6fd")
			pill_text_color = Color("#075985")
			range_text = "Rentang: 128 - 191"
		"C":
			border_color = Color("#7c3aed")
			pill_bg_color = Color("#ddd6fe")
			pill_text_color = Color("#5b21b6")
			range_text = "Rentang: 192 - 223"
			
	_refresh_style()
	
	if class_pill_btn:
		class_pill_btn.text = "KELAS " + target_class
		class_pill_btn.add_theme_color_override("font_color", pill_text_color)
		var sb_pill = StyleBoxFlat.new()
		sb_pill.bg_color = pill_bg_color
		sb_pill.border_color = border_color
		sb_pill.set_border_width_all(2)
		sb_pill.set_corner_radius_all(12)
		sb_pill.set_content_margin_all(8)
		class_pill_btn.add_theme_stylebox_override("normal", sb_pill)
		class_pill_btn.add_theme_stylebox_override("hover", sb_pill)
		class_pill_btn.add_theme_stylebox_override("pressed", sb_pill)
		
	if range_label:
		range_label.text = range_text
		range_label.add_theme_color_override("font_color", pill_text_color)
		
	if range_panel:
		var sb_range = StyleBoxFlat.new()
		sb_range.bg_color = Color("#ffffff")
		sb_range.border_color = border_color
		sb_range.set_border_width_all(1.5)
		sb_range.set_corner_radius_all(10)
		sb_range.content_margin_left = 12
		sb_range.content_margin_right = 12
		sb_range.content_margin_top = 4
		sb_range.content_margin_bottom = 4
		range_panel.add_theme_stylebox_override("panel", sb_range)

func _refresh_style() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff") if not is_highlighted else pill_bg_color.lightened(0.5)
	sb.border_color = border_color if not is_highlighted else border_color.lightened(0.2)
	sb.set_border_width_all(3.5 if is_highlighted else 2.5)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.25 if is_highlighted else 0.1)
	sb.shadow_size = 10 if is_highlighted else 4
	sb.shadow_offset = Vector2(0, 4)
	sb.set_content_margin_all(14)
	add_theme_stylebox_override("panel", sb)

func contains_point(global_pt: Vector2) -> bool:
	return get_global_rect().has_point(global_pt)

func set_hover_highlight(active: bool) -> void:
	if is_highlighted == active:
		return
	is_highlighted = active
	_refresh_style()
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.04, 1.04) if active else Vector2.ONE, 0.12)

func flash_success() -> void:
	is_animating = true
	var orig_scale = scale
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15)
	tw.tween_property(self, "scale", orig_scale, 0.15)
	await tw.finished
	is_animating = false

func flash_error() -> void:
	is_animating = true
	var orig_pos = position
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(3):
		tw.tween_property(self, "position:x", orig_pos.x - 7.0, 0.04)
		tw.tween_property(self, "position:x", orig_pos.x + 7.0, 0.04)
	tw.tween_property(self, "position:x", orig_pos.x, 0.04)
	await tw.finished
	is_animating = false

func _on_bin_clicked() -> void:
	bin_selected.emit(target_class)

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		_on_bin_clicked()

static func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
