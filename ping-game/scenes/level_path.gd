extends Control

# Nodes
@onready var background: TextureRect = %Background
@onready var door_arch: TextureButton = %DoorArch
@onready var potted_plant: TextureButton = %PottedPlant
@onready var path_line: Line2D = %PathLine
@onready var desks_container: Control = %DesksContainer
@onready var desk_nodes: Array[Control] = [%Desk1, %Desk2, %Desk3]
@onready var character_mascot: TextureRect = %CharacterMascot

@onready var back_btn: TextureButton = %BackButton
@onready var stage_card: PanelContainer = %StageCard
@onready var level_progress_badge: PanelContainer = %LevelProgressBadge

@onready var level_modal: Control = %LevelModal
@onready var modal_backdrop: ColorRect = %Backdrop
@onready var modal_card: PanelContainer = %CardWrapper
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

# Preloaded Assets
var tex_router: Texture2D = preload("res://art/assets/PING! Assets/Character/main-char-router.png")
var tex_star_gold: Texture2D = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_star_gray: Texture2D = preload("res://art/ui-ux/levelpath/star_gray.png")
var tex_alert: Texture2D = preload("res://art/ui-ux/levelpath/crisp_alert.png")
var tex_desk: Texture2D = preload("res://art/ui-ux/levelpath/desk_station_new.png")

var font_black: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold: Font = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

# Stage data
var current_stage: int = 1
var selected_level_index: int = 0
var current_char_desk_idx: int = 0
var is_walking: bool = false
var walk_anim_timer: float = 0.0
var walk_frames: Array[Texture2D] = []
var step_timer: float = 0.0
var step_toggle: bool = false
var footstep_player: AudioStreamPlayer = null
var time_passed: float = 0.0
var active_alert_node: TextureRect = null
var char_tween: Tween
var modal_tween: Tween
var toast_tween: Tween

# UI references built at runtime
var stage_title_label: Label
var stage_subtitle_label: Label
var level_fraction_label: Label
var toast_label: Label

# Modal references
var modal_stage_tag: Label
var modal_level_title: Label
var modal_desc_label: Label
var modal_target_label: Label
var modal_stars_row: HBoxContainer
var modal_play_btn: Button
var modal_close_btn: Button

# Desk sub-nodes references: Array of Dictionaries
var desk_data_nodes: Array[Dictionary] = []

