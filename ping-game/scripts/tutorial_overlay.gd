class_name TutorialOverlay
extends Control

# Panduan bermain (coach-mark) yang bisa dipakai semua level:
# layar digelapkan, objek yang dimaksud disorot, tangan/panah menunjuk ke objek tersebut,
# dan balon teks menjelaskan langkahnya.
#
# Pemakaian:
#   TutorialOverlay.start(self, [
#       { "title": "Bergerak", "text": "Gunakan joystick atau WASD.", "target": some_control, "pointer": "hand" },
#       { "title": "Selesai", "text": "Selamat bermain!" },           # tanpa target = balon di tengah
#   ], callable_setelah_selesai)
#
# Kunci langkah: title, text, target (Control | Rect2 | Callable -> Control/Rect2),
#                pointer ("hand" | "arrow" | "both" | "none", default "hand"), before (Callable).

signal finished

const FONT_BLACK = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
const FONT_BOLD = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
const FONT_EXTRABOLD = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
const HOLE_PAD := 10.0
const BUBBLE_W := 400.0

var steps: Array = []
var idx: int = 0
var t: float = 0.0
var hole_rect: Rect2 = Rect2()
var has_hole: bool = false
var pointer_kind: String = "hand"
var pointer_side: String = "bottom"
var was_paused: bool = false
var paused_tree: bool = false
var _done: bool = false

var bubble: PanelContainer
var title_lbl: Label
var text_lbl: Label
var step_lbl: Label
var next_btn: Button
var skip_btn: Button
var hand_lbl: Label

static func start(host: Node, tut_steps: Array, on_done: Callable = Callable(), pause_tree: bool = false) -> TutorialOverlay:
	for c in host.get_children():
		if c is TutorialOverlay and not (c as TutorialOverlay)._done:
			return c
	var ov = TutorialOverlay.new()
	ov.steps = tut_steps
	ov.paused_tree = pause_tree
	if on_done.is_valid():
		ov.finished.connect(on_done)
	host.add_child(ov)
	return ov

# Tombol "?" kecil untuk membuka ulang panduan kapan saja
static func make_help_button(parent: Node, pos: Vector2, on_press: Callable) -> Button:
	var b = Button.new()
	b.name = "HelpBtn"
	b.text = "?"
	b.position = pos
	b.size = Vector2(52, 52)
	b.custom_minimum_size = Vector2(52, 52)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fef08a")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(26)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	var sbh = sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color("#fde047")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_font_override("font", FONT_BLACK)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color("#4a2e2b"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Panduan bermain"
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

# ---------------------------------------------------------------------------
# Pembantu umum agar tiap level cukup menulis daftar langkahnya saja
# ---------------------------------------------------------------------------

# Sebuah properti Control milik level (mis. "joystick_base"), atau null bila tidak ada / tidak tampak
static func prop_control(host: Object, prop_name: String) -> Control:
	var v = host.get(prop_name)
	if v is Control and is_instance_valid(v) and (v as Control).is_inside_tree():
		return v
	return null

# Gabungan beberapa Control menjadi satu Rect2 (yang tidak tampak diabaikan)
static func union_of(nodes: Array) -> Rect2:
	var r = Rect2()
	var first = true
	for n in nodes:
		if n is Control and is_instance_valid(n) and (n as Control).is_inside_tree() and (n as Control).is_visible_in_tree():
			var gr = (n as Control).get_global_rect()
			r = gr if first else r.merge(gr)
			first = false
	return r

# Joystick virtual (nama variabelnya berbeda-beda antar level)
static func joystick_target(host: Object) -> Variant:
	for pn in ["joystick_base", "joystick_zone", "dpad_area_node"]:
		var c = prop_control(host, pn)
		if c:
			return c
	var mcr = prop_control(host, "mobile_controls_root")
	if mcr:
		var d = mcr.get_node_or_null("DpadBase")
		if d is Control:
			return d
	return Rect2(45, 545, 130, 130)

static func hearts_target(host: Object) -> Variant:
	var hp = prop_control(host, "hearts_panel")
	if hp:
		return hp
	var hr = host.get("hearts_rects")
	if hr is Array and hr.size() > 0 and is_instance_valid(hr[0]):
		var cur = (hr[0] as Node).get_parent()
		while cur != null:
			if cur is PanelContainer:
				return cur
			cur = cur.get_parent()
		return union_of(hr)
	var hc = prop_control(host, "hearts_container")
	if hc:
		return hc
	return null

