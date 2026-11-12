extends Control

# Leaderboard Modal (Papan Peringkat Teknisi)
# Displays Top 10 Dummy Technicians + Podium + Dynamic Player Rank based on total stars

signal closed

const CloseButtonScene = preload("res://scenes/close_button.tscn")

var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

var tex_star_gold = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_router = preload("res://art/assets/PING! Assets/Character/main-char-router.png")

@onready var backdrop: ColorRect = %Backdrop
@onready var card_wrapper: PanelContainer = %CardWrapper
@onready var close_btn_slot: Control = %CloseButtonSlot
@onready var tabs_container: HBoxContainer = %TabsContainer
@onready var podium_container: HBoxContainer = %PodiumContainer
@onready var list_container: VBoxContainer = %ListContainer
@onready var player_row_container: PanelContainer = %PlayerRowContainer

var current_tab: String = "global" # "global", "weekly", "local"
var tab_buttons: Dictionary = {}

var dummy_leaderboards: Dictionary = {
	"global": [
		{ "name": "Rian_NetMaster", "stars": 45, "title": "Master Network Architect", "skin": Color("#facc15") },
		{ "name": "Dewi_SysAdmin", "stars": 42, "title": "Firewall Guardian", "skin": Color("#38bdf8") },
		{ "name": "Budi_Cisco", "stars": 39, "title": "Subnet Specialist", "skin": Color("#4ade80") },
		{ "name": "Siti_Packet", "stars": 36, "title": "Packet Whisperer", "skin": Color("#f472b6") },
		{ "name": "Aris_Subnet", "stars": 33, "title": "Cable Craftsman", "skin": Color("#c084fc") },
		{ "name": "Dian_Router", "stars": 30, "title": "Cable Craftsman", "skin": Color("#94a3b8") },
		{ "name": "Kevin_LAN", "stars": 24, "title": "Junior Technician", "skin": Color("#38bdf8") },
		{ "name": "Fajar_Fiber", "stars": 21, "title": "Junior Technician", "skin": Color("#4ade80") },
		{ "name": "Nisa_Switch", "stars": 18, "title": "Apprentice", "skin": Color("#f472b6") }
	],
	"weekly": [
		{ "name": "Dewi_SysAdmin", "stars": 21, "title": "Firewall Guardian", "skin": Color("#38bdf8") },
		{ "name": "Aris_Subnet", "stars": 18, "title": "Cable Craftsman", "skin": Color("#c084fc") },
		{ "name": "Rian_NetMaster", "stars": 15, "title": "Master Architect", "skin": Color("#facc15") },
		{ "name": "Kevin_LAN", "stars": 12, "title": "Junior Technician", "skin": Color("#38bdf8") },
		{ "name": "Budi_Cisco", "stars": 9, "title": "Subnet Specialist", "skin": Color("#4ade80") },
		{ "name": "Dian_Router", "stars": 9, "title": "Cable Craftsman", "skin": Color("#94a3b8") },
		{ "name": "Siti_Packet", "stars": 6, "title": "Packet Whisperer", "skin": Color("#f472b6") },
		{ "name": "Fajar_Fiber", "stars": 6, "title": "Junior Technician", "skin": Color("#4ade80") },
		{ "name": "Nisa_Switch", "stars": 3, "title": "Apprentice", "skin": Color("#f472b6") }
	],
	"local": [
		{ "name": "Lab_TKJ_1", "stars": 42, "title": "Lab Komputer Utama", "skin": Color("#38bdf8") },
		{ "name": "Lab_TKJ_2", "stars": 39, "title": "Lab Server & Jaringan", "skin": Color("#4ade80") },
		{ "name": "Ruang_Server", "stars": 36, "title": "Data Center Sekolah", "skin": Color("#facc15") },
		{ "name": "Admin_Sekolah", "stars": 27, "title": "Subnet Specialist", "skin": Color("#c084fc") },
		{ "name": "Teknisi_Lab", "stars": 24, "title": "Cable Craftsman", "skin": Color("#f472b6") },
		{ "name": "Siswa_Teladan", "stars": 18, "title": "Junior Technician", "skin": Color("#94a3b8") },
		{ "name": "Magang_TI", "stars": 12, "title": "Junior Technician", "skin": Color("#38bdf8") }
	]
}

func _ready() -> void:
	visible = false
	_build_close_button()
	_setup_tabs()
	_render_leaderboard()
	
	backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close()
	)

func _build_close_button() -> void:
	for c in close_btn_slot.get_children():
		c.queue_free()
	var cb = CloseButtonScene.instantiate()
	cb.closed.connect(close)
	close_btn_slot.add_child(cb)

