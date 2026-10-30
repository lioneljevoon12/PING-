with open('ping-game/scenes/dashboard.gd', 'r', encoding='utf-8') as f:
    code = f.read()

# Add @onready var settings_modal
if '@onready var settings_modal' not in code:
    code = code.replace(
        '@onready var guidebook_modal: Control = %GuidebookModal',
        '@onready var guidebook_modal: Control = %GuidebookModal\n@onready var settings_modal: Control = %SettingsModal'
    )

# Add --screenshot-settings
screenshot_code = """	if "--screenshot-settings" in all_args:
		await get_tree().process_frame
		await get_tree().process_frame
		if settings_modal:
			settings_modal.open()
		await get_tree().create_timer(0.4).timeout
		var img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("art/settings_modal_render.png")
		get_tree().quit()
"""

if '--screenshot-settings' not in code:
    code = code.replace(
        '	if "--screenshot" in all_args:',
        screenshot_code + '\n	if "--screenshot" in all_args:'
    )

# Connect settings_btn to open settings_modal
code = code.replace(
    '_setup_button(settings_btn, func(): show_toast("Membuka Pengaturan Sistem..."))',
    '_setup_button(settings_btn, func():\n\t\tif settings_modal:\n\t\t\tsettings_modal.open()\n\t)'
)

with open('ping-game/scenes/dashboard.gd', 'w', encoding='utf-8') as f:
    f.write(code)

print("dashboard.gd updated successfully!")