static func find_button(root: Node, text_part: String) -> Button:
	if root == null:
		return null
	for ch in root.get_children():
		if ch is Button and (ch as Button).text.findn(text_part) != -1 and (ch as Button).is_visible_in_tree():
			return ch
		var sub = find_button(ch, text_part)
		if sub:
			return sub
	return null

# Langkah baku: cara berjalan
static func step_move(host: Object, extra: String = "") -> Dictionary:
	return {
		"title": "Berjalan",
		"text": "Geser joystick ini dengan mouse/jari, atau pakai tombol W A S D / panah di keyboard untuk menggerakkan karakter." + extra,
		"target": joystick_target(host), "pointer": "hand"
	}

# Langkah baku: nyawa & waktu
static func step_hearts(host: Object) -> Dictionary:
	return {
		"title": "Nyawa & Waktu",
		"text": "Tiga hati ini adalah nyawamu: setiap jawaban salah mengurangi 1 hati. Hati habis atau waktu (di kanan atas) habis = misi gagal. Teliti ya!",
		"target": hearts_target(host), "pointer": "hand"
	}

# Tombol "?" di dekat pewaktu, otomatis menghindari tombol lain di header
static func attach_help_button(header: Control, timer_node: Control, on_press: Callable) -> Button:
	var b = make_help_button(header, Vector2(1100, 24), on_press)
	var tree = header.get_tree()
	var place = func():
		if not is_instance_valid(b) or not is_instance_valid(header):
			return
		var top: Node = timer_node
		while top != null and top.get_parent() != header:
			top = top.get_parent()
		var x = 1100.0
		var y = 24.0
		if top is Control:
			var tr = (top as Control).get_global_rect()
			x = tr.position.x - 62.0
			y = tr.position.y + (tr.size.y - 52.0) / 2.0
		var moved = true
		var guard = 0
		while moved and guard < 6:
			moved = false
			guard += 1
			var me = Rect2(x, y, 52, 52)
			for ch in header.get_children():
				if ch == b or ch == top or not (ch is Control) or not (ch as Control).visible:
					continue
				var cr = (ch as Control).get_global_rect()
				if cr.size.x > 400.0 or cr.size.y > 200.0 or cr.size.x < 8.0:
					continue
				if cr.intersects(me):
					x = cr.position.x - 62.0
					moved = true
					break
		b.global_position = Vector2(x, y)
	tree.process_frame.connect(func(): tree.process_frame.connect(place, CONNECT_ONE_SHOT), CONNECT_ONE_SHOT)
	header.get_viewport().size_changed.connect(func():
		if not tree.process_frame.is_connected(place):
			tree.process_frame.connect(place, CONNECT_ONE_SHOT)
	)
	return b

# Dipakai tombol "?" : jangan buka panduan bila level sedang menampilkan pop up
static func can_open_help(host: Node) -> bool:
	if host.get_tree().paused:
		return false
	if host.get("is_modal_open") == true:
		return false
	for c in host.get_children():
		if c is TutorialOverlay and not (c as TutorialOverlay)._done:
			return false
	return true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 600
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	if paused_tree:
		was_paused = get_tree().paused
		get_tree().paused = true
	_build_bubble()
	if steps.is_empty():
		_finish()
		return
	_show_step(0)