var stages_info: Dictionary = {
	1: {
		"title": "STAGE 1",
		"subtitle": "Physical & Data Link",
		"bg": preload("res://art/ui-ux/levelpath/bg_stage1.png"),
		"levels": [
			{
				"num": 1,
				"tag": "1.1",
				"name": "Kabel Straight vs Cross",
				"desc": "Fokus pada infrastruktur fisik. Pemain belajar membedakan kabel Straight dan Cross untuk menghubungkan perangkat jaringan yang tepat.",
				"target": "Identifikasi perbedaan kabel Straight dan Cross",
				"char_offset": Vector2(-55, 35)
			},
			{
				"num": 2,
				"tag": "1.2",
				"name": "Perakitan Pin TIA/EIA 568A/B",
				"desc": "Merakit urutan pin warna standar TIA/EIA 568A/B dengan batasan waktu untuk memastikan kualitas transmisi data.",
				"target": "Rakit 8 pin warna kabel standar TIA/EIA tepat waktu",
				"char_offset": Vector2(-55, 35)
			},
			{
				"num": 3,
				"tag": "1.3",
				"name": "Switch vs Hub (Anti-Collision)",
				"desc": "Memilih penggunaan Switch ketimbang Hub untuk merutekan paket data Unicast agar terhindar dari Collision pada jaringan.",
				"target": "Rutekan paket Unicast via Switch tanpa collision",
				"char_offset": Vector2(-55, 35)
			}
		]
	},
	2: {
		"title": "STAGE 2",
		"subtitle": "Network & Addressing",
		"bg": preload("res://art/ui-ux/levelpath/bg_stage2.png"),
		"levels": [
			{
				"num": 1,
				"tag": "2.1",
				"name": "Klasifikasi Kelas IPv4",
				"desc": "Fokus pada pemahaman IP Address. Pemain menyortir masuknya alamat IPv4 ke kelas A, B, atau C secara akurat.",
				"target": "Sortir paket alamat IPv4 ke kelas A, B, atau C",
				"char_offset": Vector2(-55, 35)
			},
			{
				"num": 2,
				"tag": "2.2",
				"name": "Firewall Manual: IP Publik vs Privat",
				"desc": "Bertindak sebagai Firewall manual untuk memblokir IP Publik berbahaya dan mengizinkan aliran IP Privat aman.",
				"target": "Blokir IP Publik berbahaya & izinkan IP Privat",
				"char_offset": Vector2(-55, 35)
			},
			{
				"num": 3,
				"tag": "2.3",
				"name": "Protokol ARP: Request & Reply",
				"desc": "Mengawal langsung perjalanan amplop bersayap (ARP-Request) dan menuntun balasan MAC-Address (ARP-Reply) ke perangkat tujuan.",
				"target": "Kawal ARP-Request dan tuntun balasan ARP-Reply",
				"char_offset": Vector2(-55, 35)
			}
		]
	},
	3: {
		"title": "STAGE 3",
		"subtitle": "Routing & Subnetting",
		"bg": preload("res://art/ui-ux/levelpath/bg_stage3.png"),
		"levels": [
			{
				"num": 1,
				"name": "Prefix CIDR & Subnet Mask",
				"desc": "Hitung jumlah host valid dan network range menggunakan notasi CIDR /24 hingga /30 secara efisien.",
				"target": "Hitung alokasi IP efisien untuk 3 divisi lab",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 2,
				"name": "Tabel Routing Statis",
				"desc": "Konfigurasi rute statis (next-hop IP) agar router dapat meneruskan paket ke subnet tujuan tanpa loop.",
				"target": "Bangun rute jalur koneksi antar switch & router",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 3,
				"name": "Simulasi Pengiriman Paket (PING)",
				"desc": "Kirim paket ICMP echo request dan analisis latency (RTT) serta hop count antar router.",
				"target": "Pastikan status: PING SUCCESS! (0% packet loss)",
				"char_offset": Vector2(-50, 40)
			}
		]
	},
	4: {
		"title": "STAGE 4",
		"subtitle": "Topology & Infrastructure",
		"bg": preload("res://art/ui-ux/levelpath/bg_stage4.png"),
		"levels": [
			{
				"num": 1,
				"name": "Topologi Jaringan (Star vs Mesh)",
				"desc": "Bandingkan kelebihan topologi Star dengan switch pusat versus redundant Mesh topology tahan kendala.",
				"target": "Rancang topologi tahan toleransi kegagalan link",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 2,
				"name": "VLAN & Switch Port Security",
				"desc": "Pisahkan traffic jaringan per departemen secara logis menggunakan 802.1Q Virtual LAN.",
				"target": "Atur Access Port dan Trunk Port pada switch",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 3,
				"name": "Backbone Fiber Optik & SFP",
				"desc": "Gunakan kabel serat optik untuk transmisi data kecepatan gigabit antar gedung kampus.",
				"target": "Pasang modul transceiver SFP dan verifikasi link",
				"char_offset": Vector2(-50, 40)
			}
		]
	},
	5: {
		"title": "STAGE 5",
		"subtitle": "Standardisasi OSI & Transport",
		"bg": preload("res://art/ui-ux/levelpath/bg_stage5.png"),
		"levels": [
			{
				"num": 1,
				"name": "Model 7 Lapisan OSI Layer",
				"desc": "Petakan protokol dari Physical, Data Link, Network, Transport, Session, Presentation, hingga Application.",
				"target": "Cocokkan protokol dengan lapisan yang tepat",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 2,
				"name": "Protokol TCP vs UDP",
				"desc": "Pahami perbedaan handshaking 3 arah (SYN-ACK) TCP dengan transmisi cepat UDP tanpa koneksi.",
				"target": "Pilih protokol yang sesuai untuk Web, Video, dan DNS",
				"char_offset": Vector2(-50, 40)
			},
			{
				"num": 3,
				"name": "Troubleshooting & Analisis Paket",
				"desc": "Inspeksi paket header, temukan paket korup, dan selesaikan tantangan akhir master teknisi PING!",
				"target": "Dapatkan sertifikasi Teknisi Jaringan Handal!",
				"char_offset": Vector2(-50, 40)
			}
		]
	}
}

func _ready() -> void:
	current_stage = PlayerData.current_stage if PlayerData else 1
	if current_stage < 1 or current_stage > 5:
		current_stage = 1
		
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.volume_db = -9.0
	add_child(footstep_player)
	
	_load_walk_frames()
	if walk_frames.size() > 0:
		character_mascot.texture = walk_frames[0]
	else:
		character_mascot.texture = tex_router
	
	_build_header_ui()
	_build_desks()
	_build_modal_ui()
	_build_toast_ui()
	_setup_easter_eggs()
	
	load_stage(current_stage)
	
	# Responsive layout centering
	_reposition_responsive()
	get_viewport().size_changed.connect(_reposition_responsive)
	
	# Screenshot helper for visual testing
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--screenshot-levelpath" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/levelpath_render.png")
		get_tree().quit()
		
	if "--screenshot-levelmodal" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		open_level_modal(1, 1)
		await get_tree().create_timer(0.35).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/levelmodal_render.png")
		get_tree().quit()
		
	if "--screenshot-stage2" in all_args:
		await get_tree().process_frame
		load_stage(2)
		await get_tree().create_timer(0.3).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/stage2_render.png")
		get_tree().quit()

	if "--screenshot-walk" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		# Simulate clicking desk 2 (1.2) so it starts walking
		_on_desk_clicked(1)
		await get_tree().create_timer(0.45).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/walk_render.png")
		get_tree().quit()

	if "--screenshot-walk-arrive" in all_args:
		await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		_on_desk_clicked(1)
		await get_tree().create_timer(1.8).timeout
		var img = get_viewport().get_texture().get_image()
		img.save_png("art/walk_arrive_render.png")
		get_tree().quit()

func _load_walk_frames() -> void:
	walk_frames.clear()
	for i in range(1, 33):
		var path = "res://art/assets/PING! Assets/Sprite animation/router walk/%d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex:
				walk_frames.append(tex)

