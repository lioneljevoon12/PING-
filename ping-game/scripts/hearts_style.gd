class_name HeartsStyle
extends RefCounted

# Gaya ikon nyawa (hati) yang SERAGAM untuk semua level:
# panel krem berbingkai cokelat, hati merah, hati hilang menjadi abu-abu dengan tanda "✕".
# Pakai: HeartsStyle.schedule_normalize(hearts_rects) saat hati dibuat,
#        HeartsStyle.refresh(hearts_rects, hearts) saat nyawa berubah.

const HEART_RED := Color(1.0, 0.28, 0.4, 1.0)
const HEART_LOST := Color(0.25, 0.2, 0.22, 0.35)
const FONT_BLACK = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")

# Dipanggil tiap kali hati ditambahkan; baru bekerja saat ketiga hati sudah ada.
static func schedule_normalize(rects: Array) -> void:
	if rects.size() != 3:
		return
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.process_frame.connect(func(): normalize(rects), CONNECT_ONE_SHOT)

static func _find_panel(n: Node) -> PanelContainer:
	var cur = n
	while cur != null:
		if cur is PanelContainer:
			return cur
		cur = cur.get_parent()
	return null

static func normalize(rects: Array) -> void:
	for r in rects:
		if not is_instance_valid(r):
			return
	var first: TextureRect = rects[0]
	var panel = _find_panel(first.get_parent())
	if panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#fffdf7")
		sb.border_color = Color("#4a2e2b")
		sb.set_border_width_all(2.5)
		sb.set_corner_radius_all(14)
		sb.shadow_color = Color(0, 0, 0, 0.15)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 2)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", sb)
	for r in rects:
		var tr: TextureRect = r
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(30, 26)
		tr.size = Vector2(30, 26)
		tr.pivot_offset = Vector2(15, 13)
		tr.modulate = HEART_RED
		var p = tr.get_parent()
		if p is Control and not (p is Container):
			(p as Control).custom_minimum_size = Vector2(32, 28)
	# Jarak antar hati
	var cont: Node = first.get_parent()
	while cont != null and not (cont is HBoxContainer):
		cont = cont.get_parent()
	if cont is HBoxContainer:
		(cont as HBoxContainer).add_theme_constant_override("separation", 10)
		(cont as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		(cont as HBoxContainer).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		(cont as HBoxContainer).size_flags_vertical = Control.SIZE_SHRINK_CENTER

static func _broken_label(hr: TextureRect) -> Label:
	var bl = hr.get_node_or_null("BrokenX") as Label
	if bl:
		return bl
	bl = Label.new()
	bl.name = "BrokenX"
	bl.text = "✕"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bl.add_theme_font_override("font", FONT_BLACK)
	bl.add_theme_font_size_override("font_size", 20)
	bl.add_theme_color_override("font_color", Color("#dc2626"))
	bl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl.visible = false
	hr.add_child(bl)
	return bl

static func refresh(rects: Array, hearts: int, _is_damage: bool = false) -> void:
	if rects.is_empty() or not is_instance_valid(rects[0]):
		return
	var last = int(rects[0].get_meta("last_hearts", rects.size()))
	var damage = hearts < last
	rects[0].set_meta("last_hearts", hearts)
	for i in range(rects.size()):
		var hr: TextureRect = rects[i]
		if not is_instance_valid(hr):
			continue
		var bl = _broken_label(hr)
		if i < hearts:
			hr.modulate = HEART_RED
			hr.scale = Vector2.ONE
			bl.visible = false
		elif damage and i == hearts:
			hr.modulate = Color(1.0, 0.2, 0.2, 1.0)
			var tw = hr.create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_property(hr, "scale", Vector2(1.3, 1.3), 0.1)
			tw.tween_property(hr, "scale", Vector2(0.8, 0.8), 0.15)
			tw.tween_property(hr, "modulate", HEART_LOST, 0.2)
			bl.visible = true
			bl.modulate.a = 0.0
			var tw_b = hr.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw_b.tween_property(bl, "modulate:a", 1.0, 0.15)
		else:
			hr.modulate = HEART_LOST
			hr.scale = Vector2(0.8, 0.8)
			bl.visible = true
			bl.modulate.a = 1.0
	if damage:
		var panel = _find_panel(rects[0].get_parent())
		if panel:
			var tw_p = panel.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw_p.tween_property(panel, "modulate", Color(1.0, 0.5, 0.5, 1.0), 0.08)
			tw_p.tween_property(panel, "modulate", Color.WHITE, 0.25)