func _build_bubble() -> void:
	bubble = PanelContainer.new()
	bubble.custom_minimum_size = Vector2(BUBBLE_W, 0)
	bubble.size = Vector2(BUBBLE_W, 10)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fffdf7")
	sb.border_color = Color("#4a2e2b")
	sb.set_border_width_all(3.5)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	bubble.add_theme_stylebox_override("panel", sb)
	add_child(bubble)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	bubble.add_child(vb)

	var head = HBoxContainer.new()
	vb.add_child(head)
	title_lbl = Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_override("font", FONT_BLACK)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color("#7c3aed"))
	head.add_child(title_lbl)
	step_lbl = Label.new()
	step_lbl.add_theme_font_override("font", FONT_EXTRABOLD)
	step_lbl.add_theme_font_size_override("font_size", 12)
	step_lbl.add_theme_color_override("font_color", Color("#7c5843"))
	head.add_child(step_lbl)

	text_lbl = Label.new()
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.custom_minimum_size = Vector2(BUBBLE_W - 40.0, 0)
	text_lbl.add_theme_font_override("font", FONT_BOLD)
	text_lbl.add_theme_font_size_override("font_size", 15)
	text_lbl.add_theme_color_override("font_color", Color("#3b2a22"))
	vb.add_child(text_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)
	skip_btn = Button.new()
	skip_btn.text = "Lewati"
	skip_btn.flat = true
	skip_btn.add_theme_font_override("font", FONT_EXTRABOLD)
	skip_btn.add_theme_font_size_override("font_size", 13)
	skip_btn.add_theme_color_override("font_color", Color("#7c5843"))
	skip_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_btn.pressed.connect(_finish)
	btn_row.add_child(skip_btn)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(sp)
	next_btn = Button.new()
	next_btn.custom_minimum_size = Vector2(150, 42)
	var sbn = StyleBoxFlat.new()
	sbn.bg_color = Color("#a7f3d0")
	sbn.border_color = Color("#064e3b")
	sbn.set_border_width_all(3)
	sbn.set_corner_radius_all(16)
	var sbh = sbn.duplicate() as StyleBoxFlat
	sbh.bg_color = Color("#6ee7b7")
	next_btn.add_theme_stylebox_override("normal", sbn)
	next_btn.add_theme_stylebox_override("hover", sbh)
	next_btn.add_theme_stylebox_override("pressed", sbh)
	next_btn.add_theme_font_override("font", FONT_BLACK)
	next_btn.add_theme_font_size_override("font_size", 15)
	next_btn.add_theme_color_override("font_color", Color("#064e3b"))
	next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_btn.pressed.connect(_next)
	btn_row.add_child(next_btn)

	hand_lbl = Label.new()
	hand_lbl.add_theme_font_size_override("font_size", 46)
	hand_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_lbl)

func _resolve_target(tv: Variant) -> Rect2:
	var v = tv
	if v is Callable:
		v = (v as Callable).call()
	var screen = Rect2(Vector2.ZERO, get_viewport_rect().size)
	if v is Control:
		var c = v as Control
		if c.is_inside_tree() and c.is_visible_in_tree():
			return c.get_global_rect().intersection(screen)
		return Rect2()
	if v is Rect2:
		return (v as Rect2).intersection(screen)
	return Rect2()

func _show_step(i: int) -> void:
	idx = i
	var st: Dictionary = steps[i]
	if st.has("before") and st["before"] is Callable:
		(st["before"] as Callable).call()
	title_lbl.text = str(st.get("title", "Panduan"))
	text_lbl.text = str(st.get("text", ""))
	step_lbl.text = "%d / %d" % [i + 1, steps.size()]
	var last = (i == steps.size() - 1)
	next_btn.text = "Mulai! ✓" if last else "Lanjut ▶"
	skip_btn.visible = not last
	pointer_kind = str(st.get("pointer", "hand"))
	_update_geometry()

func _update_geometry() -> void:
	var st: Dictionary = steps[idx]
	var r = _resolve_target(st.get("target", null))
	has_hole = r.size.x > 4.0 and r.size.y > 4.0
	hole_rect = r.grow(HOLE_PAD) if has_hole else Rect2()
	var vp = get_viewport_rect().size
	bubble.reset_size()
	var bs = bubble.get_combined_minimum_size()
	bs.x = max(bs.x, BUBBLE_W)
	bubble.size = bs
	hand_lbl.visible = false
	if not has_hole:
		bubble.position = (vp - bs) / 2.0
		pointer_side = ""
		queue_redraw()
		return
	var top_space = hole_rect.position.y
	var bottom_space = vp.y - hole_rect.end.y
	var bubble_below = bottom_space >= top_space
	var bx = clamp(hole_rect.get_center().x - bs.x / 2.0, 16.0, vp.x - bs.x - 16.0)
	var by = 0.0
	if bubble_below:
		by = hole_rect.end.y + 22.0
		if pointer_kind != "none":
			by += 40.0
		if by + bs.y > vp.y - 10.0:
			by = vp.y - bs.y - 10.0
	else:
		by = hole_rect.position.y - bs.y - 22.0
		if pointer_kind != "none":
			by -= 40.0
		if by < 10.0:
			by = 10.0
	bubble.position = Vector2(bx, by)
	# Penunjuk berada di sisi yang berlawanan dengan balon bila ada tempat, selain itu di samping
	var opposite = "top" if bubble_below else "bottom"
	var same = "bottom" if bubble_below else "top"
	var room_opposite = top_space if bubble_below else bottom_space
	if room_opposite >= 70.0:
		pointer_side = opposite
	elif hole_rect.position.x >= 80.0:
		pointer_side = "left"
	elif vp.x - hole_rect.end.x >= 80.0:
		pointer_side = "right"
	else:
		pointer_side = same
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	if idx < steps.size():
		_update_geometry()
	queue_redraw()
	_place_hand()