func _process(delta: float) -> void:
	time_passed += delta
	# Bobbing animation for alert bubble
	if active_alert_node and is_instance_valid(active_alert_node):
		active_alert_node.position.y = -10.0 + sin(time_passed * 5.0) * 5.0
		active_alert_node.scale = Vector2.ONE * (1.0 + sin(time_passed * 3.5) * 0.06)
		
	if is_walking:
		if walk_frames.size() > 0:
			walk_anim_timer += delta * 24.0
			var frame_idx = int(walk_anim_timer) % walk_frames.size()
			character_mascot.texture = walk_frames[frame_idx]
			
		step_timer += delta
		if step_timer >= 0.16:
			step_timer = 0.0
			step_toggle = !step_toggle
			_play_step_sfx(step_toggle)
	else:
		# Subtle breathing bob on character mascot when idle
		if character_mascot:
			character_mascot.scale.y = 1.0 + sin(time_passed * 3.0) * 0.04

func load_stage(stage_num: int) -> void:
	current_stage = clamp(stage_num, 1, 5)
	if PlayerData:
		PlayerData.current_stage = current_stage
		
	var s_data = stages_info[current_stage]
	
	# Update background
	background.texture = s_data["bg"]
	
	# Update header
	stage_title_label.text = s_data["title"]
	stage_subtitle_label.text = s_data["subtitle"]
	
	var unlocked_lvl = PlayerData.get_stage_unlocked_level(current_stage) if PlayerData else 1
	level_fraction_label.text = "%d.%d / %d.3" % [current_stage, unlocked_lvl, current_stage]
	
	# Update 3 Desks
	active_alert_node = null
	for i in range(3):
		var desk_dict = desk_data_nodes[i]
		var lvl_num = i + 1
		var is_unlocked = (lvl_num <= unlocked_lvl)
		var stars_count = PlayerData.get_level_stars(current_stage, lvl_num) if PlayerData else 0
		
		# Number label: Stage.Level e.g. 1.1, 1.2, 1.3 or 2.1, 2.2, 2.3
		desk_dict["num_label"].text = "%d.%d" % [current_stage, lvl_num]
		
		# Stars
		for s in range(3):
			var star_tex_rect = desk_dict["stars"][s]
			star_tex_rect.texture = tex_star_gold if (s < stars_count) else tex_star_gray
			
		# Lock state
		if is_unlocked:
			desk_dict["root"].modulate = Color(1.0, 1.0, 1.0, 1.0)
			desk_dict["lock_badge"].visible = false
			desk_dict["num_badge"].visible = true
			
			# Exclamation alert on the highest unlocked level that player hasn't 3-starred
			if lvl_num == unlocked_lvl and stars_count < 3 and active_alert_node == null:
				desk_dict["alert"].visible = true
				active_alert_node = desk_dict["alert"]
			else:
				desk_dict["alert"].visible = false
		else:
			desk_dict["root"].modulate = Color(0.72, 0.72, 0.75, 0.9)
			desk_dict["lock_badge"].visible = true
			desk_dict["num_badge"].visible = false
			desk_dict["alert"].visible = false

	# Position character at the current active level desk
	var target_desk_idx = clamp(unlocked_lvl - 1, 0, 2)
	_move_character_to_desk(target_desk_idx, false)

func _move_character_to_desk(desk_idx: int, animate: bool = false) -> void:
	if desk_idx < 0 or desk_idx >= desk_nodes.size():
		return
	current_char_desk_idx = desk_idx
	selected_level_index = desk_idx
	var desk_node = desk_nodes[desk_idx]
	var s_data = stages_info[current_stage]
	var char_offset = s_data["levels"][desk_idx].get("char_offset", Vector2(-50, 40))
	var target_pos = desk_node.position + char_offset
	
	if char_tween and char_tween.is_valid():
		char_tween.kill()
		
	is_walking = false
	if walk_frames.size() > 0:
		character_mascot.texture = walk_frames[0]
	else:
		character_mascot.texture = tex_router
		
	if animate:
		play_synth_hop()
		char_tween = create_tween().set_parallel(true)
		char_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		char_tween.tween_property(character_mascot, "position", target_pos, 0.35)
		
		# Cute vertical hop arc
		var hop_tween = create_tween()
		hop_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hop_tween.tween_property(character_mascot, "scale", Vector2(1.2, 0.8), 0.08)
		hop_tween.chain().tween_property(character_mascot, "scale", Vector2(0.9, 1.15), 0.15)
		hop_tween.chain().tween_property(character_mascot, "scale", Vector2(1.0, 1.0), 0.12)
	else:
		character_mascot.position = target_pos
		character_mascot.scale = Vector2(1.0, 1.0)

