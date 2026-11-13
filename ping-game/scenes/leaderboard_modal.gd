extends Control

# Leaderboard Modal -> Papan Peringkat & Data Bintang Level Teknisi
# Menampilkan rekap bintang tertinggi per level yang didapatkan pemain secara offline/lokal

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

var current_tab: String = "all" # "all", "stage1", "stage2", "stage3", "stage4", "stage5"
var tab_buttons: Dictionary = {}

const STAGES_METADATA = [
	{
		"stage": 1,
		"stage_name": "Stage 1: Gudang Hardware",
		"tab_id": "stage1",
		"levels": [
			{ "num": 1, "tag": "1.1", "name": "Kabel Straight vs Cross", "desc": "Identifikasi kabel Straight dan Cross" },
			{ "num": 2, "tag": "1.2", "name": "Perakitan Pin TIA/EIA 568A/B", "desc": "Urutan 8 pin kabel standar TIA/EIA" },
			{ "num": 3, "tag": "1.3", "name": "Switch vs Hub (Anti-Collision)", "desc": "Rutekan paket Unicast tanpa collision" }
		]
	},
	{
		"stage": 2,
		"stage_name": "Stage 2: Koridor Server Utama",
		"tab_id": "stage2",
		"levels": [
			{ "num": 1, "tag": "2.1", "name": "Klasifikasi Kelas IPv4", "desc": "Sortir alamat IPv4 ke kelas A, B, atau C" },
			{ "num": 2, "tag": "2.2", "name": "Firewall Manual: IP Publik vs Privat", "desc": "Blokir IP Publik & izinkan IP Privat" },
			{ "num": 3, "tag": "2.3", "name": "Protokol ARP: Request (Broadcast)", "desc": "Kawal ARP-Request hingga pemilik IP ditemukan" },
			{ "num": 4, "tag": "2.4", "name": "ARP-Reply & Tabel ARP", "desc": "Tuntun ARP-Reply, simpan MAC di Tabel ARP, uji Unicast" }
		]
	},
	{
		"stage": 3,
		"stage_name": "Stage 3: Ruang Kontrol Subnet",
		"tab_id": "stage3",
		"levels": [
			{ "num": 1, "tag": "3.1", "name": "Menentukan NetID dan HostID", "desc": "Pisahkan NetID dan HostID pada IP 10.20.30.55/24" },
			{ "num": 2, "tag": "3.2", "name": "Mencocokkan CIDR & Subnet Mask", "desc": "Cocokkan Subnet Mask desimal dengan CIDR" },
			{ "num": 3, "tag": "3.3", "name": "Identifikasi IP Usable", "desc": "Nyalakan PC Klien dengan IP Usable yang valid" },
			{ "num": 4, "tag": "3.4", "name": "Memperbaiki Routing Table", "desc": "Lengkapi Routing Table Router R-01 ke Server" }
		]
	},
	{
		"stage": 4,
		"stage_name": "Stage 4: Fasilitas Eksternal",
		"tab_id": "stage4",
		"levels": [
			{ "num": 1, "tag": "4.1", "name": "Jangkauan Wilayah: PAN, LAN, MAN & WAN", "desc": "Klasifikasi situasi ke kategori wilayah yang tepat" },
			{ "num": 2, "tag": "4.2", "name": "Memperbaiki Pusat Topologi Star", "desc": "Hubungkan seluruh kabel PC ke Switch Pusat SW-01" },
			{ "num": 3, "tag": "4.3", "name": "Memperbaiki Topologi Ring & Mesh", "desc": "Selesaikan jalur melingkar Ring dan redundan Mesh" }
		]
	},
	{
		"stage": 5,
		"stage_name": "Stage 5: Gerbang Internet",
		"tab_id": "stage5",
		"levels": [
			{ "num": 1, "tag": "5.1", "name": "Model 7 Lapisan OSI Layer", "desc": "Susun 7 kartu OSI Layer dari Physical hingga Application" },
			{ "num": 2, "tag": "5.2", "name": "Data Encapsulation & Decapsulation", "desc": "Kemas data di Client lalu bongkar di Server" },
			{ "num": 3, "tag": "5.3", "name": "Protokol Transport: TCP vs UDP", "desc": "Arahkan situasi komunikasi ke jalur TCP atau UDP" },
			{ "num": 4, "tag": "5.4", "name": "Mencocokkan Layanan dengan Nomor Port", "desc": "Hubungkan HTTP, HTTPS, DNS, SSH & FTP ke port standar" },
			{ "num": 5, "tag": "5.5", "name": "TCP Three-Way Handshake", "desc": "Selesaikan SYN, SYN/ACK, ACK secara berurutan" }
		]
	}
]