func _place_hand() -> void:
	if not has_hole or pointer_kind == "none" or pointer_kind == "arrow":
		hand_lbl.visible = false
		return
	hand_lbl.visible = true
	var bob = sin(t * 6.0) * 8.0
	var c = hole_rect.get_center()
	match pointer_side:
		"top":
			hand_lbl.text = "👇"
			hand_lbl.position = Vector2(c.x - 26.0, hole_rect.position.y - 62.0 + bob)
		"bottom":
			hand_lbl.text = "👆"
			hand_lbl.position = Vector2(c.x - 26.0, hole_rect.end.y + 2.0 - bob)
		"left":
			hand_lbl.text = "👉"
			hand_lbl.position = Vector2(hole_rect.position.x - 62.0 + bob, c.y - 28.0)
		_:
			hand_lbl.text = "👈"
			hand_lbl.position = Vector2(hole_rect.end.x + 4.0 - bob, c.y - 28.0)

func _draw() -> void:
	var vp = get_viewport_rect().size
	var dim = Color(0, 0, 0, 0.64)
	if not has_hole:
		draw_rect(Rect2(Vector2.ZERO, vp), dim)
		return
	var h = hole_rect
	draw_rect(Rect2(0, 0, vp.x, max(0.0, h.position.y)), dim)
	draw_rect(Rect2(0, h.end.y, vp.x, max(0.0, vp.y - h.end.y)), dim)
	draw_rect(Rect2(0, h.position.y, max(0.0, h.position.x), h.size.y), dim)
	draw_rect(Rect2(h.end.x, h.position.y, max(0.0, vp.x - h.end.x), h.size.y), dim)
	# Garis sorot berdenyut
	var pulse = 0.5 + 0.5 * sin(t * 5.0)
	draw_rect(h, Color(1.0, 0.93, 0.35, 0.55 + 0.45 * pulse), false, 4.0 + pulse * 2.0)
	if pointer_kind == "arrow" or pointer_kind == "both":
		_draw_arrow(h)

func _draw_arrow(h: Rect2) -> void:
	var c = h.get_center()
	var bob = sin(t * 6.0) * 7.0
	var dir = Vector2.ZERO
	var tip = Vector2.ZERO
	match pointer_side:
		"top":
			dir = Vector2(0, 1)
			tip = Vector2(c.x, h.position.y - 4.0)
		"bottom":
			dir = Vector2(0, -1)
			tip = Vector2(c.x, h.end.y + 4.0)
		"left":
			dir = Vector2(1, 0)
			tip = Vector2(h.position.x - 4.0, c.y)
		_:
			dir = Vector2(-1, 0)
			tip = Vector2(h.end.x + 4.0, c.y)
	tip -= dir * bob
	var perp = Vector2(-dir.y, dir.x)
	var base = tip - dir * 30.0
	var tail = tip - dir * 78.0
	var col = Color("#fde047")
	var edge = Color("#4a2e2b")
	var shaft = PackedVector2Array([tail + perp * 9.0, base + perp * 9.0, base - perp * 9.0, tail - perp * 9.0])
	var head = PackedVector2Array([tip, base + perp * 24.0, base - perp * 24.0])
	draw_colored_polygon(shaft, col)
	draw_colored_polygon(head, col)
	draw_polyline(PackedVector2Array([tail + perp * 9.0, base + perp * 9.0, base + perp * 24.0, tip, base - perp * 24.0, base - perp * 9.0, tail - perp * 9.0]), edge, 3.0, true)

func _next() -> void:
	if idx >= steps.size() - 1:
		_finish()
	else:
		_show_step(idx + 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_next()

func _finish() -> void:
	if _done:
		return
	_done = true
	if paused_tree:
		get_tree().paused = was_paused
	finished.emit()
	queue_free()
