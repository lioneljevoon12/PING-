class_name UiKit
extends RefCounted

# Komponen UI bersama agar tampilan SERAGAM di semua layar & level.

const FONT_BLACK = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
const BACK_SIZE := 64.0

# Tombol kembali "<": lingkaran pink berbingkai cokelat, ukuran sama di mana pun.
static func style_back_button(btn: Button) -> void:
	if btn == null:
		return
	btn.text = "<"
	btn.flat = false
	btn.icon = null
	btn.custom_minimum_size = Vector2(BACK_SIZE, BACK_SIZE)
	btn.size = Vector2(BACK_SIZE, BACK_SIZE)
	btn.pivot_offset = Vector2(BACK_SIZE / 2.0, BACK_SIZE / 2.0)
	btn.clip_text = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fed0cf")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(32)
	sb.shadow_color = Color(0.29, 0.18, 0.17, 0.22)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	var sbh = sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color("#fcc0be")
	var sbp = sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color("#f9aeac")
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbp)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_font_override("font", FONT_BLACK)
	btn.add_theme_font_size_override("font_size", 28)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(c, Color("#4a2e2b"))
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# ---------------------------------------------------------------------------
# Header level (atas layar) dengan ukuran & posisi SERAGAM di semua level
# ---------------------------------------------------------------------------
const HDR_Y := 20.0
const HDR_H := 64.0
const HDR_HEARTS_W := 150.0
const HDR_BADGE_W := 84.0
const HDR_TIMER_W := 170.0
const HDR_GAP := 12.0

static func _subtree_texts(n: Node) -> Array:
	var out = []
	var st = [n]
	while st.size() > 0:
		var x = st.pop_back()
		for c in x.get_children():
			st.append(c)
		if x is Label:
			out.append((x as Label).text)
		elif x is Button:
			out.append((x as Button).text)
	return out

static func _nearest_panel(n: Node, stop: Node) -> PanelContainer:
	var cur = n
	while cur != null and cur != stop:
		if cur is PanelContainer:
			return cur
		cur = cur.get_parent()
	return null

# Ambil elemen dari kontainer (HBox, dll.) lalu jadikan anak langsung header agar bisa diposisikan mutlak
static func _lift(n: Control, header: Control) -> void:
	if n == null or n.get_parent() == header:
		return
	n.get_parent().remove_child(n)
	header.add_child(n)

static func _fix(c: Control, pos: Vector2, sz: Vector2) -> void:
	if c == null:
		return
	c.custom_minimum_size = sz
	c.size = sz
	c.position = pos

static func _hdr_box(bg: Color = Color("#fffdf7")) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.15)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func _style_hdr_panel(p: Control) -> void:
	if p is PanelContainer:
		p.add_theme_stylebox_override("panel", _hdr_box())

static func _style_hdr_button(b: Control) -> void:
	if b is Button:
		var sb = _hdr_box()
		var sbh = _hdr_box(Color("#fff3e0"))
		for st in ["normal", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_stylebox_override("hover", sbh)
		b.add_theme_stylebox_override("pressed", sbh)
		b.add_theme_font_override("font", FONT_BLACK)
		b.add_theme_font_size_override("font_size", 28)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, Color("#4a2e2b"))
	elif b is TextureButton:
		for ch in b.get_children():
			if ch is PanelContainer:
				_style_hdr_panel(ch)
			elif ch is Label:
				(ch as Label).add_theme_font_size_override("font_size", 28)