func _setup_tabs() -> void:
	for c in tabs_container.get_children():
		c.queue_free()
		
	var tab_defs = [
		{ "id": "global", "label": "🌐 Global" },
		{ "id": "weekly", "label": "📅 Mingguan" },
		{ "id": "local", "label": "🏫 Lab Lokal" }
	]
	
	for t in tab_defs:
		var btn = Button.new()
		btn.text = t["label"]
		btn.custom_minimum_size = Vector2(140, 38)
		btn.add_theme_font_override("font", font_extrabold)
		btn.add_theme_font_size_override("font_size", 13)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var tid = t["id"]
		btn.pressed.connect(func(): _select_tab(tid))
		tabs_container.add_child(btn)
		tab_buttons[tid] = btn
		
	_update_tab_styles()

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	_update_tab_styles()
	_render_leaderboard()

func _update_tab_styles() -> void:
	for tid in tab_buttons.keys():
		var btn = tab_buttons[tid] as Button
		var is_active = (tid == current_tab)
		var sb = StyleBoxFlat.new()
		if is_active:
			sb.bg_color = Color("#ea580c")
			sb.border_color = Color("#9a3412")
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color("#fed7aa")
			sb.border_color = Color("#ea580c")
			btn.add_theme_color_override("font_color", Color("#9a3412"))
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func _render_leaderboard() -> void:
	for c in podium_container.get_children():
		c.queue_free()
	for c in list_container.get_children():
		c.queue_free()
		
	var entries = dummy_leaderboards.get(current_tab, []).duplicate()
	
	# Determine player stars & position
	var player_stars = PlayerData.get_total_stars() if PlayerData else 0
	var player_name = PlayerData.current_username if PlayerData else "Teknisi"
	var player_title = PlayerData.current_title if PlayerData else "Junior Technician"
	var player_skin = PlayerData.get_active_skin_color() if PlayerData else Color("#38bdf8")
	
	# Top 3 Podium: Render order 2nd (Left), 1st (Center), 3rd (Right)
	if entries.size() >= 3:
		var top1 = entries[0]
		var top2 = entries[1]
		var top3 = entries[2]
		
		var p2_node = _create_podium_card(2, top2["name"], top2["stars"], top2["title"], top2["skin"], Color("#cbd5e1"), Color("#64748b"), "🥈 2nd", 160)
		var p1_node = _create_podium_card(1, top1["name"], top1["stars"], top1["title"], top1["skin"], Color("#fde047"), Color("#ca8a04"), "👑 1st", 195)
		var p3_node = _create_podium_card(3, top3["name"], top3["stars"], top3["title"], top3["skin"], Color("#fed7aa"), Color("#c2410c"), "🥉 3rd", 140)
		
		podium_container.add_child(p2_node)
		podium_container.add_child(p1_node)
		podium_container.add_child(p3_node)
		
	# Ranks 4 to End in scroll list
	for i in range(3, entries.size()):
		var rank_num = i + 1
		var item = entries[i]
		var row = _create_rank_row(rank_num, item["name"], item["stars"], item["title"], item["skin"], false)
		list_container.add_child(row)
		
	# Sticky Player Row at bottom
	_render_player_sticky_row(player_name, player_stars, player_title, player_skin, entries)

func _create_podium_card(rank: int, name_txt: String, stars_cnt: int, title_txt: String, skin_col: Color, bg_col: Color, border_col: Color, badge_txt: String, col_height: int) -> Control:
	var col = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.custom_minimum_size = Vector2(165, 230)
	col.add_theme_constant_override("separation", 6)
	
	# Avatar circle with skin color
	var av_box = PanelContainer.new()
	av_box.custom_minimum_size = Vector2(54, 54)
	av_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = skin_col
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(2.5)
	sb_av.set_corner_radius_all(27)
	sb_av.shadow_color = Color(0, 0, 0, 0.15)
	sb_av.shadow_size = 4
	sb_av.shadow_offset = Vector2(0, 2)
	av_box.add_theme_stylebox_override("panel", sb_av)
	
	var av_img = TextureRect.new()
	av_img.texture = tex_router
	av_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_box.add_child(av_img)
	col.add_child(av_box)
	
	# Podium Pillar
	var pillar = PanelContainer.new()
	pillar.custom_minimum_size = Vector2(160, col_height)
	var sb_pil = StyleBoxFlat.new()
	sb_pil.bg_color = bg_col
	sb_pil.border_color = border_col
	sb_pil.set_border_width_all(2.5)
	sb_pil.set_corner_radius_all(14)
	sb_pil.set_content_margin_all(8)
	pillar.add_theme_stylebox_override("panel", sb_pil)
	
	var p_vbox = VBoxContainer.new()
	p_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_vbox.add_theme_constant_override("separation", 2)
	pillar.add_child(p_vbox)
	
	var badge = Label.new()
	badge.text = badge_txt
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_override("font", font_black)
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", border_col.darkened(0.2))
	p_vbox.add_child(badge)
	
	var l_name = Label.new()
	l_name.text = name_txt
	l_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_name.add_theme_font_override("font", font_black)
	l_name.add_theme_font_size_override("font_size", 13)
	l_name.add_theme_color_override("font_color", Color("#2b1810"))
	p_vbox.add_child(l_name)
	
	var star_hb = HBoxContainer.new()
	star_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hb.add_theme_constant_override("separation", 4)
	p_vbox.add_child(star_hb)
	
	var s_icon = TextureRect.new()
	s_icon.texture = tex_star_gold
	s_icon.custom_minimum_size = Vector2(18, 18)
	s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_hb.add_child(s_icon)
	
	var s_lbl = Label.new()
	s_lbl.text = "%d ★" % stars_cnt
	s_lbl.add_theme_font_override("font", font_extrabold)
	s_lbl.add_theme_font_size_override("font_size", 13)
	s_lbl.add_theme_color_override("font_color", Color("#9a3412"))
	star_hb.add_child(s_lbl)
	
	col.add_child(pillar)
	return col

