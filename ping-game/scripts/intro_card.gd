class_name IntroCard
extends RefCounted

# Pop up pembuka level yang SERAGAM di semua level (mengikuti desain Level 3.2):
# kartu kuning krem berbingkai cokelat, pin di atas, judul + garis pemisah, teks tugas,
# tombol MULAI hijau mint, dan avatar teknisi di pojok kiri bawah.
#
# Pemakaian (di dalam level):
#   intro_modal = IntroCard.build(self, "Level 1.1 ...", "Deskripsi tugas ...", _start_gameplay)
# Overlay yang dikembalikan adalah ColorRect (latar gelap); kartunya adalah ANAK TERAKHIR overlay.

const FONT_BLACK = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
const FONT_EXTRABOLD = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
const FONT_BOLD = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")

const C_CARD := Color("#fef3b8")
const C_BORDER := Color("#5a3e38")
const C_DIVIDER := Color("#d6cb7e")
const C_TEXT := Color("#5a3e38")
const C_BTN := Color("#bdebd5")
const CARD_SIZE := Vector2(760, 470)

static func build(host: Node, title: String, body: String, on_start: Callable, z: int = 200, visible_now: bool = true) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.name = "IntroModal"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.z_index = z
	overlay.visible = visible_now
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(overlay)

	var card = Control.new()
	card.name = "IntroCardBox"
	card.size = CARD_SIZE
	card.pivot_offset = CARD_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card)
	_center(card, host)
	host.get_viewport().size_changed.connect(func():
		if is_instance_valid(card) and card.is_inside_tree():
			_center(card, host)
	)

	# Panel kartu
	var panel = Panel.new()
	panel.size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = C_CARD
	sb.border_color = C_BORDER
	sb.set_border_width_all(7)
	sb.set_corner_radius_all(40)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(5, 7)
	sb.shadow_size = 1
	panel.add_theme_stylebox_override("panel", sb)
	card.add_child(panel)

	# Pin di atas kartu
	var pin = Panel.new()
	pin.size = Vector2(30, 30)
	pin.position = Vector2(CARD_SIZE.x / 2.0 - 15.0, 22)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_pin = StyleBoxFlat.new()
	sb_pin.bg_color = Color("#e4e2f4")
	sb_pin.border_color = C_BORDER
	sb_pin.set_border_width_all(4)
	sb_pin.set_corner_radius_all(15)
	pin.add_theme_stylebox_override("panel", sb_pin)
	card.add_child(pin)

	# Judul
	var t = Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.clip_text = false
	t.add_theme_font_override("font", FONT_BLACK)
	t.add_theme_font_size_override("font_size", 26 if title.length() <= 44 else 22)
	t.add_theme_color_override("font_color", C_TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.position = Vector2(70, 66)
	t.size = Vector2(CARD_SIZE.x - 140.0, 70)
	card.add_child(t)

	# Garis pemisah
	var line = Panel.new()
	line.size = Vector2(CARD_SIZE.x - 220.0, 7)
	line.position = Vector2(110, 142)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = C_DIVIDER
	sb_l.set_corner_radius_all(4)
	line.add_theme_stylebox_override("panel", sb_l)
	card.add_child(line)

	# Teks tugas
	var d = Label.new()
	d.text = body
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_override("font", FONT_BOLD)
	var fs = 20
	if body.length() > 230:
		fs = 18
	if body.length() > 330:
		fs = 16
	d.add_theme_font_size_override("font_size", fs)
	d.add_theme_constant_override("line_spacing", 7)
	d.add_theme_color_override("font_color", C_TEXT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.position = Vector2(80, 166)
	d.size = Vector2(CARD_SIZE.x - 160.0, 178)
	card.add_child(d)

	# Tombol MULAI
	var btn = Button.new()
	btn.text = "MULAI"
	btn.size = Vector2(230, 64)
	btn.position = Vector2((CARD_SIZE.x - 230.0) / 2.0, CARD_SIZE.y - 108.0)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = C_BTN
	sb_b.border_color = C_BORDER
	sb_b.set_border_width_all(5)
	sb_b.set_corner_radius_all(32)
	sb_b.shadow_color = Color(0, 0, 0, 0.18)
	sb_b.shadow_size = 1
	sb_b.shadow_offset = Vector2(0, 5)
	var sb_bh = sb_b.duplicate() as StyleBoxFlat
	sb_bh.bg_color = Color("#a6e3c8")
	btn.add_theme_stylebox_override("normal", sb_b)
	btn.add_theme_stylebox_override("hover", sb_bh)
	btn.add_theme_stylebox_override("pressed", sb_bh)
	btn.add_theme_stylebox_override("focus", sb_b)
	btn.add_theme_font_override("font", FONT_BLACK)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", C_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if on_start.is_valid():
		btn.pressed.connect(on_start)
	card.add_child(btn)

	# Avatar teknisi (pojok kiri bawah, sedikit keluar dari kartu)
	var av = Control.new()
	av.size = Vector2(128, 128)
	av.position = Vector2(-44, CARD_SIZE.y - 96.0)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.draw.connect(func(): _draw_avatar(av))
	card.add_child(av)
	av.queue_redraw()
	return overlay

static func _center(card: Control, host: Node) -> void:
	var vp = host.get_viewport().get_visible_rect().size
	card.position = (vp - CARD_SIZE) / 2.0

# Kartu intro = anak terakhir dari overlay
static func card_of(overlay: Control) -> Control:
	return overlay.get_child(overlay.get_child_count() - 1) as Control

static func _draw_avatar(av: Control) -> void:
	var c = Vector2(64, 64)
	av.draw_circle(c, 58, Color("#e4f3e8"))
	# badan: setengah elips (bahu) + busur bawah lingkaran
	var pts = PackedVector2Array()
	for i in range(0, 13):
		var a = PI + PI * float(i) / 12.0
		pts.append(Vector2(64.0 + cos(a) * 38.0, 98.0 + sin(a) * 20.0))
	var a_right = atan2(98.0 - 64.0, 102.0 - 64.0)
	var a_left = atan2(98.0 - 64.0, 26.0 - 64.0)
	for i in range(0, 17):
		var ang = a_right + (a_left - a_right) * float(i) / 16.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * 57.0)
	av.draw_colored_polygon(pts, Color("#fdc99b"))
	# kepala
	av.draw_circle(Vector2(64, 66), 26, Color("#fdfcf8"))
	av.draw_arc(Vector2(64, 66), 26, 0, TAU, 40, C_BORDER, 5.0, true)
	# topi proyek
	av.draw_rect(Rect2(32, 42, 64, 14), Color("#fff0a8"))
	av.draw_rect(Rect2(32, 42, 64, 14), C_BORDER, false, 4.0)
	# lingkaran luar
	av.draw_arc(c, 58, 0, TAU, 64, C_BORDER, 6.0, true)
