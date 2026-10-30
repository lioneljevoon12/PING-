path = r'C:/Projects/PING-/ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target = 'get_viewport().size_changed.connect(_reposition_responsive)'
replacement = '''get_viewport().size_changed.connect(_reposition_responsive)
	
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-gameplay" in all_args:
		await get_tree().create_timer(0.2).timeout
		_start_gameplay()
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/level1_2_gameplay_render.png")
		get_tree().quit()'''

if '\r\n' in text:
    replacement = replacement.replace('\n', '\r\n')

assert target in text, "target not found"
text = text.replace(target, replacement, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Added screenshot hook to level_1_2.gd')