# Ukuran huruf & ikon di dalam panel header
static func _unify_header_text(level: Node, timer: Control, badge: Control) -> void:
	var tl = level.get("timer_label") as Label
	if tl and is_instance_valid(tl):
		tl.add_theme_font_override("font", FONT_BLACK)
		tl.add_theme_font_size_override("font_size", 22)
		var par = tl.get_parent()
		if par:
			for sib in par.get_children():
				if sib == tl:
					continue
				if sib is TextureRect:
					(sib as TextureRect).custom_minimum_size = Vector2(28, 28)
					(sib as TextureRect).size = Vector2(28, 28)
					(sib as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					(sib as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				elif sib is Label:
					(sib as Label).add_theme_font_size_override("font_size", 22)
	if badge:
		var labels = []
		var st = [badge]
		while st.size() > 0:
			var x = st.pop_back()
			for c in x.get_children():
				st.append(c)
			if x is Label:
				labels.append(x)
		for l in labels:
			var lab = l as Label
			lab.add_theme_font_override("font", FONT_BLACK)
			lab.add_theme_font_size_override("font_size", 11 if lab.text == "Level" else 22)

static func normalize_header(level: Node) -> void:
	if level == null or not is_instance_valid(level):
		return
	var header = level.get("header_ui") as Control
	if header == null or not is_instance_valid(header) or not header.is_inside_tree():
		return
	var vp_w = header.get_viewport_rect().size.x

	var back: Control = null
	var pause: Control = null
	var badge: Control = null
	var guide = header.get_node_or_null("GuidebookTopBtn") as Control
	var hearts: Control = null
	var timer: Control = null
	var help = level.get("help_btn") as Control

	var hr = level.get("hearts_rects")
	if hr is Array and hr.size() > 0 and is_instance_valid(hr[0]):
		hearts = _nearest_panel(hr[0].get_parent(), header)
	var tl = level.get("timer_label") as Control
	if tl and is_instance_valid(tl):
		timer = _nearest_panel(tl, header)
		# isi panel pewaktu rata tengah
		var par = tl.get_parent()
		while par != null and par != timer:
			if par is BoxContainer:
				(par as BoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
			par = par.get_parent()

	var st = [header]
	while st.size() > 0:
		var x = st.pop_back()
		for c in x.get_children():
			st.append(c)
		if x == hearts or x == timer or x == help or x == guide:
			continue
		if x is BaseButton and x is Control:
			var txts = _subtree_texts(x)
			if back == null and txts.has("<"):
				back = x
			elif pause == null and (txts.has("≡") or txts.has("☰")):
				pause = x
		elif x is PanelContainer and badge == null:
			if _subtree_texts(x).has("Level") and _nearest_panel(x.get_parent(), header) == null:
				badge = x

	for c in [back, hearts, badge, timer, pause, help, guide]:
		if c != null:
			_lift(c, header)

	var y = HDR_Y
	_fix(back, Vector2(30, y), Vector2(BACK_SIZE, BACK_SIZE))
	_fix(hearts, Vector2(106, y), Vector2(HDR_HEARTS_W, HDR_H))
	_fix(badge, Vector2(106 + HDR_HEARTS_W + HDR_GAP, y), Vector2(HDR_BADGE_W, HDR_H))
	_fix(pause, Vector2(vp_w - 30 - HDR_H, y), Vector2(HDR_H, HDR_H))
	var timer_x = vp_w - 30 - HDR_H - HDR_GAP - HDR_TIMER_W
	_fix(timer, Vector2(timer_x, y), Vector2(HDR_TIMER_W, HDR_H))
	var help_x = timer_x - HDR_GAP - HDR_H
	_fix(help, Vector2(help_x, y), Vector2(HDR_H, HDR_H))
	_fix(guide, Vector2(help_x - HDR_GAP - 170.0, y), Vector2(170, HDR_H))
	_style_hdr_panel(timer)
	_style_hdr_panel(badge)
	_style_hdr_button(pause)
	_unify_header_text(level, timer, badge)
	# Ikon jeda seragam
	if pause is Button:
		(pause as Button).text = "☰"
	# anak TextureButton jeda (panel/label di dalamnya) ikut ukuran tombol
	if pause is TextureButton:
		for ch in pause.get_children():
			if ch is Control:
				(ch as Control).size = Vector2(HDR_H, HDR_H)
