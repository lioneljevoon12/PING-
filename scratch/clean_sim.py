path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

test_sim = """\tif "--screenshot-level1-2-minigame" in all_args:
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

clean_ss = """\tif "--screenshot-level1-2-minigame" in all_args:
\t\tawait get_tree().create_timer(0.3).timeout
\t\tintro_modal.visible = false
\t\t_open_crimping_modal()
\t\tawait get_tree().create_timer(0.4).timeout
\t\tvar img = get_viewport().get_texture().get_image()
\t\timg.save_png("art/level1_2_minigame_render.png")
\t\tget_tree().quit()"""

if '\r\n' in text:
    test_sim = test_sim.replace('\n', '\r\n')
    clean_ss = clean_ss.replace('\n', '\r\n')

assert test_sim in text, 'test_sim not found'
text = text.replace(test_sim, clean_ss)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Cleaned up screenshot test!')