func _ready() -> void:
	visible = false
	_build_close_button()
	_update_header_title()
	_setup_tabs()
	_render_leaderboard()
	
	backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close()
	)

func _update_header_title() -> void:
	var title_lbl = get_node_or_null("%TitleLabel")
	if title_lbl and title_lbl is Label:
		title_lbl.text = "⭐ REKAP PERFORMA LEVELMU"
		
	var pod_title = get_node_or_null("CardWrapper/MainVBox/ContentSplitHBox/LeftPodiumVBox/PodiumTitle")
	if pod_title and pod_title is Label:
		pod_title.text = "📊 RINGKASAN PERFORMA"
		
	var list_title = get_node_or_null("CardWrapper/MainVBox/ContentSplitHBox/RightListVBox/ListTitle")
	if list_title and list_title is Label:
		list_title.text = "📋 CAPAIAN BINTANG TIAP LEVEL"

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
		{ "id": "all", "label": "🌟 Semua" },
		{ "id": "stage1", "label": "Stage 1" },
		{ "id": "stage2", "label": "Stage 2" },
		{ "id": "stage3", "label": "Stage 3" },
		{ "id": "stage4", "label": "Stage 4" },
		{ "id": "stage5", "label": "Stage 5" }
	]
	
	for t in tab_defs:
		var btn = Button.new()
		btn.text = t["label"]
		btn.custom_minimum_size = Vector2(80, 36)
		btn.add_theme_font_override("font", font_extrabold)
		btn.add_theme_font_size_override("font_size", 12)
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
		sb.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func _render_leaderboard() -> void:
	for c in podium_container.get_children():
		c.queue_free()
	for c in list_container.get_children():
		c.queue_free()
		
	var pd = get_node_or_null("/root/PlayerData")
	var player_stars = pd.get_total_stars() if pd else 0
	var max_stars = pd.get_max_stars() if pd else 48
	var player_name = pd.current_username if pd else "Teknisi"
	var player_title = pd.get_technician_rank_title() if (pd and pd.has_method("get_technician_rank_title")) else "Junior Technician"
	var player_skin = pd.get_active_skin_color() if pd else Color("#38bdf8")
	var unlocked_stage = pd.unlocked_stage if pd else 1
	
	var stats = pd.get_star_rank_stats() if (pd and pd.has_method("get_star_rank_stats")) else {
		"rank1_perfect": 0, "rank2_good": 0, "rank3_passed": 0, "unlocked_unplayed": 1, "locked": 15
	}
	
	# -------------------------------------------------------------
	# 1. LEFT PANEL: Statistik Teknisi & Peringkat Bintang
	# -------------------------------------------------------------
	var left_box = VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", 10)
	
	# A. Profile Summary Card
	var prof_card = PanelContainer.new()
	var sb_prof = StyleBoxFlat.new()
	sb_prof.bg_color = Color("#fff7ed")
	sb_prof.border_color = Color("#ea580c")
	sb_prof.set_border_width_all(2.5)
	sb_prof.set_corner_radius_all(14)
	sb_prof.set_content_margin_all(10)
	prof_card.add_theme_stylebox_override("panel", sb_prof)
	
	var prof_hb = HBoxContainer.new()
	prof_hb.add_theme_constant_override("separation", 12)
	prof_card.add_child(prof_hb)
	
	# Avatar
	var av_panel = PanelContainer.new()
	av_panel.custom_minimum_size = Vector2(50, 50)
	var sb_av = StyleBoxFlat.new()
	sb_av.bg_color = player_skin
	sb_av.border_color = Color("#4a2e2b")
	sb_av.set_border_width_all(2)
	sb_av.set_corner_radius_all(25)
	av_panel.add_theme_stylebox_override("panel", sb_av)
	var av_tex = TextureRect.new()
	av_tex.texture = tex_router
	av_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_panel.add_child(av_tex)
	prof_hb.add_child(av_panel)
	
	var prof_info = VBoxContainer.new()
	prof_info.alignment = BoxContainer.ALIGNMENT_CENTER
	prof_info.add_theme_constant_override("separation", 1)
	
	var name_lbl = Label.new()
	name_lbl.text = player_name
	name_lbl.add_theme_font_override("font", font_black)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color("#2b1810"))
	prof_info.add_child(name_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = "🎖️ " + player_title
	title_lbl.add_theme_font_override("font", font_bold)
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color("#c2410c"))
	prof_info.add_child(title_lbl)
	
	var stage_lbl = Label.new()
	stage_lbl.text = "Stage Terbuka: %d / 5" % unlocked_stage
	stage_lbl.add_theme_font_override("font", font_semibold)
	stage_lbl.add_theme_font_size_override("font_size", 10)
	stage_lbl.add_theme_color_override("font_color", Color("#78350f"))
	prof_info.add_child(stage_lbl)
	
	prof_hb.add_child(prof_info)
	left_box.add_child(prof_card)
	
	# B. Star Progress Bar Card
	var star_card = PanelContainer.new()
	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color("#fef3c7")
	sb_st.border_color = Color("#d97706")
	sb_st.set_border_width_all(2)
	sb_st.set_corner_radius_all(12)
	sb_st.set_content_margin_all(8)
	star_card.add_theme_stylebox_override("panel", sb_st)
	
	var star_vb = VBoxContainer.new()
	star_vb.add_theme_constant_override("separation", 4)
	star_card.add_child(star_vb)
	
	var st_top_hb = HBoxContainer.new()
	var st_lbl = Label.new()
	st_lbl.text = "⭐ TOTAL BINTANG"
	st_lbl.add_theme_font_override("font", font_black)
	st_lbl.add_theme_font_size_override("font_size", 12)
	st_lbl.add_theme_color_override("font_color", Color("#92400e"))
	st_top_hb.add_child(st_lbl)
	
	var st_sp = Control.new()
	st_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_top_hb.add_child(st_sp)
	
	var st_val = Label.new()
	st_val.text = "%d / %d Bintang" % [player_stars, max_stars]
	st_val.add_theme_font_override("font", font_black)
	st_val.add_theme_font_size_override("font_size", 13)
	st_val.add_theme_color_override("font_color", Color("#b45309"))
	st_top_hb.add_child(st_val)
	star_vb.add_child(st_top_hb)
	
	var prog_bar = ProgressBar.new()
	prog_bar.min_value = 0
	prog_bar.max_value = max_stars
	prog_bar.value = player_stars
	prog_bar.show_percentage = false
	prog_bar.custom_minimum_size = Vector2(0, 10)
	var sb_pbg = StyleBoxFlat.new()
	sb_pbg.bg_color = Color("#fde68a")
	sb_pbg.set_corner_radius_all(5)
	var sb_pfg = StyleBoxFlat.new()
	sb_pfg.bg_color = Color("#f59e0b")
	sb_pfg.set_corner_radius_all(5)
	prog_bar.add_theme_stylebox_override("background", sb_pbg)
	prog_bar.add_theme_stylebox_override("fill", sb_pfg)
	star_vb.add_child(prog_bar)
	
	left_box.add_child(star_card)
	
	# C. Breakdown Peringkat Per Level
	var breakdown_grid = VBoxContainer.new()
	breakdown_grid.add_theme_constant_override("separation", 5)
	
	var rank_items = [
		{ "badge": "🥇 Sempurna", "sub": "3 Bintang ⭐⭐⭐", "count": stats["rank1_perfect"], "bg": Color("#fef9c3"), "border": Color("#ca8a04"), "col": Color("#854d0e") },
		{ "badge": "🥈 Baik", "sub": "2 Bintang ⭐⭐", "count": stats["rank2_good"], "bg": Color("#f1f5f9"), "border": Color("#94a3b8"), "col": Color("#334155") },
		{ "badge": "🥉 Cukup", "sub": "1 Bintang ⭐", "count": stats["rank3_passed"], "bg": Color("#ffedd5"), "border": Color("#ea580c"), "col": Color("#9a3412") },
		{ "badge": "🔒 Terkunci / Belum", "sub": "Selesaikan level sebelumnya", "count": stats["locked"] + stats["unlocked_unplayed"], "bg": Color("#f8fafc"), "border": Color("#cbd5e1"), "col": Color("#64748b") }
	]
	
	for it in rank_items:
		var item_card = PanelContainer.new()
		var sb_it = StyleBoxFlat.new()
		sb_it.bg_color = it["bg"]
		sb_it.border_color = it["border"]
		sb_it.set_border_width_all(1.5)
		sb_it.set_corner_radius_all(8)
		sb_it.set_content_margin_all(6)
		item_card.add_theme_stylebox_override("panel", sb_it)
		
		var it_hb = HBoxContainer.new()
		it_hb.add_theme_constant_override("separation", 8)
		item_card.add_child(it_hb)
		
		var it_vb = VBoxContainer.new()
		it_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b_lbl = Label.new()
		b_lbl.text = it["badge"]
		b_lbl.add_theme_font_override("font", font_black)
		b_lbl.add_theme_font_size_override("font_size", 11)
		b_lbl.add_theme_color_override("font_color", it["col"])
		it_vb.add_child(b_lbl)
		
		var s_lbl = Label.new()
		s_lbl.text = it["sub"]
		s_lbl.add_theme_font_override("font", font_semibold)
		s_lbl.add_theme_font_size_override("font_size", 9)
		s_lbl.add_theme_color_override("font_color", it["col"].darkened(0.2))
		it_vb.add_child(s_lbl)
		it_hb.add_child(it_vb)
		
		var cnt_lbl = Label.new()
		cnt_lbl.text = "%d Level" % it["count"]
		cnt_lbl.add_theme_font_override("font", font_black)
		cnt_lbl.add_theme_font_size_override("font_size", 13)
		cnt_lbl.add_theme_color_override("font_color", it["col"])
		cnt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		it_hb.add_child(cnt_lbl)
		
		breakdown_grid.add_child(item_card)
		
	left_box.add_child(breakdown_grid)
	
	# D. Reset Progress Button
	var reset_btn = Button.new()
	reset_btn.text = "🔄 Reset Progress Dari Awal"
	reset_btn.custom_minimum_size = Vector2(0, 32)
	reset_btn.add_theme_font_override("font", font_extrabold)
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.add_theme_color_override("font_color", Color("#dc2626"))
	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = Color("#fee2e2")
	sb_r.border_color = Color("#f87171")
	sb_r.set_border_width_all(1.5)
	sb_r.set_corner_radius_all(8)
	reset_btn.add_theme_stylebox_override("normal", sb_r)
	reset_btn.add_theme_stylebox_override("hover", sb_r)
	reset_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	reset_btn.pressed.connect(_on_reset_progress_pressed)
	left_box.add_child(reset_btn)
	
	podium_container.add_child(left_box)
	
	# -------------------------------------------------------------
	# 2. RIGHT PANEL: Daftar Bintang Tertinggi Per Level
	# -------------------------------------------------------------
	var stages_to_show: Array = []
	for s_entry in STAGES_METADATA:
		if current_tab == "all" or current_tab == s_entry["tab_id"]:
			stages_to_show.append(s_entry)
			
	for s_data in stages_to_show:
		var s_num = int(s_data["stage"])
		var stage_is_unlocked = pd.is_stage_unlocked(s_num) if pd else (s_num == 1)
		var unl_lvl = pd.get_stage_unlocked_level(s_num) if (pd and stage_is_unlocked) else (1 if s_num == 1 else 0)
		
		# Stage Header in List
		var sh_panel = PanelContainer.new()
		var sb_sh = StyleBoxFlat.new()
		sb_sh.bg_color = Color("#ffedd5") if stage_is_unlocked else Color("#f1f5f9")
		sb_sh.border_color = Color("#fdba74") if stage_is_unlocked else Color("#cbd5e1")
		sb_sh.set_border_width_all(1.5)
		sb_sh.set_corner_radius_all(6)
		sb_sh.set_content_margin_all(4)
		sh_panel.add_theme_stylebox_override("panel", sb_sh)
		
		var sh_hb = HBoxContainer.new()
		var sh_title = Label.new()
		sh_title.text = s_data["stage_name"] + (" (Terbuka)" if stage_is_unlocked else " 🔒 (Terkunci)")
		sh_title.add_theme_font_override("font", font_black)
		sh_title.add_theme_font_size_override("font_size", 11)
		sh_title.add_theme_color_override("font_color", Color("#9a3412") if stage_is_unlocked else Color("#64748b"))
		sh_hb.add_child(sh_title)
		
		var sh_sp = Control.new()
		sh_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh_hb.add_child(sh_sp)
		
		var sh_stars_cnt = pd.get_stage_stars(s_num) if pd else 0
		var max_st_stars = s_data["levels"].size() * 3
		var sh_st_lbl = Label.new()
		sh_st_lbl.text = "⭐ %d / %d" % [sh_stars_cnt, max_st_stars]
		sh_st_lbl.add_theme_font_override("font", font_black)
		sh_st_lbl.add_theme_font_size_override("font_size", 11)
		sh_st_lbl.add_theme_color_override("font_color", Color("#ea580c") if stage_is_unlocked else Color("#94a3b8"))
		sh_hb.add_child(sh_st_lbl)
		sh_panel.add_child(sh_hb)
		list_container.add_child(sh_panel)
		
		# Level Rows
		for lvl in s_data["levels"]:
			var l_num = int(lvl["num"])
			var is_lvl_unlocked = stage_is_unlocked and (l_num <= unl_lvl)
			var stars = pd.get_level_stars(s_num, l_num) if pd else 0
			
			var row = _create_level_rank_card(s_num, lvl, is_lvl_unlocked, stars)
			list_container.add_child(row)
			
	# -------------------------------------------------------------
	# 3. BOTTOM STICKY BAR: Informasi Offline & Total Bintang
	# -------------------------------------------------------------
	_render_player_sticky_row(player_stars, max_stars)

