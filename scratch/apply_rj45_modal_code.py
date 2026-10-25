path = 'ping-game/scenes/gameplay/level_1_2.gd'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Locate from 'func _build_crimping_modal() -> void:' up to 'func _open_crimping_modal() -> void:'
start_marker = 'func _build_crimping_modal() -> void:'
end_marker = 'func _open_crimping_modal() -> void:'

assert start_marker in text, "start_marker not found"
assert end_marker in text, "end_marker not found"

start_idx = text.find(start_marker)
end_idx = text.find(end_marker)

new_minigame_code = """func _build_crimping_modal() -> void:
\tcrimping_modal = Control.new()
\tcrimping_modal.name = "CrimpingModal"
\tcrimping_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
\tcrimping_modal.visible = false
\tadd_child(crimping_modal)
\t
\tvar backdrop = ColorRect.new()
\tbackdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
\tbackdrop.color = Color(0, 0, 0, 0.72)
\tcrimping_modal.add_child(backdrop)
\t
\tcrimping_card = PanelContainer.new()
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
\tcrimping_card.add_child(vb_all)
\t
\t# Header (Lavender #e8daf8)
\tvar hdr = PanelContainer.new()
\thdr.custom_minimum_size = Vector2(914, 46)
\tvar sb_h = StyleBoxFlat.new()
\tsb_h.bg_color = Color("#e8daf8")
\tsb_h.border_color = Color("#4a2e2b")
\tsb_h.border_width_bottom = 3
\tsb_h.corner_radius_top_left = 17
\tsb_h.corner_radius_top_right = 17
\thdr.add_theme_stylebox_override("panel", sb_h)
\tvb_all.add_child(hdr)
\t
\tvar c_hdr = Control.new()
\tc_hdr.custom_minimum_size = Vector2(914, 46)
\thdr.add_child(c_hdr)
\t
\tvar t_lbl = Label.new()
\tt_lbl.text = "MERAKIT PIN KABEL STRAIGHT (STANDAR T568B)"
\tt_lbl.size = Vector2(914, 46)
\tt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\tt_lbl.add_theme_font_override("font", font_black)
\tt_lbl.add_theme_font_size_override("font_size", 14)
\tt_lbl.add_theme_color_override("font_color", Color("#4a2e2b"))
\tc_hdr.add_child(t_lbl)
\t
\tvar c_btn = Button.new()
\tc_btn.text = "\\u2715"
\tc_btn.position = Vector2(914 - 44, 6)
\tc_btn.size = Vector2(34, 34)
\tc_btn.pivot_offset = Vector2(17, 17)
\tvar sb_cls = StyleBoxFlat.new()
\tsb_cls.bg_color = Color("#fddede")
\tsb_cls.border_color = Color("#4a2e2b")
\tsb_cls.set_border_width_all(2.5)
\tsb_cls.set_corner_radius_all(17)
\tc_btn.add_theme_stylebox_override("normal", sb_cls)
\tc_btn.add_theme_font_override("font", font_black)
\tc_btn.add_theme_font_size_override("font_size", 14)
\tc_btn.add_theme_color_override("font_color", Color("#4a2e2b"))
\tc_btn.pressed.connect(_close_crimping_modal)
\t_setup_hover_scale(c_btn, 1.15)
\tc_hdr.add_child(c_btn)
\t
\t# Content Body (Left: RJ45 Connector, Right: Wire Selection & Controls)
\tvar body_margin = MarginContainer.new()
\tbody_margin.add_theme_constant_override("margin_left", 20)
\tbody_margin.add_theme_constant_override("margin_top", 12)
\tbody_margin.add_theme_constant_override("margin_right", 20)
\tbody_margin.add_theme_constant_override("margin_bottom", 12)
\tvb_all.add_child(body_margin)
\t
\tvar hb_body = HBoxContainer.new()
\thb_body.add_theme_constant_override("separation", 22)
\tbody_margin.add_child(hb_body)
\t
\t# ================= LEFT COLUMN: RJ45 CONNECTOR =================
\tvar left_col = VBoxContainer.new()
\tleft_col.alignment = BoxContainer.ALIGNMENT_CENTER
\tleft_col.add_theme_constant_override("separation", 6)
\thb_body.add_child(left_col)
\t
\tvar rj_label = Label.new()
\trj_label.text = "KONEKTOR RJ45"
\trj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\trj_label.add_theme_font_override("font", font_black)
\trj_label.add_theme_font_size_override("font_size", 13)
\trj_label.add_theme_color_override("font_color", Color("#334155"))
\tleft_col.add_child(rj_label)
\t
\t# RJ45 Connector Widget Root
\tvar rj_widget = Control.new()
\trj_widget.custom_minimum_size = Vector2(280, 390)
\trj_widget.size = Vector2(280, 390)
\tleft_col.add_child(rj_widget)
\t
\t# Channel Slots Coordinates (derived from authentic RJ45 vector diagram)
\tvar NATIVE_X = [47.0, 102.0, 157.0, 211.0, 264.0, 320.0, 374.0, 428.0]
\tvar scale_f = 280.0 / 502.0
\t
\trj45_channel_controls.clear()
\trj45_wire_sprites.clear()
\trj45_pin_badges.clear()
\t
\t# 1. Base Wire Channels (placed behind the housing)
\tvar channels_layer = Control.new()
\tchannels_layer.size = Vector2(280, 390)
\trj_widget.add_child(channels_layer)
\t
\tfor i in range(8):
\t\tvar ch_x = NATIVE_X[i] * scale_f
\t\tvar ch_w = 15.0
\t\tvar ch_y = 108.0
\t\tvar ch_h = 224.0
\t\t
\t\t# Channel slot container
\t\tvar ch_ctrl = Control.new()
\t\tch_ctrl.name = "RJChannel_%d" % i
\t\tch_ctrl.position = Vector2(ch_x, ch_y)
\t\tch_ctrl.size = Vector2(ch_w, ch_h)
\t\tchannels_layer.add_child(ch_ctrl)
\t\trj45_channel_controls.append(ch_ctrl)
\t\t
\t\t# Faint empty slot background
\t\tvar empty_bg = Panel.new()
\t\tempty_bg.size = Vector2(ch_w, ch_h)
\t\tvar sb_empty = StyleBoxFlat.new()
\t\tsb_empty.bg_color = Color(0.9, 0.92, 0.95, 0.5)
\t\tsb_empty.border_color = Color(0.75, 0.8, 0.88, 0.8)
\t\tsb_empty.set_border_width_all(1)
\t\tempty_bg.add_theme_stylebox_override("panel", sb_empty)
\t\tch_ctrl.add_child(empty_bg)
\t\t
\t\t# Wire TextureRect (visible when wire assigned)
\t\tvar wire_tex_rect = TextureRect.new()
\t\twire_tex_rect.name = "WireTex"
\t\twire_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\twire_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
\t\twire_tex_rect.size = Vector2(ch_w, ch_h)
\t\twire_tex_rect.visible = false
\t\tch_ctrl.add_child(wire_tex_rect)
\t\trj45_wire_sprites.append(wire_tex_rect)
\t\t
\t\t# Interactive touch/click handling on channel
\t\tvar slot_idx = i
\t\tch_ctrl.gui_input.connect(func(ev: InputEvent):
\t\t\tif ev is InputEventMouseButton:
\t\t\t\tvar mb = ev as InputEventMouseButton
\t\t\t\tif mb.button_index == MOUSE_BUTTON_LEFT:
\t\t\t\t\tif mb.pressed and pin_slots[slot_idx] != null:
\t\t\t\t\t\t_start_wire_drag(pin_slots[slot_idx], slot_idx, mb.global_position)
\t\t\t\t\telif not mb.pressed:
\t\t\t\t\t\t_end_wire_drag(mb.global_position)
\t\t\telif ev is InputEventMouseMotion:
\t\t\t\t_process_wire_drag((ev as InputEventMouseMotion).global_position)
\t\t\telif ev is InputEventScreenTouch:
\t\t\t\tvar st = ev as InputEventScreenTouch
\t\t\t\tif st.pressed and pin_slots[slot_idx] != null:
\t\t\t\t\t_start_wire_drag(pin_slots[slot_idx], slot_idx, st.position)
\t\t\t\telif not st.pressed:
\t\t\t\t\t_end_wire_drag(st.position)
\t\t\telif ev is InputEventScreenDrag:
\t\t\t\t_process_wire_drag((ev as InputEventScreenDrag).position)
\t\t)
\t
\t# 2. RJ45 Housing Overlay (On top of wire channels)
\tvar housing_rect = TextureRect.new()
\thousing_rect.texture = tex_rj45_housing
\thousing_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\thousing_rect.stretch_mode = TextureRect.STRETCH_SCALE
\thousing_rect.size = Vector2(280, 308)
\thousing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
\trj_widget.add_child(housing_rect)
\t
\t# 3. Pin Number Badges Row (Below wire tails at y=340)
\tvar badges_container = Control.new()
\tbadges_container.position = Vector2(0, 340)
\tbadges_container.size = Vector2(280, 32)
\trj_widget.add_child(badges_container)
\t
\tfor i in range(8):
\t\tvar ch_x = NATIVE_X[i] * scale_f
\t\tvar badge = PanelContainer.new()
\t\tbadge.position = Vector2(ch_x - 3, 0)
\t\tbadge.custom_minimum_size = Vector2(21, 24)
\t\tbadge.size = Vector2(21, 24)
\t\tvar sb_b = StyleBoxFlat.new()
\t\tsb_b.bg_color = Color("#e2e8f0")
\t\tsb_b.border_color = Color("#94a3b8")
\t\tsb_b.set_border_width_all(1.5)
\t\tsb_b.set_corner_radius_all(6)
\t\tbadge.add_theme_stylebox_override("panel", sb_b)
\t\t
\t\tvar b_lbl = Label.new()
\t\tb_lbl.name = "BadgeLabel"
\t\tb_lbl.text = str(i + 1)
\t\tb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\tb_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\t\tb_lbl.add_theme_font_override("font", font_black)
\t\tb_lbl.add_theme_font_size_override("font_size", 10)
\t\tb_lbl.add_theme_color_override("font_color", Color("#475569"))
\t\tbadge.add_child(b_lbl)
\t\t
\t\tbadges_container.add_child(badge)
\t\trj45_pin_badges.append(badge)
\t\t
\t\t# Clicking pin badge also removes wire if present
\t\tvar s_idx = i
\t\tbadge.gui_input.connect(func(ev: InputEvent):
\t\t\tif (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
\t\t\t\t_on_slot_clicked(s_idx)
\t\t)
\t
\t# ================= RIGHT COLUMN: WIRE SELECTION & CONTROLS =================
\tvar right_col = VBoxContainer.new()
\tright_col.custom_minimum_size = Vector2(550, 420)
\tright_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tright_col.add_theme_constant_override("separation", 10)
\thb_body.add_child(right_col)
\t
\t# Guide Card
\tvar info_box = PanelContainer.new()
\tvar sb_info = StyleBoxFlat.new()
\tsb_info.bg_color = Color("#f8fafc")
\tsb_info.border_color = Color("#cbd5e1")
\tsb_info.set_border_width_all(1.5)
\tsb_info.set_corner_radius_all(12)
\tsb_info.set_content_margin_all(10)
\tinfo_box.add_theme_stylebox_override("panel", sb_info)
\tright_col.add_child(info_box)
\t
\tvar vb_info = VBoxContainer.new()
\tvb_info.add_theme_constant_override("separation", 3)
\tinfo_box.add_child(vb_info)
\t
\tvar hb_std = HBoxContainer.new()
\thb_std.add_theme_constant_override("separation", 8)
\tvb_info.add_child(hb_std)
\t
\tvar title_sec = Label.new()
\ttitle_sec.text = "PILIH & SUSUN PIN RJ45"
\ttitle_sec.add_theme_font_override("font", font_black)
\ttitle_sec.add_theme_font_size_override("font_size", 14)
\ttitle_sec.add_theme_color_override("font_color", Color("#1e293b"))
\thb_std.add_child(title_sec)
\t
\tvar std_pill = PanelContainer.new()
\tvar sb_sp = StyleBoxFlat.new()
\tsb_sp.bg_color = Color("#dcfce7")
\tsb_sp.border_color = Color("#16a34a")
\tsb_sp.set_border_width_all(1)
\tsb_sp.set_corner_radius_all(6)
\tsb_sp.set_content_margin_all(3)
\tstd_pill.add_theme_stylebox_override("panel", sb_sp)
\tvar sp_lbl = Label.new()
\tsp_lbl.text = "STANDAR T568B"
\tsp_lbl.add_theme_font_override("font", font_black)
\tsp_lbl.add_theme_font_size_override("font_size", 10)
\tsp_lbl.add_theme_color_override("font_color", Color("#15803d"))
\tstd_pill.add_child(sp_lbl)
\thb_std.add_child(std_pill)
\t
\tvar sub_info = Label.new()
\tsub_info.text = "Ketuk kabel warna untuk memasukkan ke pin RJ45 berikutnya secara berurutan, atau seret langsung ke slot konektor di sebelah kiri."
\tsub_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tsub_info.add_theme_font_override("font", font_semibold)
\tsub_info.add_theme_font_size_override("font_size", 11)
\tsub_info.add_theme_color_override("font_color", Color("#64748b"))
\tvb_info.add_child(sub_info)
\t
\t# Wire Cards Grid (4 columns x 2 rows)
\tvar grid_scroll = PanelContainer.new()
\tvar sb_grid_bg = StyleBoxFlat.new()
\tsb_grid_bg.bg_color = Color.TRANSPARENT
\tgrid_scroll.add_theme_stylebox_override("panel", sb_grid_bg)
\tright_col.add_child(grid_scroll)
\t
\tvar grid_wires = GridContainer.new()
\tgrid_wires.columns = 4
\tgrid_wires.add_theme_constant_override("h_separation", 10)
\tgrid_wires.add_theme_constant_override("v_separation", 10)
\tgrid_scroll.add_child(grid_wires)
\t
\ttray_card_nodes.clear()
\tfor i in range(all_wires_def.size()):
\t\tvar wire = all_wires_def[i]
\t\tvar wire_card = PanelContainer.new()
\t\twire_card.name = "TrayCard_%s" % wire["id"]
\t\twire_card.custom_minimum_size = Vector2(125, 96)
\t\twire_card.pivot_offset = Vector2(62, 48)
\t\tvar sb_w = StyleBoxFlat.new()
\t\tsb_w.bg_color = Color("#ffffff")
\t\tsb_w.border_color = Color("#cbd5e1")
\t\tsb_w.set_border_width_all(2)
\t\tsb_w.set_corner_radius_all(10)
\t\tsb_w.set_content_margin_all(6)
\t\tsb_w.shadow_color = Color(0, 0, 0, 0.08)
\t\tsb_w.shadow_size = 4
\t\tsb_w.shadow_offset = Vector2(0, 2)
\t\twire_card.add_theme_stylebox_override("panel", sb_w)
\t\t
\t\tvar vb_card = VBoxContainer.new()
\t\tvb_card.alignment = BoxContainer.ALIGNMENT_CENTER
\t\tvb_card.add_theme_constant_override("separation", 4)
\t\twire_card.add_child(vb_card)
\t\t
\t\t# Wire preview texture
\t\tvar wire_tex = TextureRect.new()
\t\twire_tex.texture = wire["tex"]
\t\twire_tex.custom_minimum_size = Vector2(16, 52)
\t\twire_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\t\twire_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\t\tvb_card.add_child(wire_tex)
\t\t
\t\tvar name_l = Label.new()
\t\tname_l.name = "WireName"
\t\tname_l.text = wire["name"]
\t\tname_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\tname_l.add_theme_font_override("font", font_black)
\t\tname_l.add_theme_font_size_override("font_size", 10)
\t\tname_l.add_theme_color_override("font_color", Color("#1e293b"))
\t\tvb_card.add_child(name_l)
\t\t
\t\t# Drag & Drop and Tap support for tray card
\t\tvar wire_data = wire
\t\twire_card.gui_input.connect(func(ev: InputEvent):
\t\t\tif ev is InputEventMouseButton:
\t\t\t\tvar mb = ev as InputEventMouseButton
\t\t\t\tif mb.button_index == MOUSE_BUTTON_LEFT:
\t\t\t\t\tif mb.pressed:
\t\t\t\t\t\t_start_wire_drag(wire_data, -1, mb.global_position)
\t\t\t\t\telse:
\t\t\t\t\t\t_end_wire_drag(mb.global_position)
\t\t\telif ev is InputEventMouseMotion:
\t\t\t\t_process_wire_drag((ev as InputEventMouseMotion).global_position)
\t\t\telif ev is InputEventScreenTouch:
\t\t\t\tvar st = ev as InputEventScreenTouch
\t\t\t\tif st.pressed:
\t\t\t\t\t_start_wire_drag(wire_data, -1, st.position)
\t\t\t\telse:
\t\t\t\t\t_end_wire_drag(st.position)
\t\t\telif ev is InputEventScreenDrag:
\t\t\t\t_process_wire_drag((ev as InputEventScreenDrag).position)
\t\t)
\t\t_setup_hover_scale(wire_card, 1.08)
\t\tgrid_wires.add_child(wire_card)
\t\ttray_card_nodes.append(wire_card)
\t
\t# Action Buttons Row
\tvar footer_row = HBoxContainer.new()
\tfooter_row.alignment = BoxContainer.ALIGNMENT_CENTER
\tfooter_row.add_theme_constant_override("separation", 16)
\tright_col.add_child(footer_row)
\t
\tvar btn_reset = Button.new()
\tbtn_reset.text = "RESET"
\tbtn_reset.custom_minimum_size = Vector2(120, 42)
\tbtn_reset.add_theme_font_override("font", font_black)
\tbtn_reset.add_theme_font_size_override("font_size", 13)
\tvar sb_rst = StyleBoxFlat.new()
\tsb_rst.bg_color = Color("#fee2e2")
\tsb_rst.border_color = Color("#ef4444")
\tsb_rst.set_border_width_all(2)
\tsb_rst.set_corner_radius_all(10)
\tbtn_reset.add_theme_stylebox_override("normal", sb_rst)
\tbtn_reset.add_theme_color_override("font_color", Color("#991b1b"))
\tbtn_reset.pressed.connect(_reset_minigame_slots)
\t_setup_hover_scale(btn_reset, 1.08)
\tfooter_row.add_child(btn_reset)
\t
\tvar btn_guide_mini = Button.new()
\tbtn_guide_mini.text = "LIHAT PANDUAN"
\tbtn_guide_mini.custom_minimum_size = Vector2(150, 42)
\tbtn_guide_mini.add_theme_font_override("font", font_black)
\tbtn_guide_mini.add_theme_font_size_override("font_size", 13)
\tvar sb_gm = StyleBoxFlat.new()
\tsb_gm.bg_color = Color("#f5f3ff")
\tsb_gm.border_color = Color("#7c3aed")
\tsb_gm.set_border_width_all(2)
\tsb_gm.set_corner_radius_all(10)
\tbtn_guide_mini.add_theme_stylebox_override("normal", sb_gm)
\tbtn_guide_mini.add_theme_color_override("font_color", Color("#5b21b6"))
\tbtn_guide_mini.pressed.connect(_open_guidebook_modal)
\t_setup_hover_scale(btn_guide_mini, 1.08)
\tfooter_row.add_child(btn_guide_mini)
\t
\tvar btn_submit = Button.new()
\tbtn_submit.text = "KRIMPING KABEL"
\tbtn_submit.custom_minimum_size = Vector2(180, 42)
\tbtn_submit.add_theme_font_override("font", font_black)
\tbtn_submit.add_theme_font_size_override("font_size", 14)
\tvar sb_sub = StyleBoxFlat.new()
\tsb_sub.bg_color = Color("#16a34a")
\tsb_sub.border_color = Color("#14532d")
\tsb_sub.set_border_width_all(2.5)
\tsb_sub.set_corner_radius_all(12)
\tbtn_submit.add_theme_stylebox_override("normal", sb_sub)
\tbtn_submit.add_theme_color_override("font_color", Color("#ffffff"))
\tbtn_submit.pressed.connect(_validate_crimping_submission)
\t_setup_hover_scale(btn_submit, 1.1)
\tfooter_row.add_child(btn_submit)
\t
\t_refresh_rj45_display()

func _refresh_rj45_display() -> void:
\tfor i in range(8):
\t\tvar wire = pin_slots[i]
\t\tif i < rj45_wire_sprites.size():
\t\t\tvar wire_tex_rect = rj45_wire_sprites[i]
\t\t\tif wire != null:
\t\t\t\twire_tex_rect.texture = wire["tex"]
\t\t\t\twire_tex_rect.visible = true
\t\t\telse:
\t\t\t\twire_tex_rect.visible = false
\t\t\t\t
\t\tif i < rj45_pin_badges.size():
\t\t\tvar badge = rj45_pin_badges[i]
\t\t\tvar badge_lbl = badge.get_node_or_null("BadgeLabel") as Label
\t\t\tif wire != null:
\t\t\t\tvar sb_act = StyleBoxFlat.new()
\t\t\t\tsb_act.bg_color = Color("#16a34a")
\t\t\t\tsb_act.border_color = Color("#14532d")
\t\t\t\tsb_act.set_border_width_all(1.5)
\t\t\t\tsb_act.set_corner_radius_all(6)
\t\t\t\tbadge.add_theme_stylebox_override("panel", sb_act)
\t\t\t\tif badge_lbl:
\t\t\t\t\tbadge_lbl.add_theme_color_override("font_color", Color.WHITE)
\t\t\telse:
\t\t\t\tvar sb_emp = StyleBoxFlat.new()
\t\t\t\tsb_emp.bg_color = Color("#e2e8f0")
\t\t\t\tsb_emp.border_color = Color("#94a3b8")
\t\t\t\tsb_emp.set_border_width_all(1.5)
\t\t\t\tsb_emp.set_corner_radius_all(6)
\t\t\t\tbadge.add_theme_stylebox_override("panel", sb_emp)
\t\t\t\tif badge_lbl:
\t\t\t\t\tbadge_lbl.add_theme_color_override("font_color", Color("#475569"))
\t\t\t\t\t
\t# Update tray cards (dim if already assigned)
\tfor i in range(all_wires_def.size()):
\t\tif i >= tray_card_nodes.size():
\t\t\tcontinue
\t\tvar wire_def = all_wires_def[i]
\t\tvar card = tray_card_nodes[i]
\t\tvar is_assigned = false
\t\tfor p in pin_slots:
\t\t\tif p != null and p["id"] == wire_def["id"]:
\t\t\t\tis_assigned = true
\t\t\t\tbreak
\t\t\t\t
\t\tvar name_l = card.get_node_or_null("VBoxContainer/WireName") as Label
\t\tif is_assigned:
\t\t\tcard.modulate.a = 0.35
\t\t\tif name_l:
\t\t\t\tname_l.text = wire_def["name"] + " \\u2713"
\t\t\t\tname_l.add_theme_color_override("font_color", Color("#16a34a"))
\t\telse:
\t\t\tcard.modulate.a = 1.0
\t\tif name_l:
\t\t\tname_l.text = wire_def["name"]
\t\t\tname_l.add_theme_color_override("font_color", Color("#1e293b"))

var is_dragging: bool = false
var dragged_wire: Dictionary = {}
var drag_from_slot_idx: int = -1
var drag_start_global: Vector2 = Vector2.ZERO

func _init_drag_ghost() -> void:
\tif not drag_ghost:
\t\tdrag_ghost = Control.new()
\t\tdrag_ghost.name = "DragGhost"
\t\tdrag_ghost.size = Vector2(24, 80)
\t\tdrag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
\t\tdrag_ghost.visible = false
\t\tdrag_ghost.z_index = 50
\t\tcrimping_modal.add_child(drag_ghost)

func _update_drag_ghost_visual(wire: Dictionary) -> void:
\t_init_drag_ghost()
\tfor ch in drag_ghost.get_children():
\t\tch.queue_free()
\tvar tr = TextureRect.new()
\ttr.texture = wire["tex"]
\ttr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\ttr.stretch_mode = TextureRect.STRETCH_SCALE
\ttr.size = Vector2(22, 80)
\tdrag_ghost.add_child(tr)

func _start_wire_drag(wire: Dictionary, from_slot: int, global_pos: Vector2) -> void:
\tdragged_wire = wire
\tdrag_from_slot_idx = from_slot
\tdrag_start_global = global_pos
\tis_dragging = false

func _process_wire_drag(global_pos: Vector2) -> void:
\tif dragged_wire.is_empty():
\t\treturn
\tif not is_dragging and global_pos.distance_to(drag_start_global) > 10.0:
\t\tis_dragging = true
\t\t_update_drag_ghost_visual(dragged_wire)
\t\tdrag_ghost.visible = true
\t\t_play_tone(523.25, 0.05, 0.12)
\t\t
\tif is_dragging and drag_ghost:
\t\tdrag_ghost.global_position = global_pos - Vector2(11, 40)

func _end_wire_drag(global_pos: Vector2) -> void:
\tif dragged_wire.is_empty():
\t\treturn
\t\t
\tif drag_ghost:
\t\tdrag_ghost.visible = false
\t\t
\tif is_dragging:
\t\t# Check if dropped onto any RJ45 channel
\t\tvar target_slot_idx = -1
\t\tfor i in range(rj45_channel_controls.size()):
\t\t\tvar ch_ctrl = rj45_channel_controls[i]
\t\t\tvar rect = ch_ctrl.get_global_rect()
\t\t\trect = rect.grow_individual(6.0, 10.0, 6.0, 20.0)
\t\t\tif rect.has_point(global_pos):
\t\t\t\ttarget_slot_idx = i
\t\t\t\tbreak
\t\t\t\t
\t\tif target_slot_idx != -1:
\t\t\t# If this wire is already in another slot, clear that slot
\t\t\tfor p in range(8):
\t\t\t\tif pin_slots[p] != null and pin_slots[p]["id"] == dragged_wire["id"]:
\t\t\t\t\tpin_slots[p] = null
\t\t\t\t\t
\t\t\tpin_slots[target_slot_idx] = dragged_wire
\t\t\t_play_tone(587.33 + target_slot_idx * 40.0, 0.08)
\t\telse:
\t\t\tif drag_from_slot_idx != -1:
\t\t\t\tpin_slots[drag_from_slot_idx] = null
\t\t\t\t_play_tone(392.0, 0.08)
\t\t\t\t
\t\t_refresh_rj45_display()
\telse:
\t\tif drag_from_slot_idx != -1:
\t\t\t_on_slot_clicked(drag_from_slot_idx)
\t\telse:
\t\t\t_on_tray_wire_clicked(dragged_wire)
\t\t\t
\tdragged_wire = {}
\tdrag_from_slot_idx = -1
\tis_dragging = false

func _on_tray_wire_clicked(wire_data: Dictionary) -> void:
\t# If wire is already placed, clicking it removes it
\tfor i in range(8):
\t\tif pin_slots[i] != null and pin_slots[i]["id"] == wire_data["id"]:
\t\t\tpin_slots[i] = null
\t\t\t_play_tone(392.0, 0.08)
\t\t\t_refresh_rj45_display()
\t\t\treturn
\t\t\t
\t# Place in next empty pin
\tfor i in range(8):
\t\tif pin_slots[i] == null:
\t\t\tpin_slots[i] = wire_data
\t\t\t_play_tone(587.33 + i * 40.0, 0.08)
\t\t\t_refresh_rj45_display()
\t\t\treturn
\t\t\t
\tshow_toast("Semua 8 pin konektor sudah terisi! Ketuk pin untuk melepasnya.")

func _on_slot_clicked(slot_idx: int) -> void:
\tif pin_slots[slot_idx] != null:
\t\tpin_slots[slot_idx] = null
\t\t_play_tone(440.0, 0.08)
\t\t_refresh_rj45_display()

func _reset_minigame_slots() -> void:
\t_play_sweep(659.25, 330.0, 0.1, 0.15)
\tfor i in range(8):
\t\tpin_slots[i] = null
\t_refresh_rj45_display()
\tshow_toast("Semua pin konektor RJ45 berhasil dikosongkan.")

func _validate_crimping_submission() -> void:
\t# Check if all 8 slots are filled
\tfor i in range(8):
\t\tif pin_slots[i] == null:
\t\t\t_play_tone(220.0, 0.2)
\t\t\tshow_toast("Pin %d masih kosong! Pasang semua 8 kabel ke konektor RJ45." % (i + 1))
\t\t\treturn
\t\t\t
\t# Compare with TARGET_SEQUENCE (T568B)
\tvar is_correct = true
\tvar wrong_indices: Array[int] = []
\tfor i in range(8):
\t\tif pin_slots[i]["id"] != TARGET_SEQUENCE[i]:
\t\t\tis_correct = false
\t\t\twrong_indices.append(i)
\t\t\t
\tif is_correct:
\t\t# VICTORY!
\t\t_play_sweep(440.0, 880.0, 0.15, 0.25)
\t\t_close_crimping_modal()
\t\tif PlayerData:
\t\t\tPlayerData.set_level_stars(1, 2, hearts)
\t\t_trigger_win()
\telse:
\t\t# PENALTY
\t\thearts -= 1
\t\t_update_hearts_display()
\t\t_play_tone(180.0, 0.25, 0.3)
\t\t
\t\t# Visual shake on crimping card
\t\tif crimping_card:
\t\t\tvar orig_pos = crimping_card.position
\t\t\tvar tw = create_tween()
\t\t\ttw.tween_property(crimping_card, "position:x", orig_pos.x - 12, 0.05)
\t\t\ttw.tween_property(crimping_card, "position:x", orig_pos.x + 12, 0.05)
\t\t\ttw.tween_property(crimping_card, "position:x", orig_pos.x - 6, 0.05)
\t\t\ttw.tween_property(crimping_card, "position:x", orig_pos.x, 0.05)
\t\t\t
\t\tif hearts > 0:
\t\t\tshow_toast("Urutan kabel tidak sesuai standar T568B! Cek Buku Panduan.")
\t\telse:
\t\t\t_close_crimping_modal()
\t\t\t_trigger_game_over("Nyawa teknisi habis! Urutan kabel salah 3 kali.")

"""

if '\r\n' in text:
    new_minigame_code = new_minigame_code.replace('\n', '\r\n')

text = text[:start_idx] + new_minigame_code + text[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Successfully replaced crimping modal with full RJ45 connector minigame!')
