path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_ss = """\tif "--screenshot-level1-2-minigame" in all_args:
\t\tawait get_tree().create_timer(0.3).timeout
\t\tintro_modal.visible = false
\t\t_open_crimping_modal()
\t\tawait get_tree().create_timer(0.4).timeout
\t\tvar img = get_viewport().get_texture().get_image()
\t\timg.save_png("art/level1_2_minigame_render.png")
\t\tget_tree().quit()"""

new_ss = """\tif "--screenshot-level1-2-minigame" in all_args:
\t\tawait get_tree().create_timer(0.3).timeout
\t\tintro_modal.visible = false
\t\t_open_crimping_modal()
\t\t_on_tray_wire_clicked(all_wires_def[0])
\t\t_on_tray_wire_clicked(all_wires_def[1])
\t\t_on_tray_wire_clicked(all_wires_def[2])
\t\t_on_tray_wire_clicked(all_wires_def[3])
\t\tawait get_tree().create_timer(0.4).timeout
\t\tvar img = get_viewport().get_texture().get_image()
\t\timg.save_png("art/level1_2_minigame_render.png")
\t\tget_tree().quit()"""

if '\r\n' in text:
    old_ss = old_ss.replace('\n', '\r\n')
    new_ss = new_ss.replace('\n', '\r\n')

assert old_ss in text, 'old_ss not found'
text = text.replace(old_ss, new_ss)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Added wire sim test!')