func _create_level_rank_card(stage_num: int, lvl: Dictionary, is_unlocked: bool, stars: int) -> Control:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	
	var sb = StyleBoxFlat.new()
	if not is_unlocked:
		sb.bg_color = Color("#f8fafc")
		sb.border_color = Color("#e2e8f0")
	elif stars >= 3:
		sb.bg_color = Color("#fefce8")
		sb.border_color = Color("#fde047")
	elif stars == 2:
		sb.bg_color = Color("#f8fafc")
		sb.border_color = Color("#cbd5e1")
	elif stars == 1:
		sb.bg_color = Color("#fff7ed")
		sb.border_color = Color("#ffedd5")
	else:
		sb.bg_color = Color("#ffffff")
		sb.border_color = Color("#fed7aa")
		
	sb.set_border_width_all(1.5)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	row.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	row.add_child(hb)
	
	# 1. Badge Nomor Level
	var tag_pill = PanelContainer.new()
	tag_pill.custom_minimum_size = Vector2(40, 32)
	var sb_tag = StyleBoxFlat.new()
	if not is_unlocked:
		sb_tag.bg_color = Color("#e2e8f0")
		sb_tag.border_color = Color("#cbd5e1")
	elif stars >= 3:
		sb_tag.bg_color = Color("#fde047")
		sb_tag.border_color = Color("#ca8a04")
	else:
		sb_tag.bg_color = Color("#fed7aa")
		sb_tag.border_color = Color("#f97316")
	sb_tag.set_border_width_all(1.5)
	sb_tag.set_corner_radius_all(8)
	tag_pill.add_theme_stylebox_override("panel", sb_tag)
	
	var tag_lbl = Label.new()
	tag_lbl.text = lvl["tag"]
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_override("font", font_black)
	tag_lbl.add_theme_font_size_override("font_size", 12)
	tag_lbl.add_theme_color_override("font_color", Color("#4a2e2b") if is_unlocked else Color("#94a3b8"))
	tag_pill.add_child(tag_lbl)
	hb.add_child(tag_pill)
	
	# 2. Level Info (Title & Target)
	var vb_info = VBoxContainer.new()
	vb_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb_info.alignment = BoxContainer.ALIGNMENT_CENTER
	vb_info.add_theme_constant_override("separation", 1)
	
	var title_l = Label.new()
	title_l.text = lvl["name"]
	title_l.add_theme_font_override("font", font_black)
	title_l.add_theme_font_size_override("font_size", 12)
	title_l.add_theme_color_override("font_color", Color("#2b1810") if is_unlocked else Color("#94a3b8"))
	vb_info.add_child(title_l)
	
	var desc_l = Label.new()
	desc_l.text = lvl["desc"]
	desc_l.add_theme_font_override("font", font_semibold)
	desc_l.add_theme_font_size_override("font_size", 10)
	desc_l.add_theme_color_override("font_color", Color("#78350f") if is_unlocked else Color("#cbd5e1"))
	vb_info.add_child(desc_l)
	hb.add_child(vb_info)
	
	# 3. Rank Label & Stars
	var right_hb = HBoxContainer.new()
	right_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	right_hb.add_theme_constant_override("separation", 8)
	
	# Rank Badge Text
	var rank_badge = Label.new()
	rank_badge.add_theme_font_override("font", font_black)
	rank_badge.add_theme_font_size_override("font_size", 11)
	
	if not is_unlocked:
		rank_badge.text = "🔒 TERKUNCI"
		rank_badge.add_theme_color_override("font_color", Color("#94a3b8"))
	elif stars >= 3:
		rank_badge.text = "🥇 SEMPURNA"
		rank_badge.add_theme_color_override("font_color", Color("#ca8a04"))
	elif stars == 2:
		rank_badge.text = "🥈 BAIK"
		rank_badge.add_theme_color_override("font_color", Color("#475569"))
	elif stars == 1:
		rank_badge.text = "🥉 CUKUP"
		rank_badge.add_theme_color_override("font_color", Color("#ea580c"))
	else:
		rank_badge.text = "⏳ BELUM DIKERJAKAN"
		rank_badge.add_theme_color_override("font_color", Color("#059669"))
	right_hb.add_child(rank_badge)
	
	# 3 Star Icons
	var stars_hb = HBoxContainer.new()
	stars_hb.add_theme_constant_override("separation", 3)
	for i in range(3):
		var star_icon = TextureRect.new()
		star_icon.texture = tex_star_gold
		star_icon.custom_minimum_size = Vector2(16, 16)
		star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not is_unlocked or (i + 1 > stars):
			star_icon.modulate = Color(0.7, 0.7, 0.7, 0.3)
		stars_hb.add_child(star_icon)
	right_hb.add_child(stars_hb)
	
	hb.add_child(right_hb)
	return row