func _walk_character_to_desk(target_desk_idx: int, on_arrived: Callable = Callable()) -> void:
	if is_walking:
		return
	if target_desk_idx == current_char_desk_idx:
		if on_arrived.is_valid():
			on_arrived.call()
		return
		
	var start_idx = current_char_desk_idx
	var waypoints: Array[int] = []
	
	# Determine intermediate waypoints along the level path
	if abs(target_desk_idx - start_idx) == 2:
		# Always pass through desk 1 when traveling between 0 and 2
		waypoints.append(1)
		waypoints.append(target_desk_idx)
	else:
		waypoints.append(target_desk_idx)
		
	is_walking = true
	walk_anim_timer = 0.0
	step_timer = 0.0
	
	if char_tween and char_tween.is_valid():
		char_tween.kill()
		
	char_tween = create_tween()
	var s_data = stages_info[current_stage]
	var prev_pos = desk_nodes[start_idx].position + s_data["levels"][start_idx].get("char_offset", Vector2(-50, 40))
	
	for wp_idx in waypoints:
		var desk_node = desk_nodes[wp_idx]
		var char_offset = s_data["levels"][wp_idx].get("char_offset", Vector2(-50, 40))
		var wp_target_pos = desk_node.position + char_offset
		
		var moving_right = (wp_target_pos.x >= prev_pos.x)
		var flip_dir = 1.0 if moving_right else -1.0
		var dist = prev_pos.distance_to(wp_target_pos)
		var seg_duration = clamp(dist / 360.0, 0.45, 1.4)
		
		# Set facing direction at start of this segment
		char_tween.tween_callback((func(d: float):
			character_mascot.scale.x = d
		).bind(flip_dir))
		
		# Move along path to waypoint
		char_tween.tween_property(character_mascot, "position", wp_target_pos, seg_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		prev_pos = wp_target_pos
		
	# On complete traversal and arrival
	char_tween.tween_callback(func():
		is_walking = false
		current_char_desk_idx = target_desk_idx
		selected_level_index = target_desk_idx
		if walk_frames.size() > 0:
			character_mascot.texture = walk_frames[0]
		character_mascot.scale = Vector2(1.0, 1.0)
		
		# Celebration bounce & arrival chime
		_play_sweep(659.25, 880.0, 0.12, 0.18)
		var arr_tween = create_tween()
		arr_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		arr_tween.tween_property(character_mascot, "scale", Vector2(1.15, 0.85), 0.08)
		arr_tween.chain().tween_property(character_mascot, "scale", Vector2(0.9, 1.15), 0.12)
		arr_tween.chain().tween_property(character_mascot, "scale", Vector2(1.0, 1.0), 0.1)
		
		# User requirement: "karakter harus jalan dulu baru ada notifnya"
		if on_arrived.is_valid():
			on_arrived.call()
	)

func _on_desk_clicked(desk_idx: int) -> void:
	if is_walking:
		return
		
	var lvl_num = desk_idx + 1
	var unlocked_lvl = PlayerData.get_stage_unlocked_level(current_stage) if PlayerData else 1
	
	if lvl_num > unlocked_lvl:
		play_synth_lock()
		var desk_node = desk_nodes[desk_idx]
		# Shake animation
		var orig_x = desk_node.position.x
		var shake = create_tween()
		shake.tween_property(desk_node, "position:x", orig_x - 8.0, 0.04)
		shake.chain().tween_property(desk_node, "position:x", orig_x + 8.0, 0.06)
		shake.chain().tween_property(desk_node, "position:x", orig_x - 4.0, 0.05)
		shake.chain().tween_property(desk_node, "position:x", orig_x, 0.04)
		show_toast("Level %d.%d masih terkunci! Selesaikan Level %d.%d terlebih dahulu." % [current_stage, lvl_num, current_stage, lvl_num - 1])
		return
		
	# Unlocked desk!
	if current_char_desk_idx == desk_idx:
		# Already here! Quick hop and open modal
		selected_level_index = desk_idx
		play_synth_hop()
		var hop = create_tween()
		hop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hop.tween_property(character_mascot, "scale", Vector2(1.15, 0.85), 0.08)
		hop.chain().tween_property(character_mascot, "scale", Vector2(0.9, 1.15), 0.12)
		hop.chain().tween_property(character_mascot, "scale", Vector2(1.0, 1.0), 0.1)
		hop.chain().tween_callback(func(): open_level_modal(current_stage, lvl_num))
	else:
		# Walk to desk first, and ONLY open modal once arrived!
		_walk_character_to_desk(desk_idx, func():
			open_level_modal(current_stage, lvl_num)
		)

func open_level_modal(stage_num: int, level_num: int) -> void:
	play_synth_chime([523.25, 659.25, 783.99], 0.08)
	var lvl_data = stages_info[stage_num]["levels"][level_num - 1]
	
	modal_stage_tag.text = "STAGE %d • LEVEL %d.%d" % [stage_num, stage_num, level_num]
	modal_level_title.text = lvl_data["name"]
	modal_desc_label.text = lvl_data["desc"]
	modal_target_label.text = "🎯 " + lvl_data["target"]
	
	var stars_count = PlayerData.get_level_stars(stage_num, level_num) if PlayerData else 0
	for i in range(3):
		var star_img = modal_stars_row.get_child(i) as TextureRect
		star_img.texture = tex_star_gold if (i < stars_count) else tex_star_gray
		
	level_modal.visible = true
	modal_backdrop.modulate.a = 0.0
	modal_card.modulate.a = 0.0
	modal_card.scale = Vector2(0.65, 0.65)
	
	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()
	modal_tween = create_tween().set_parallel(true)
	modal_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	modal_tween.tween_property(modal_backdrop, "modulate:a", 1.0, 0.2)
	modal_tween.tween_property(modal_card, "modulate:a", 1.0, 0.2)
	modal_tween.tween_property(modal_card, "scale", Vector2.ONE, 0.28)

func close_level_modal() -> void:
	play_synth_tone(440.0, 0.1)
	if modal_tween and modal_tween.is_valid():
		modal_tween.kill()
	modal_tween = create_tween().set_parallel(true)
	modal_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	modal_tween.tween_property(modal_backdrop, "modulate:a", 0.0, 0.16)
	modal_tween.tween_property(modal_card, "modulate:a", 0.0, 0.16)
	modal_tween.tween_property(modal_card, "scale", Vector2(0.7, 0.7), 0.18)
	modal_tween.chain().tween_callback(func(): level_modal.visible = false)

func _start_selected_level() -> void:
	play_synth_chime([523.25, 659.25, 1046.5], 0.1)
	close_level_modal()
	show_toast("Memulai Stage %d Level %d.%d: Menyiapkan simulasi jaringan..." % [current_stage, current_stage, selected_level_index + 1])

# --- UI BUILDERS ---

func _build_header_ui() -> void:
	# Back Button
	back_btn.pressed.connect(func():
		play_synth_tone(493.88, 0.1)
		get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
	)
	_setup_hover_scale(back_btn, 1.1)
	
	# Stage Card
	var sb_stage = StyleBoxFlat.new()
	sb_stage.bg_color = Color("#fdf4eb")
	sb_stage.border_color = Color("#4a2e2b")
	sb_stage.set_border_width_all(3)
	sb_stage.set_corner_radius_all(14)
	sb_stage.shadow_color = Color(0, 0, 0, 0.15)
	sb_stage.shadow_size = 3
	sb_stage.shadow_offset = Vector2(0, 2)
	stage_card.add_theme_stylebox_override("panel", sb_stage)
	
	var h_stage = HBoxContainer.new()
	h_stage.add_theme_constant_override("separation", 6)
	stage_card.add_child(h_stage)
	
	var btn_prev_stage = Button.new()
	btn_prev_stage.text = "◀"
	btn_prev_stage.flat = true
	btn_prev_stage.add_theme_color_override("font_color", Color("#4a2e2b"))
	btn_prev_stage.add_theme_font_override("font", font_black)
	btn_prev_stage.add_theme_font_size_override("font_size", 14)
	btn_prev_stage.custom_minimum_size = Vector2(24, 0)
	btn_prev_stage.pressed.connect(func():
		if current_stage > 1:
			play_synth_tone(587.33, 0.1)
			load_stage(current_stage - 1)
	)
	h_stage.add_child(btn_prev_stage)
	
	var v_box = VBoxContainer.new()
	v_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_theme_constant_override("separation", -2)
	h_stage.add_child(v_box)
	
	stage_title_label = Label.new()
	stage_title_label.text = "STAGE 1"
	stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title_label.add_theme_font_override("font", font_black)
	stage_title_label.add_theme_font_size_override("font_size", 16)
	stage_title_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	v_box.add_child(stage_title_label)
	
	stage_subtitle_label = Label.new()
	stage_subtitle_label.text = "Physical & Data Link"
	stage_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_subtitle_label.add_theme_font_override("font", font_extrabold)
	stage_subtitle_label.add_theme_font_size_override("font_size", 12)
	stage_subtitle_label.add_theme_color_override("font_color", Color("#7c5843"))
	v_box.add_child(stage_subtitle_label)
	
	var btn_next_stage = Button.new()
	btn_next_stage.text = "▶"
	btn_next_stage.flat = true
	btn_next_stage.add_theme_color_override("font_color", Color("#4a2e2b"))
	btn_next_stage.add_theme_font_override("font", font_black)
	btn_next_stage.add_theme_font_size_override("font_size", 14)
	btn_next_stage.custom_minimum_size = Vector2(24, 0)
	btn_next_stage.pressed.connect(func():
		if current_stage < 5:
			play_synth_tone(659.25, 0.1)
			load_stage(current_stage + 1)
	)
	h_stage.add_child(btn_next_stage)
	
	# Level Progress Badge
	var sb_lvl = StyleBoxFlat.new()
	sb_lvl.bg_color = Color("#e0f2fe")
	sb_lvl.border_color = Color("#0284c7")
	sb_lvl.set_border_width_all(3)
	sb_lvl.set_corner_radius_all(14)
	sb_lvl.shadow_color = Color(0, 0, 0, 0.15)
	sb_lvl.shadow_size = 3
	sb_lvl.shadow_offset = Vector2(0, 2)
	level_progress_badge.add_theme_stylebox_override("panel", sb_lvl)
	
	var v_lvl = VBoxContainer.new()
	v_lvl.alignment = BoxContainer.ALIGNMENT_CENTER
	v_lvl.add_theme_constant_override("separation", -2)
	level_progress_badge.add_child(v_lvl)
	
	var lvl_title = Label.new()
	lvl_title.text = "LEVEL"
	lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_title.add_theme_font_override("font", font_black)
	lvl_title.add_theme_font_size_override("font_size", 11)
	lvl_title.add_theme_color_override("font_color", Color("#0369a1"))
	v_lvl.add_child(lvl_title)
	
	level_fraction_label = Label.new()
	level_fraction_label.text = "1 / 3"
	level_fraction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_fraction_label.add_theme_font_override("font", font_black)
	level_fraction_label.add_theme_font_size_override("font_size", 17)
	level_fraction_label.add_theme_color_override("font_color", Color("#0284c7"))
	v_lvl.add_child(level_fraction_label)

func _build_desks() -> void:
	desk_data_nodes.clear()
	for i in range(3):
		var desk_node = desk_nodes[i]
		
		# Desk Button (clickable table with laptop)
		var desk_btn = TextureButton.new()
		desk_btn.texture_normal = tex_desk
		desk_btn.ignore_texture_size = true
		desk_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		desk_btn.size = Vector2(180, 126)
		desk_btn.pivot_offset = Vector2(90, 63)
		desk_node.add_child(desk_btn)
		
		var desk_idx = i
		desk_btn.pressed.connect(func(): _on_desk_clicked(desk_idx))
		_setup_hover_scale(desk_btn, 1.08)
		
		# Number Badge (Pill with Number "1.1", "1.2", "1.3" / "2.1", etc.)
		var num_badge = PanelContainer.new()
		num_badge.size = Vector2(48, 30)
		num_badge.position = Vector2(66, 26)
		num_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb_num = StyleBoxFlat.new()
		sb_num.bg_color = Color("#ea580c")
		sb_num.border_color = Color("#ffffff")
		sb_num.set_border_width_all(2)
		sb_num.set_corner_radius_all(15)
		sb_num.shadow_color = Color(0, 0, 0, 0.25)
		sb_num.shadow_size = 4
		sb_num.shadow_offset = Vector2(0, 2)
		num_badge.add_theme_stylebox_override("panel", sb_num)
		
		var num_lbl = Label.new()
		num_lbl.text = "%d.%d" % [current_stage, i + 1]
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_override("font", font_black)
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", Color("#ffffff"))
		num_badge.add_child(num_lbl)
		desk_node.add_child(num_badge)
		
		# Lock Badge (shown when level is locked)
		var lock_badge = PanelContainer.new()
		lock_badge.size = Vector2(48, 30)
		lock_badge.position = Vector2(66, 26)
		lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_badge.visible = false
		
		var sb_lock = StyleBoxFlat.new()
		sb_lock.bg_color = Color("#475569")
		sb_lock.border_color = Color("#94a3b8")
		sb_lock.set_border_width_all(2)
		sb_lock.set_corner_radius_all(15)
		lock_badge.add_theme_stylebox_override("panel", sb_lock)
		
		var lock_lbl = Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 15)
		lock_badge.add_child(lock_lbl)
		desk_node.add_child(lock_badge)
		
		# Floating Exclamation Alert Bubble
		var alert_rect = TextureRect.new()
		alert_rect.texture = tex_alert
		alert_rect.size = Vector2(44, 44)
		alert_rect.position = Vector2(130, -12)
		alert_rect.pivot_offset = Vector2(22, 22)
		alert_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		alert_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		alert_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alert_rect.visible = false
		desk_node.add_child(alert_rect)
		
		# Stars Box (3 stars underneath table)
		var stars_row = HBoxContainer.new()
		stars_row.position = Vector2(45, 126)
		stars_row.size = Vector2(90, 22)
		stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_row.add_theme_constant_override("separation", 4)
		stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var stars_arr: Array[TextureRect] = []
		for s in range(3):
			var star_rect = TextureRect.new()
			star_rect.texture = tex_star_gray
			star_rect.custom_minimum_size = Vector2(20, 20)
			star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars_row.add_child(star_rect)
			stars_arr.append(star_rect)
		desk_node.add_child(stars_row)
		
		desk_data_nodes.append({
			"root": desk_node,
			"btn": desk_btn,
			"num_badge": num_badge,
			"num_label": num_lbl,
			"lock_badge": lock_badge,
			"alert": alert_rect,
			"stars": stars_arr
		})

