path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_pause = """\tpause_card = PanelContainer.new()
\tpause_card.name = "PauseCard"
\tpause_card.size = Vector2(460, 320)
\tpause_card.pivot_offset = Vector2(230, 160)
\tvar sb_p = StyleBoxFlat.new()
\tsb_p.bg_color = Color("#fffdf7")
\tsb_p.border_color = Color("#4a2e2b")
\tsb_p.set_border_width_all(3.5)
\tsb_p.set_corner_radius_all(20)
\tsb_p.set_content_margin_all(24)
\tsb_p.shadow_color = Color(0, 0, 0, 0.3)
\tsb_p.shadow_size = 14
\tsb_p.shadow_offset = Vector2(0, 4)
\tpause_card.add_theme_stylebox_override("panel", sb_p)
\tpause_modal.add_child(pause_card)
\t
\tvar vb_p = VBoxContainer.new()
\tvb_p.add_theme_constant_override("separation", 12)
\tpause_card.add_child(vb_p)"""

new_pause = """\tpause_card = Control.new()
\tpause_card.name = "PauseCard"
\tpause_card.size = Vector2(460, 320)
\tpause_card.pivot_offset = Vector2(230, 160)
\tpause_modal.add_child(pause_card)
\t
\tvar bg_p = PanelContainer.new()
\tbg_p.size = Vector2(460, 320)
\tvar sb_p = StyleBoxFlat.new()
\tsb_p.bg_color = Color("#fffdf7")
\tsb_p.border_color = Color("#4a2e2b")
\tsb_p.set_border_width_all(3.5)
\tsb_p.set_corner_radius_all(20)
\tsb_p.set_content_margin_all(24)
\tsb_p.shadow_color = Color(0, 0, 0, 0.3)
\tsb_p.shadow_size = 14
\tsb_p.shadow_offset = Vector2(0, 4)
\tbg_p.add_theme_stylebox_override("panel", sb_p)
\tpause_card.add_child(bg_p)
\t
\tvar vb_p = VBoxContainer.new()
\tvb_p.add_theme_constant_override("separation", 12)
\tbg_p.add_child(vb_p)"""

if '\r\n' in text:
    old_pause = old_pause.replace('\n', '\r\n')
    new_pause = new_pause.replace('\n', '\r\n')

assert old_pause in text, 'old_pause not found!'
text = text.replace(old_pause, new_pause)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated pause_card wrapper!')
