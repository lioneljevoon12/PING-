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
