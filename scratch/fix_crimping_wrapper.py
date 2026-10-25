path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_c_build = """\tcrimping_card = PanelContainer.new()
\tcrimping_card.name = "CrimpingCard"
\tcrimping_card.custom_minimum_size = Vector2(920, 520)
\tcrimping_card.size = Vector2(920, 520)
\tcrimping_card.pivot_offset = Vector2(460, 260)
\tvar sb_c = StyleBoxFlat.new()
\tsb_c.bg_color = Color("#fffdf7")
\tsb_c.border_color = Color("#4a2e2b")
\tsb_c.set_border_width_all(3.5)
\tsb_c.set_corner_radius_all(20)
\tsb_c.shadow_color = Color(0, 0, 0, 0.35)
\tsb_c.shadow_size = 14
\tsb_c.shadow_offset = Vector2(0, 6)
\tcrimping_card.add_theme_stylebox_override("panel", sb_c)
\tcrimping_modal.add_child(crimping_card)
\t
\tvar vb_all = VBoxContainer.new()
\tvb_all.add_theme_constant_override("separation", 0)
\tcrimping_card.add_child(vb_all)"""

new_c_build = """\tcrimping_card = Control.new()
\tcrimping_card.name = "CrimpingCard"
\tcrimping_card.size = Vector2(920, 520)
\tcrimping_card.pivot_offset = Vector2(460, 260)
\tcrimping_modal.add_child(crimping_card)
\t
\tvar bg_panel = PanelContainer.new()
\tbg_panel.name = "CardBg"
\tbg_panel.size = Vector2(920, 520)
\tvar sb_c = StyleBoxFlat.new()
\tsb_c.bg_color = Color("#fffdf7")
\tsb_c.border_color = Color("#4a2e2b")
\tsb_c.set_border_width_all(3.5)
\tsb_c.set_corner_radius_all(20)
\tsb_c.shadow_color = Color(0, 0, 0, 0.35)
\tsb_c.shadow_size = 14
\tsb_c.shadow_offset = Vector2(0, 6)
\tbg_panel.add_theme_stylebox_override("panel", sb_c)
\tcrimping_card.add_child(bg_panel)
\t
\tvar vb_all = VBoxContainer.new()
\tvb_all.add_theme_constant_override("separation", 0)
\tbg_panel.add_child(vb_all)"""

if '\r\n' in text:
    old_c_build = old_c_build.replace('\n', '\r\n')
    new_c_build = new_c_build.replace('\n', '\r\n')

assert old_c_build in text, 'old_c_build not found'
text = text.replace(old_c_build, new_c_build)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Updated crimping_card wrapper Control!')