func _build_modal_ui() -> void:
	modal_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_level_modal()
	)
	
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = Color("#fffdfa")
	sb_card.border_color = Color("#4a2e2b")
	sb_card.set_border_width_all(5)
	sb_card.set_corner_radius_all(24)
	sb_card.shadow_color = Color(0, 0, 0, 0.35)
	sb_card.shadow_size = 16
	sb_card.shadow_offset = Vector2(0, 8)
	modal_card.add_theme_stylebox_override("panel", sb_card)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal_card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Top Stage Tag
	modal_stage_tag = Label.new()
	modal_stage_tag.text = "STAGE 1 • LEVEL 1"
	modal_stage_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_stage_tag.add_theme_font_override("font", font_black)
	modal_stage_tag.add_theme_font_size_override("font_size", 14)
	modal_stage_tag.add_theme_color_override("font_color", Color("#ea580c"))
	vbox.add_child(modal_stage_tag)
	
	# Level Title
	modal_level_title = Label.new()
	modal_level_title.text = "Nama Level Misi"
	modal_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_level_title.add_theme_font_override("font", font_black)
	modal_level_title.add_theme_font_size_override("font_size", 22)
	modal_level_title.add_theme_color_override("font_color", Color("#2d1810"))
	vbox.add_child(modal_level_title)
	
	# Stars Row
	modal_stars_row = HBoxContainer.new()
	modal_stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_stars_row.add_theme_constant_override("separation", 8)
	for i in range(3):
		var star = TextureRect.new()
		star.texture = tex_star_gold
		star.custom_minimum_size = Vector2(36, 36)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		modal_stars_row.add_child(star)
	vbox.add_child(modal_stars_row)
	
	# Description Box
	var desc_box = PanelContainer.new()
	var sb_desc = StyleBoxFlat.new()
	sb_desc.bg_color = Color("#f8f4ec")
	sb_desc.set_corner_radius_all(12)
	sb_desc.content_margin_left = 16
	sb_desc.content_margin_top = 10
	sb_desc.content_margin_right = 16
	sb_desc.content_margin_bottom = 10
	desc_box.add_theme_stylebox_override("panel", sb_desc)
	
	var desc_vbox = VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 6)
	desc_box.add_child(desc_vbox)
	
	modal_desc_label = Label.new()
	modal_desc_label.text = "Deskripsi misi pembelajaran jaringan..."
	modal_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_desc_label.add_theme_font_override("font", font_semibold)
	modal_desc_label.add_theme_font_size_override("font_size", 13)
	modal_desc_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	desc_vbox.add_child(modal_desc_label)
	
	modal_target_label = Label.new()
	modal_target_label.text = "🎯 Target capaian materi"
	modal_target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_target_label.add_theme_font_override("font", font_bold)
	modal_target_label.add_theme_font_size_override("font_size", 13)
	modal_target_label.add_theme_color_override("font_color", Color("#047857"))
	desc_vbox.add_child(modal_target_label)
	
	vbox.add_child(desc_box)
	
	# Action Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	
	modal_close_btn = Button.new()
	modal_close_btn.text = "TUTUP"
	modal_close_btn.custom_minimum_size = Vector2(120, 48)
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color("#e2e8f0")
	sb_close.border_color = Color("#94a3b8")
	sb_close.set_border_width_all(2)
	sb_close.set_corner_radius_all(14)
	modal_close_btn.add_theme_stylebox_override("normal", sb_close)
	modal_close_btn.add_theme_font_override("font", font_extrabold)
	modal_close_btn.add_theme_font_size_override("font_size", 15)
	modal_close_btn.add_theme_color_override("font_color", Color("#475569"))
	modal_close_btn.pressed.connect(close_level_modal)
	_setup_hover_scale(modal_close_btn, 1.05)
	btn_row.add_child(modal_close_btn)
	
	modal_play_btn = Button.new()
	modal_play_btn.text = "▶  MULAI LEVEL"
	modal_play_btn.custom_minimum_size = Vector2(220, 48)
	var sb_play = StyleBoxFlat.new()
	sb_play.bg_color = Color("#ea580c")
	sb_play.border_color = Color("#9a3412")
	sb_play.set_border_width_all(2)
	sb_play.set_corner_radius_all(14)
	sb_play.shadow_color = Color(0, 0, 0, 0.25)
	sb_play.shadow_size = 4
	sb_play.shadow_offset = Vector2(0, 2)
	modal_play_btn.add_theme_stylebox_override("normal", sb_play)
	modal_play_btn.add_theme_font_override("font", font_black)
	modal_play_btn.add_theme_font_size_override("font_size", 16)
	modal_play_btn.add_theme_color_override("font_color", Color("#ffffff"))
	modal_play_btn.pressed.connect(_start_selected_level)
	_setup_hover_scale(modal_play_btn, 1.05)
	btn_row.add_child(modal_play_btn)

