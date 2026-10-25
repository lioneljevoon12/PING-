path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
\tvar rack_tex = TextureRect.new()
\track_tex.texture = tex_rack
\track_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\track_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\track_tex.size = Vector2(270, 340)
\track_root.add_child(rack_tex)
\t
\tvar badge = PanelContainer.new()
\tbadge.position = Vector2(25, -20)
\tbadge.custom_minimum_size = Vector2(220, 34)
\tvar sb = StyleBoxFlat.new()
\tsb.bg_color = Color(badge_color_hex)
\tsb.border_color = Color("#4a2e2b")
\tsb.set_border_width_all(2)
\tsb.set_corner_radius_all(12)
\tbadge.add_theme_stylebox_override("panel", sb)
\track_root.add_child(badge)
\t
\tvar lbl = Label.new()
\tlbl.text = title_text
\tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\tlbl.add_theme_font_override("font", font_black)
\tlbl.add_theme_font_size_override("font_size", 12)
\tlbl.add_theme_color_override("font_color", Color.WHITE)
\tbadge.add_child(lbl)
\t
\t# Shelf Cables Decoration (row 1 and row 2) matching Figma Level 1.2
\tvar sample_cables = [tex_cable_green, tex_cable_yellow, tex_cable_blue, tex_cable_red]
\tfor row in range(2):
\t\tfor col in range(4):
\t\t\tvar c_img = TextureRect.new()
\t\t\tc_img.texture = sample_cables[(row * 4 + col) % sample_cables.size()]
\t\t\tc_img.position = Vector2(22 + col * 56, 75 + row * 92)
\t\t\tc_img.size = Vector2(52, 52)
\t\t\tc_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\t\tc_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\t\track_root.add_child(c_img)"""

new_code = """func _setup_decorative_rack(rack_root: Control, title_text: String, badge_color_hex: String) -> void:
\track_root.clip_contents = true
\tvar rack_tex = TextureRect.new()
\track_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\track_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\track_tex.custom_minimum_size = Vector2(270, 340)
\track_tex.size = Vector2(270, 340)
\track_tex.texture = tex_rack
\track_root.add_child(rack_tex)
\t
\tvar badge = PanelContainer.new()
\tbadge.position = Vector2(25, -20)
\tbadge.custom_minimum_size = Vector2(220, 34)
\tvar sb = StyleBoxFlat.new()
\tsb.bg_color = Color(badge_color_hex)
\tsb.border_color = Color("#4a2e2b")
\tsb.set_border_width_all(2)
\tsb.set_corner_radius_all(12)
\tbadge.add_theme_stylebox_override("panel", sb)
\track_root.add_child(badge)
\t
\tvar lbl = Label.new()
\tlbl.text = title_text
\tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\tlbl.add_theme_font_override("font", font_black)
\tlbl.add_theme_font_size_override("font_size", 12)
\tlbl.add_theme_color_override("font_color", Color.WHITE)
\tbadge.add_child(lbl)
\t
\t# Shelf Cables Decoration (row 1 and row 2) matching Figma Level 1.2
\tvar sample_cables = [tex_cable_green, tex_cable_yellow, tex_cable_blue, tex_cable_red]
\tfor row in range(2):
\t\tfor col in range(4):
\t\t\tvar c_img = TextureRect.new()
\t\t\tc_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\t\tc_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\t\tc_img.custom_minimum_size = Vector2(50, 50)
\t\t\tc_img.size = Vector2(50, 50)
\t\t\tc_img.position = Vector2(22 + col * 56, 75 + row * 92)
\t\t\tc_img.texture = sample_cables[(row * 4 + col) % sample_cables.size()]
\t\t\track_root.add_child(c_img)"""

if '\r\n' in text:
    old_code = old_code.replace('\n', '\r\n')
    new_code = new_code.replace('\n', '\r\n')

assert old_code in text, 'old_code not found!'
text = text.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated _setup_decorative_rack successfully!')
