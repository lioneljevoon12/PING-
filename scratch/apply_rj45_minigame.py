import re

path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add texture preloads if not already there
preload_anchor = 'var tex_diagram_straight = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight_opt.png")'
new_preloads = '''var tex_diagram_straight = preload("res://art/assets/PING! Assets/asset-gameplay/stage1/1.1/straight_opt.png")
var tex_rj45_housing = preload("res://art/rj45_housing_empty.png")
var tex_wire_po = preload("res://art/rj45_wires/wire_po.png")
var tex_wire_o = preload("res://art/rj45_wires/wire_o.png")
var tex_wire_ph = preload("res://art/rj45_wires/wire_ph.png")
var tex_wire_b = preload("res://art/rj45_wires/wire_b.png")
var tex_wire_pb = preload("res://art/rj45_wires/wire_pb.png")
var tex_wire_h = preload("res://art/rj45_wires/wire_h.png")
var tex_wire_pc = preload("res://art/rj45_wires/wire_pc.png")
var tex_wire_c = preload("res://art/rj45_wires/wire_c.png")'''

if '\r\n' in code:
    preload_anchor = preload_anchor.replace('\n', '\r\n')
    new_preloads = new_preloads.replace('\n', '\r\n')

if preload_anchor in code and 'tex_rj45_housing' not in code:
    code = code.replace(preload_anchor, new_preloads)

# 2. Update all_wires_def to include texture references
old_def = '''var all_wires_def: Array[Dictionary] = [
\t{ "id": "white_orange", "name": "P-Oranye", "full_name": "Putih-Oranye", "base": Color("#ffffff"), "stripe": Color("#ea580c"), "is_striped": true },
\t{ "id": "orange",       "name": "Oranye",   "full_name": "Oranye",       "base": Color("#ea580c"), "stripe": Color("#ea580c"), "is_striped": false },
\t{ "id": "white_green",  "name": "P-Hijau",  "full_name": "Putih-Hijau",  "base": Color("#ffffff"), "stripe": Color("#16a34a"), "is_striped": true },
\t{ "id": "blue",         "name": "Biru",     "full_name": "Biru",         "base": Color("#0284c7"), "stripe": Color("#0284c7"), "is_striped": false },
\t{ "id": "white_blue",   "name": "P-Biru",   "full_name": "Putih-Biru",   "base": Color("#ffffff"), "stripe": Color("#0284c7"), "is_striped": true },
\t{ "id": "green",        "name": "Hijau",    "full_name": "Hijau",        "base": Color("#16a34a"), "stripe": Color("#16a34a"), "is_striped": false },
\t{ "id": "white_brown",  "name": "P-Cokelat","full_name": "Putih-Cokelat","base": Color("#ffffff"), "stripe": Color("#78350f"), "is_striped": true },
\t{ "id": "brown",        "name": "Cokelat",  "full_name": "Cokelat",      "base": Color("#78350f"), "stripe": Color("#78350f"), "is_striped": false }
]'''

new_def = '''var all_wires_def: Array[Dictionary] = [
\t{ "id": "white_orange", "name": "P-Oranye", "full_name": "Putih-Oranye", "base": Color("#ffffff"), "stripe": Color("#ea580c"), "is_striped": true, "tex": tex_wire_po },
\t{ "id": "orange",       "name": "Oranye",   "full_name": "Oranye",       "base": Color("#ea580c"), "stripe": Color("#ea580c"), "is_striped": false, "tex": tex_wire_o },
\t{ "id": "white_green",  "name": "P-Hijau",  "full_name": "Putih-Hijau",  "base": Color("#ffffff"), "stripe": Color("#16a34a"), "is_striped": true, "tex": tex_wire_ph },
\t{ "id": "blue",         "name": "Biru",     "full_name": "Biru",         "base": Color("#0284c7"), "stripe": Color("#0284c7"), "is_striped": false, "tex": tex_wire_b },
\t{ "id": "white_blue",   "name": "P-Biru",   "full_name": "Putih-Biru",   "base": Color("#ffffff"), "stripe": Color("#0284c7"), "is_striped": true, "tex": tex_wire_pb },
\t{ "id": "green",        "name": "Hijau",    "full_name": "Hijau",        "base": Color("#16a34a"), "stripe": Color("#16a34a"), "is_striped": false, "tex": tex_wire_h },
\t{ "id": "white_brown",  "name": "P-Cokelat","full_name": "Putih-Cokelat","base": Color("#ffffff"), "stripe": Color("#78350f"), "is_striped": true, "tex": tex_wire_pc },
\t{ "id": "brown",        "name": "Cokelat",  "full_name": "Cokelat",      "base": Color("#78350f"), "stripe": Color("#78350f"), "is_striped": false, "tex": tex_wire_c }
]'''

if '\r\n' in code:
    old_def = old_def.replace('\n', '\r\n')
    new_def = new_def.replace('\n', '\r\n')

if old_def in code:
    code = code.replace(old_def, new_def)

# 3. Add variables for RJ45 widget
vars_anchor = 'var slot_containers: Array[PanelContainer] = []\r\nvar tray_container: HBoxContainer = null' if '\r\n' in code else 'var slot_containers: Array[PanelContainer] = []\nvar tray_container: HBoxContainer = null'
new_vars = '''var slot_containers: Array[PanelContainer] = []
var tray_container: HBoxContainer = null
var rj45_channel_controls: Array[Control] = []
var rj45_wire_sprites: Array[TextureRect] = []
var rj45_pin_badges: Array[PanelContainer] = []
var tray_card_nodes: Array[PanelContainer] = []'''
if '\r\n' in code:
    new_vars = new_vars.replace('\n', '\r\n')

if vars_anchor in code:
    code = code.replace(vars_anchor, new_vars)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print('Updated preloads and wire definitions!')