func _render_player_sticky_row(player_stars: int, max_stars: int) -> void:
	for c in player_row_container.get_children():
		c.queue_free()
		
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#fff7ed")
	sb.border_color = Color("#ea580c")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	player_row_container.add_theme_stylebox_override("panel", sb)
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	player_row_container.add_child(hb)
	
	var save_icon = Label.new()
	save_icon.text = "💾"
	save_icon.add_theme_font_size_override("font_size", 16)
	hb.add_child(save_icon)
	
	var save_lbl = Label.new()
	save_lbl.text = "Ini catatan performamu sendiri: bintang terbaik tiap level, tersimpan otomatis di perangkat ini."
	save_lbl.add_theme_font_override("font", font_bold)
	save_lbl.add_theme_font_size_override("font_size", 12)
	save_lbl.add_theme_color_override("font_color", Color("#7c2d12"))
	save_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(save_lbl)
	
	var star_badge = HBoxContainer.new()
	star_badge.add_theme_constant_override("separation", 6)
	
	var s_ic = TextureRect.new()
	s_ic.texture = tex_star_gold
	s_ic.custom_minimum_size = Vector2(20, 20)
	s_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_badge.add_child(s_ic)
	
	var s_txt = Label.new()
	var pct = int((float(player_stars) / float(max_stars)) * 100.0) if max_stars > 0 else 0
	s_txt.text = "%d / %d (%d%%)" % [player_stars, max_stars, pct]
	s_txt.add_theme_font_override("font", font_black)
	s_txt.add_theme_font_size_override("font_size", 14)
	s_txt.add_theme_color_override("font_color", Color("#ea580c"))
	s_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_badge.add_child(s_txt)
	
	hb.add_child(star_badge)

func _on_reset_progress_pressed() -> void:
	var pd = get_node_or_null("/root/PlayerData")
	if pd and pd.has_method("reset_progress_to_default"):
		pd.reset_progress_to_default()
		_render_leaderboard()

func open() -> void:
	visible = true
	modulate.a = 0.0
	card_wrapper.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.2)
	_render_leaderboard()

func close() -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_property(card_wrapper, "scale", Vector2(0.95, 0.95), 0.15)
	tw.chain().tween_callback(func():
		visible = false
		closed.emit()
	)
