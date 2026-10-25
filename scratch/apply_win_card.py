path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_win = """\twin_card = PanelContainer.new()
\twin_card.name = "WinCard"
\twin_card.custom_minimum_size = Vector2(560, 360)
\twin_card.size = Vector2(560, 360)
\twin_card.pivot_offset = Vector2(280, 180)
\tvar sb_win = StyleBoxFlat.new()
\tsb_win.bg_color = Color("#f0fdf4")
\tsb_win.border_color = Color("#16a34a")
\tsb_win.set_border_width_all(4)
\tsb_win.set_corner_radius_all(20)
\tsb_win.set_content_margin_all(24)
\twin_card.add_theme_stylebox_override("panel", sb_win)
\twin_modal.add_child(win_card)
\t
\tvar vb_w = VBoxContainer.new()
\tvb_w.alignment = BoxContainer.ALIGNMENT_CENTER
\tvb_w.add_theme_constant_override("separation", 14)
\twin_card.add_child(vb_w)"""

new_win = """\twin_card = Control.new()
\twin_card.name = "WinCard"
\twin_card.size = Vector2(560, 340)
\twin_card.pivot_offset = Vector2(280, 170)
\twin_modal.add_child(win_card)
\t
\tvar bg_win = PanelContainer.new()
\tbg_win.size = Vector2(560, 340)
\tvar sb_win = StyleBoxFlat.new()
\tsb_win.bg_color = Color("#f0fdf4")
\tsb_win.border_color = Color("#16a34a")
\tsb_win.set_border_width_all(4)
\tsb_win.set_corner_radius_all(20)
\tsb_win.set_content_margin_all(24)
\tsb_win.shadow_color = Color(0, 0, 0, 0.3)
\tsb_win.shadow_size = 14
\tsb_win.shadow_offset = Vector2(0, 6)
\tbg_win.add_theme_stylebox_override("panel", sb_win)
\twin_card.add_child(bg_win)
\t
\tvar vb_w = VBoxContainer.new()
\tvb_w.alignment = BoxContainer.ALIGNMENT_CENTER
\tvb_w.add_theme_constant_override("separation", 14)
\tbg_win.add_child(vb_w)"""

old_go = """\tgameover_card = PanelContainer.new()
\tgameover_card.name = "GameOverCard"
\tgameover_card.custom_minimum_size = Vector2(520, 320)
\tgameover_card.size = Vector2(520, 320)
\tgameover_card.pivot_offset = Vector2(260, 160)
\tvar sb_go = StyleBoxFlat.new()
\tsb_go.bg_color = Color("#fef2f2")
\tsb_go.border_color = Color("#dc2626")
\tsb_go.set_border_width_all(4)
\tsb_go.set_corner_radius_all(20)
\tsb_go.set_content_margin_all(24)
\tgameover_card.add_theme_stylebox_override("panel", sb_go)
\tgameover_modal.add_child(gameover_card)
\t
\tvar vb_go = VBoxContainer.new()
\tvb_go.alignment = BoxContainer.ALIGNMENT_CENTER
\tvb_go.add_theme_constant_override("separation", 14)
\tgameover_card.add_child(vb_go)"""

new_go = """\tgameover_card = Control.new()
\tgameover_card.name = "GameOverCard"
\tgameover_card.size = Vector2(520, 320)
\tgameover_card.pivot_offset = Vector2(260, 160)
\tgameover_modal.add_child(gameover_card)
\t
\tvar bg_go = PanelContainer.new()
\tbg_go.size = Vector2(520, 320)
\tvar sb_go = StyleBoxFlat.new()
\tsb_go.bg_color = Color("#fef2f2")
\tsb_go.border_color = Color("#dc2626")
\tsb_go.set_border_width_all(4)
\tsb_go.set_corner_radius_all(20)
\tsb_go.set_content_margin_all(24)
\tsb_go.shadow_color = Color(0, 0, 0, 0.3)
\tsb_go.shadow_size = 14
\tsb_go.shadow_offset = Vector2(0, 6)
\tbg_go.add_theme_stylebox_override("panel", sb_go)
\tgameover_card.add_child(bg_go)
\t
\tvar vb_go = VBoxContainer.new()
\tvb_go.alignment = BoxContainer.ALIGNMENT_CENTER
\tvb_go.add_theme_constant_override("separation", 14)
\tbg_go.add_child(vb_go)"""

# Handle CRLF
if '\r\n' in text:
    old_win = old_win.replace('\n', '\r\n')
    new_win = new_win.replace('\n', '\r\n')
    old_go = old_go.replace('\n', '\r\n')
    new_go = new_go.replace('\n', '\r\n')

assert old_win in text, "old_win not found!"
assert old_go in text, "old_go not found!"

text = text.replace(old_win, new_win)
text = text.replace(old_go, new_go)
text = text.replace('btn_retry.text = "\\U0001f504 COBA LAGI"', 'btn_retry.text = "COBA LAGI"')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Updated win and gameover cards in level_1_2.gd!")
