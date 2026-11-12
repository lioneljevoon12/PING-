class_name FirewallBin
extends PanelContainer

# Komponen reusable untuk gerbang firewall (ALLOW IP Privat vs BLOCK IP Publik).
# Menampilkan ikon perangkat/perisai, tombol aksi, serta deskripsi rentang IP.
# Mendukung drag-and-drop overlap detection dan klik/tap langsung.

signal gate_selected(rule_type: String)

@export_enum("ALLOW", "BLOCK") var rule: String = "ALLOW":
	set(val):
		rule = val.to_upper()
		if is_node_ready():
			_update_visuals()

var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

var tex_switch: Texture2D = null
var tex_shield: Texture2D = null

var is_highlighted: bool = false
var is_animating: bool = false

@onready var icon_rect: TextureRect = %IconRect
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var action_btn: Button = %ActionBtn
@onready var range_label: Label = %RangeLabel
@onready var desc_label: Label = %DescLabel

func _ready() -> void:
	custom_minimum_size = Vector2(290, 230)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	tex_switch = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/switch-icons.png")
	tex_shield = _safe_load_texture("res://art/assets/PING! Assets/asset-gameplay/stage2/guardian-icon.png")
	
	if action_btn:
		action_btn.pressed.connect(_on_clicked)
		
	gui_input.connect(_on_gui_input)
	_update_visuals()

func _update_visuals() -> void:
	var is_allow = (rule == "ALLOW")
	
	# Palet Warna: Mint Green untuk ALLOW, Soft Coral Red untuk BLOCK
	var base_border = Color("#10b981") if is_allow else Color("#ef4444")
	var base_bg = Color("#f0fdf4") if is_allow else Color("#fef2f2")
	var btn_bg = Color("#a7f3d0") if is_allow else Color("#fecdd3")
	var btn_border = Color("#059669") if is_allow else Color("#dc2626")
	var text_color = Color("#065f46") if is_allow else Color("#991b1b")
	
	# 1. Outer Container Style (Dashed/Thick border)
	var sb_outer = StyleBoxFlat.new()
	sb_outer.bg_color = base_bg if not is_highlighted else base_bg.lightened(0.3)
	sb_outer.border_color = base_border if not is_highlighted else base_border.lightened(0.2)
	sb_outer.set_border_width_all(3.5 if is_highlighted else 2.5)
	sb_outer.set_corner_radius_all(18)
	sb_outer.shadow_color = Color(base_border.r, base_border.g, base_border.b, 0.22 if is_highlighted else 0.08)
	sb_outer.shadow_size = 12 if is_highlighted else 5
	sb_outer.shadow_offset = Vector2(0, 3)
	sb_outer.set_content_margin_all(14)
	add_theme_stylebox_override("panel", sb_outer)
	
	# 2. Icon Texture
	if icon_rect:
		icon_rect.texture = tex_switch if is_allow else tex_shield
		
	# 3. Badge Icon (✓ / ✕)
	if badge_label:
		badge_label.text = "✓" if is_allow else "✕"
		badge_label.add_theme_color_override("font_color", Color.WHITE)
		badge_label.add_theme_font_override("font", font_black)
		badge_label.add_theme_font_size_override("font_size", 16)
		
	if badge_panel:
		var sb_badge = StyleBoxFlat.new()
		sb_badge.bg_color = base_border
		sb_badge.set_corner_radius_all(14)
		badge_panel.add_theme_stylebox_override("panel", sb_badge)
		
	# 4. Action Button
	if action_btn:
		action_btn.text = "✓ IZINKAN MASUK (ALLOW IP PRIVAT)" if is_allow else "✕ BLOKIR KONEKSI (DENY IP PUBLIK)"
		action_btn.add_theme_font_override("font", font_black)
		action_btn.add_theme_font_size_override("font_size", 13)
		action_btn.add_theme_color_override("font_color", text_color)
		
		var sb_btn = StyleBoxFlat.new()
		sb_btn.bg_color = btn_bg
		sb_btn.border_color = btn_border
		sb_btn.set_border_width_all(2)
		sb_btn.set_corner_radius_all(12)
		sb_btn.set_content_margin_all(8)
		
		var sb_btn_h = sb_btn.duplicate()
		sb_btn_h.bg_color = btn_bg.lightened(0.2)
		
		var sb_btn_p = sb_btn.duplicate()
		sb_btn_p.bg_color = btn_bg.darkened(0.1)
		
		action_btn.add_theme_stylebox_override("normal", sb_btn)
		action_btn.add_theme_stylebox_override("hover", sb_btn_h)
		action_btn.add_theme_stylebox_override("pressed", sb_btn_p)
		
	# 5. Range and Description
	if range_label:
		range_label.text = "10.0.0.0/8 • 172.16.0.0/12 • 192.168.0.0/16" if is_allow else "Seluruh IP Publik Eksternal (Di Luar IP Privat)"
		range_label.add_theme_font_override("font", font_bold)
		range_label.add_theme_font_size_override("font_size", 11)
		range_label.add_theme_color_override("font_color", text_color)
		
	if desc_label:
		desc_label.text = "Arahkan paket jaringan lokal (LAN) yang sah ke sini" if is_allow else "Tahan dan buang trafik asing dari luar perusahaan ke sini"
		desc_label.add_theme_font_override("font", font_semibold)
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", text_color.lightened(0.25))

func set_highlight(active: bool) -> void:
	if is_highlighted == active:
		return
	is_highlighted = active
	_update_visuals()
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_highlighted:
		tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)
	else:
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)

func contains_global_point(pt: Vector2) -> bool:
	return get_global_rect().has_point(pt)

func animate_success() -> void:
	if is_animating:
		return
	is_animating = true
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	await tw.finished
	is_animating = false

func animate_error() -> void:
	if is_animating:
		return
	is_animating = true
	var orig_pos = position
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(3):
		tw.tween_property(self, "position:x", orig_pos.x - 6.0, 0.04)
		tw.tween_property(self, "position:x", orig_pos.x + 6.0, 0.04)
	tw.tween_property(self, "position:x", orig_pos.x, 0.04)
	await tw.finished
	position = orig_pos
	is_animating = false

func _on_clicked() -> void:
	gate_selected.emit(rule)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_clicked()
	elif event is InputEventScreenTouch and event.pressed:
		_on_clicked()

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