func _build_toast_ui() -> void:
	toast_panel.modulate.a = 0.0
	var sb_toast = StyleBoxFlat.new()
	sb_toast.bg_color = Color(0.15, 0.1, 0.12, 0.92)
	sb_toast.border_color = Color(0.85, 0.5, 0.35, 1.0)
	sb_toast.set_border_width_all(2)
	sb_toast.set_corner_radius_all(16)
	sb_toast.content_margin_left = 20
	sb_toast.content_margin_right = 20
	sb_toast.content_margin_top = 10
	sb_toast.content_margin_bottom = 10
	toast_panel.add_theme_stylebox_override("panel", sb_toast)
	
	toast_label = Label.new()
	toast_label.text = "Notifikasi game"
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	toast_panel.add_child(toast_label)

func show_toast(msg: String) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = msg
	toast_panel.pivot_offset = toast_panel.size / 2.0
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.15)
	toast_tween.parallel().tween_property(toast_panel, "scale", Vector2.ONE, 0.2)
	toast_tween.tween_interval(2.2)
	toast_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	toast_tween.parallel().tween_property(toast_panel, "scale", Vector2(0.9, 0.9), 0.25)

func _setup_easter_eggs() -> void:
	# Potted plant boing
	potted_plant.pressed.connect(func():
		play_synth_boing()
		var t = create_tween()
		t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(potted_plant, "scale", Vector2(1.22, 0.8), 0.08)
		t.chain().tween_property(potted_plant, "scale", Vector2(0.85, 1.2), 0.14)
		t.chain().tween_property(potted_plant, "scale", Vector2(1.08, 0.95), 0.12)
		t.chain().tween_property(potted_plant, "scale", Vector2.ONE, 0.1)
		show_toast("🌿 Tanaman hias lab jaringan dirawat dengan baik!")
	)
	_setup_hover_scale(potted_plant, 1.05)
	
	# Doorway arch interaction
	door_arch.pressed.connect(func():
		var unlocked_lvl = PlayerData.get_stage_unlocked_level(current_stage) if PlayerData else 1
		if unlocked_lvl >= 3 and PlayerData and PlayerData.get_level_stars(current_stage, 3) > 0:
			play_synth_chime([523.25, 659.25, 783.99, 1046.5], 0.1)
			if current_stage < 5:
				show_toast("🚪 Gerbang terbuka! Melanjutkan ke Stage %d..." % (current_stage + 1))
				load_stage(current_stage + 1)
			else:
				show_toast("🎉 Selamat! Kamu telah menamatkan semua Stage Jaringan!")
		else:
			play_synth_knock()
			var t = create_tween()
			t.tween_property(door_arch, "scale", Vector2(1.03, 1.03), 0.06)
			t.chain().tween_property(door_arch, "scale", Vector2.ONE, 0.1)
			show_toast("🚪 Gerbang terkunci! Selesaikan semua 3 level di stage ini untuk membuka pintu stage berikutnya.")
	)
	_setup_hover_scale(door_arch, 1.03)