func _create_rank_row(rank: int, name_txt: String, stars_cnt: int, title_txt: String, skin_col: Color, is_player: bool) -> Control:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	var sb = StyleBoxFlat.new()
	if is_player:
		sb.bg_color = Color("#fef3c7")
		sb.border_color = Color("#ea580c")
		sb.set_border_width_all(2.5)
	else:
		sb.bg_color = Color("#ffffff")
		sb.border_color = Color("#e2e8f0")
		sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	row.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	row.add_child(hb)
	
	# Rank number
	var r_lbl = Label.new()
	r_lbl.text = "#%d" % rank
	r_lbl.custom_minimum_size = Vector2(36, 0)
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_lbl.add_theme_font_override("font", font_black)
	r_lbl.add_theme_font_size_override("font_size", 14)
	r_lbl.add_theme_color_override("font_color", Color("#4a2e2b") if not is_player else Color("#c2410c"))
	hb.add_child(r_lbl)
	
	# Mini avatar
	var av = PanelContainer.new()
	av.custom_minimum_size = Vector2(32, 32)
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = skin_col
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(1.5)
	sb_av.set_corner_radius_all(16)
	av.add_theme_stylebox_override("panel", sb_av)
	
	var av_tr = TextureRect.new()
	av_tr.texture = tex_router
	av_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.add_child(av_tr)
	hb.add_child(av)
	
	# Name & title
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)
	
	var n_lbl = Label.new()
	n_lbl.text = name_txt + (" (Kamu)" if is_player else "")
	n_lbl.add_theme_font_override("font", font_black)
	n_lbl.add_theme_font_size_override("font_size", 13)
	n_lbl.add_theme_color_override("font_color", Color("#1e293b"))
	vb.add_child(n_lbl)
	
	var t_lbl = Label.new()
	t_lbl.text = title_txt
	t_lbl.add_theme_font_override("font", font_semibold)
	t_lbl.add_theme_font_size_override("font_size", 10)
	t_lbl.add_theme_color_override("font_color", Color("#64748b"))
	vb.add_child(t_lbl)
	
	# Stars count
	var s_hb = HBoxContainer.new()
	s_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	s_hb.add_theme_constant_override("separation", 4)
	hb.add_child(s_hb)
	
	var s_tr = TextureRect.new()
	s_tr.texture = tex_star_gold
	s_tr.custom_minimum_size = Vector2(16, 16)
	s_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s_hb.add_child(s_tr)
	
	var s_val = Label.new()
	s_val.text = "%d ★" % stars_cnt
	s_val.add_theme_font_override("font", font_extrabold)
	s_val.add_theme_font_size_override("font_size", 13)
	s_val.add_theme_color_override("font_color", Color("#b45309"))
	s_hb.add_child(s_val)
	
	return row

func _render_player_sticky_row(p_name: String, p_stars: int, p_title: String, p_skin: Color, entries: Array) -> void:
	for c in player_row_container.get_children():
		c.queue_free()
		
	# Calculate player rank relative to entries
	var rank = 1
	for e in entries:
		if e["stars"] > p_stars:
			rank += 1
			
	var p_row = _create_rank_row(rank, p_name, p_stars, p_title, p_skin, true)
	player_row_container.add_child(p_row)

func open() -> void:
	_update_stars_and_refresh()
	visible = true
	card_wrapper.scale = Vector2(0.85, 0.85)
	card_wrapper.modulate.a = 0.0
	backdrop.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.22)
	tw.tween_property(card_wrapper, "modulate:a", 1.0, 0.18)
	tw.tween_property(backdrop, "modulate:a", 1.0, 0.18)

func _update_stars_and_refresh() -> void:
	_render_leaderboard()

func close() -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(card_wrapper, "scale", Vector2(0.9, 0.9), 0.14)
	tw.tween_property(card_wrapper, "modulate:a", 0.0, 0.14)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(func():
		visible = false
		closed.emit()
	)
