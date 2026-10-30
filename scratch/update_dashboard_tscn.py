with open('ping-game/scenes/dashboard.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

old_ext = '[ext_resource type="PackedScene" path="res://scenes/guidebook.tscn" id="23_guidebook"]'
new_ext = old_ext + '\n[ext_resource type="PackedScene" path="res://scenes/settings_modal.tscn" id="26_settings_modal"]'

text = text.replace(old_ext, new_ext, 1)

old_end = """[node name="GuidebookModal" parent="." instance=ExtResource("23_guidebook")]
unique_name_in_owner = true
visible = false"""

new_end = old_end + """\n
[node name="SettingsModal" parent="." instance=ExtResource("26_settings_modal")]
unique_name_in_owner = true
visible = false"""

text = text.replace(old_end, new_end, 1)

with open('ping-game/scenes/dashboard.tscn', 'w', encoding='utf-8') as f:
    f.write(text)

print("dashboard.tscn updated!")