func _setup_hover_scale(btn: Control, hover_scale: float = 1.08) -> void:
	btn.mouse_entered.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE * hover_scale, 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)
	btn.button_down.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE * 0.94, 0.08)
	)
	btn.button_up.connect(func():
		var target = Vector2.ONE * hover_scale if btn.is_hovered() else Vector2.ONE
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", target, 0.1)
	)

# --- PROCEDURAL SYNTH AUDIO ---

func play_synth_tone(freq: float, duration: float) -> void:
	if not audio_player: return
	_play_notes([freq], duration, 0.25)

func play_synth_chime(notes: Array, note_dur: float) -> void:
	if not audio_player: return
	_play_notes(notes, note_dur, 0.3)

func play_synth_hop() -> void:
	if not audio_player: return
	_play_sweep(350.0, 700.0, 0.14, 0.25)

func play_synth_boing() -> void:
	if not audio_player: return
	_play_sweep(200.0, 600.0, 0.18, 0.3)

func play_synth_knock() -> void:
	if not audio_player: return
	_play_notes([130.0, 110.0], 0.08, 0.35)

func play_synth_lock() -> void:
	if not audio_player: return
	_play_notes([220.0, 196.0], 0.12, 0.3)

func _play_notes(notes: Array, note_duration: float, volume: float) -> void:
	var sample_rate = 44100
	var total_dur = note_duration * notes.size()
	var num_samples = int(sample_rate * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t_total = float(i) / sample_rate
		var note_idx = clamp(int(t_total / note_duration), 0, notes.size() - 1)
		var freq = notes[note_idx]
		var t_note = fmod(t_total, note_duration)
		var envelope = exp(-t_note * 12.0)
		var sample_val = sin(t_note * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_sweep(start_f: float, end_f: float, duration: float, volume: float) -> void:
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = t / duration
		var freq = lerp(start_f, end_f, progress)
		var envelope = sin(progress * PI)
		var sample_val = sin(t * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_step_sfx(pitch_high: bool) -> void:
	if not footstep_player:
		return
	var sample_rate = 22050
	var duration = 0.035
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var freq = 680.0 if pitch_high else 540.0
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 90.0)
		var val = sin(t * freq * TAU) * envelope * 0.15
		var int_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
	stream.data = data
	footstep_player.stream = stream
	footstep_player.play()

func _reposition_responsive() -> void:
	var screen_w = get_viewport_rect().size.x
	var center_x = screen_w / 2.0
	
	# Center DoorArch horizontally
	if door_arch:
		door_arch.position = Vector2(center_x - 164.0, 46.0)
		door_arch.size = Vector2(328.0, 200.0)
		
	# Position Potted Plant next to DoorArch
	if potted_plant:
		potted_plant.position = Vector2(center_x + 180.0, 70.0)
		potted_plant.size = Vector2(120.0, 180.0)
		potted_plant.pivot_offset = Vector2(60, 150)
		
	# Reposition Desks spread across the center
	if desk_nodes.size() > 0 and desk_nodes[0]:
		desk_nodes[0].position = Vector2(center_x - 560.0, 460.0)
		desk_nodes[0].size = Vector2(180.0, 126.0)
	if desk_nodes.size() > 1 and desk_nodes[1]:
		desk_nodes[1].position = Vector2(center_x - 90.0, 460.0)
		desk_nodes[1].size = Vector2(180.0, 126.0)
	if desk_nodes.size() > 2 and desk_nodes[2]:
		desk_nodes[2].position = Vector2(center_x + 390.0, 210.0)
		desk_nodes[2].size = Vector2(180.0, 126.0)
		
	# Dynamic connecting path line
	if path_line and desk_nodes.size() >= 3:
		path_line.visible = true
		var p1 = desk_nodes[0].position + Vector2(90.0, 63.0)
		var p2 = desk_nodes[1].position + Vector2(90.0, 63.0)
		var p3 = desk_nodes[2].position + Vector2(90.0, 63.0)
		var p_door = door_arch.position + Vector2(164.0, 140.0)
		path_line.points = PackedVector2Array([p1, p2, p3, p_door])
		
	# Move mascot to active selected desk
	if not is_walking:
		_move_character_to_desk(selected_level_index, false)

