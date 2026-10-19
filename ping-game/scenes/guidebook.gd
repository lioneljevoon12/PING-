extends Control

signal closed

@onready var dim_backdrop: ColorRect = %DimBackdrop
@onready var book_wrapper: Control = %BookWrapper
@onready var close_btn: TextureButton = %CloseButton
@onready var prev_btn: TextureButton = %PrevButton
@onready var next_btn: TextureButton = %NextButton

# Left page nodes
@onready var left_title: Label = %LeftTitle
@onready var left_image: TextureRect = %LeftImage
@onready var left_text: RichTextLabel = %LeftText
@onready var page_num_left: Label = %PageNumLeft

# Right page nodes
@onready var right_title: Label = %RightTitle
@onready var right_text: RichTextLabel = %RightText
@onready var right_image: TextureRect = %RightImage
@onready var page_num_right: Label = %PageNumRight

# Flipping sheet animation nodes
@onready var flip_sheet: Control = %FlipSheet
@onready var sheet_shadow: ColorRect = %SheetShadow
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var current_spread: int = 0
var is_animating: bool = false
var book_tween: Tween

# Textures
var tex_rj45: Texture2D = preload("res://art/ui-ux/guidebook/rj45_graphic.png")
var tex_diagram: Texture2D = preload("res://art/ui-ux/guidebook/diagram_graphic.png")
var tex_crimping: Texture2D = preload("res://art/assets/PING! Assets/Objects/Crimping.png")
var tex_cable: Texture2D = preload("res://art/assets/PING! Assets/Objects/kabel utp.png")

var spreads: Array = [
	{
		"left": {
			"title": "URUTAN KABEL T568B",
			"image": tex_rj45,
			"image_height": 170,
			"desc": "[center][b]Standar Pengkabelan T568B:[/b][/center]\n[table=2]\n[cell]1. Putih-Oranye   [/cell][cell]5. Putih-Biru[/cell]\n[cell]2. Oranye         [/cell][cell]6. Hijau[/cell]\n[cell]3. Putih-Hijau    [/cell][cell]7. Putih-Cokelat[/cell]\n[cell]4. Biru           [/cell][cell]8. Cokelat[/cell]\n[/table]"
		},
		"right": {
			"title": "STRAIGHT VS CROSS",
			"image": tex_diagram,
			"image_height": 95,
			"body": "[b]Kabel Straight-Through:[/b]\nMenghubungkan dua perangkat [b]berbeda tipe[/b] (misal: Komputer ke Switch, Switch ke Router). Kedua ujung menggunakan susunan warna standar yang sama (568B).\n\n[b]Kabel Crossover:[/b]\nMenghubungkan dua perangkat [b]sejenis[/b] (misal: PC ke PC, Switch ke Switch). Menyilangkan pin kirim (TX) dan terima (RX)."
		}
	},
	{
		"left": {
			"title": "FUNGSI PIN RJ-45",
			"image": tex_cable,
			"image_height": 120,
			"desc": "[b]Fungsi Pin RJ-45 (10/100 Mbps):[/b]\n• [b]Pin 1 & 2:[/b] Transmit Data (Tx+ / Tx-)\n• [b]Pin 3 & 6:[/b] Receive Data (Rx+ / Rx-)\n• [b]Pin 4, 5, 7, 8:[/b] Cadangan / PoE (Power)\n\n[b]Perbedaan T568A vs T568B:[/b]\nHanya menukar pasangan [b]Oranye[/b] dan [b]Hijau[/b] (Pin 1, 2 dengan Pin 3, 6)."
		},
		"right": {
			"title": "LANGKAH CRIMPING",
			"image": tex_crimping,
			"image_height": 110,
			"body": "[b]Urutan Pemasangan Kabel LAN:[/b]\n[b]1. Kupas Jaket:[/b] Kupas jaket luar kabel ~2 cm.\n[b]2. Urai & Luruskan:[/b] Buka 4 pilinan kawat.\n[b]3. Susun Warna:[/b] Urutkan pin standar T568B.\n[b]4. Potong Rata:[/b] Potong rata kawat ~1.2 cm.\n[b]5. Tekan Crimping:[/b] Masukkan ke RJ-45 lalu jepit kuat dengan tang crimping!"
		}
	},
	{
		"left": {
			"title": "KLASIFIKASI IPv4",
			"image": null,
			"image_height": 0,
			"desc": "[b]Kelas A (1.0.0.0 – 126.255.255.255)[/b]\n• Subnet Mask default: 255.0.0.0 (/8)\n• Skala: Jaringan global raksasa (16 Juta Host)\n\n[b]Kelas B (128.0.0.0 – 191.255.255.255)[/b]\n• Subnet Mask default: 255.255.0.0 (/16)\n• Skala: Kampus / Perusahaan besar (65.534 Host)\n\n[b]Kelas C (192.0.0.0 – 223.255.255.255)[/b]\n• Subnet Mask default: 255.255.255.0 (/24)\n• Skala: Jaringan LAN lokal & rumah (254 Host)"
		},
		"right": {
			"title": "IP PRIVAT & NAT",
			"image": null,
			"image_height": 0,
			"body": "[b]Rentang IP Privat (Gratis untuk LAN):[/b]\n• [b]Kelas A:[/b] 10.0.0.0 – 10.255.255.255\n• [b]Kelas B:[/b] 172.16.0.0 – 172.31.255.255\n• [b]Kelas C:[/b] 192.168.0.0 – 192.168.255.255\n\n[b]Fungsi NAT (Network Address Translation):[/b]\nIP privat tidak bisa langsung mengakses internet. Router menggunakan [b]NAT[/b] untuk memetakan ribuan perangkat lokal ke satu IP publik resmi saat terhubung ke internet."
		}
	}
]

func _ready() -> void:
	visible = false
	book_wrapper.pivot_offset = book_wrapper.size / 2.0
	
	close_btn.pivot_offset = close_btn.size / 2.0
	prev_btn.pivot_offset = prev_btn.size / 2.0
	next_btn.pivot_offset = next_btn.size / 2.0
	
	close_btn.pressed.connect(close)
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	
	_setup_button_hover(close_btn)
	_setup_button_hover(prev_btn)
	_setup_button_hover(next_btn)
	
	dim_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	
	_render_spread(current_spread)
	
	if "--screenshot-guidebook" in OS.get_cmdline_args():
		open()
		await get_tree().create_timer(0.45).timeout
		var img0 = get_viewport().get_texture().get_image()
		img0.save_png("art/guidebook_spread0.png")
		
		# Next spread
		_on_next_pressed()
		await get_tree().create_timer(0.45).timeout
		var img1 = get_viewport().get_texture().get_image()
		img1.save_png("art/guidebook_spread1.png")
		
		# Next spread
		_on_next_pressed()
		await get_tree().create_timer(0.45).timeout
		var img2 = get_viewport().get_texture().get_image()
		img2.save_png("art/guidebook_spread2.png")
		
		get_tree().quit()

func open() -> void:
	visible = true
	is_animating = false
	current_spread = 0
	_render_spread(current_spread)
	
	dim_backdrop.modulate.a = 0.0
	book_wrapper.modulate.a = 0.0
	book_wrapper.scale = Vector2(0.3, 0.3)
	
	if book_tween and book_tween.is_valid():
		book_tween.kill()
		
	book_tween = create_tween().set_parallel(true)
	book_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	book_tween.tween_property(dim_backdrop, "modulate:a", 1.0, 0.25)
	book_tween.tween_property(book_wrapper, "modulate:a", 1.0, 0.2)
	book_tween.tween_property(book_wrapper, "scale", Vector2(1.0, 1.0), 0.35)
	
	play_book_open_sfx()

func close() -> void:
	if is_animating:
		return
	is_animating = true
	play_book_close_sfx()
	
	if book_tween and book_tween.is_valid():
		book_tween.kill()
		
	book_tween = create_tween().set_parallel(true)
	book_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	book_tween.tween_property(dim_backdrop, "modulate:a", 0.0, 0.2)
	book_tween.tween_property(book_wrapper, "modulate:a", 0.0, 0.2)
	book_tween.tween_property(book_wrapper, "scale", Vector2(0.4, 0.4), 0.22)
	
	book_tween.chain().tween_callback(func():
		visible = false
		is_animating = false
		closed.emit()
	)

func _on_next_pressed() -> void:
	if is_animating or current_spread >= spreads.size() - 1:
		return
	_flip_page(true)

func _on_prev_pressed() -> void:
	if is_animating or current_spread <= 0:
		return
	_flip_page(false)

func _flip_page(forward: bool) -> void:
	is_animating = true
	play_page_flip_sfx()
	
	flip_sheet.visible = true
	
	var flip_duration = 0.16
	var next_index = current_spread + 1 if forward else current_spread - 1
	
	if forward:
		# Flip from right to left across spine
		# Start on right page
		flip_sheet.position = Vector2(458, 30)
		flip_sheet.size = Vector2(357, 505)
		flip_sheet.pivot_offset = Vector2(0, 252) # Left edge (spine)
		flip_sheet.scale = Vector2(1.0, 1.0)
		sheet_shadow.color.a = 0.0
		
		var tween = create_tween()
		# Phase 1: fold right page into spine
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(flip_sheet, "scale:x", 0.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.4, flip_duration)
		
		# Halfway: update underlying contents and switch pivot to right edge (spine) on left side
		tween.chain().tween_callback(func():
			current_spread = next_index
			_render_spread(current_spread)
			
			flip_sheet.position = Vector2(68, 30)
			flip_sheet.pivot_offset = Vector2(357, 252) # Right edge (spine)
			flip_sheet.scale = Vector2(0.0, 1.0)
		)
		
		# Phase 2: unfold onto left page
		tween.chain().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(flip_sheet, "scale:x", 1.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.0, flip_duration)
		
		tween.chain().tween_callback(func():
			flip_sheet.visible = false
			is_animating = false
		)
	else:
		# Flip from left to right across spine
		flip_sheet.position = Vector2(68, 30)
		flip_sheet.size = Vector2(357, 505)
		flip_sheet.pivot_offset = Vector2(357, 252) # Right edge (spine)
		flip_sheet.scale = Vector2(1.0, 1.0)
		sheet_shadow.color.a = 0.0
		
		var tween = create_tween()
		# Phase 1: fold left page into spine
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(flip_sheet, "scale:x", 0.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.4, flip_duration)
		
		# Halfway: update underlying contents and switch pivot to left edge (spine) on right side
		tween.chain().tween_callback(func():
			current_spread = next_index
			_render_spread(current_spread)
			
			flip_sheet.position = Vector2(458, 30)
			flip_sheet.pivot_offset = Vector2(0, 252) # Left edge (spine)
			flip_sheet.scale = Vector2(0.0, 1.0)
		)
		
		# Phase 2: unfold onto right page
		tween.chain().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(flip_sheet, "scale:x", 1.0, flip_duration)
		tween.tween_property(sheet_shadow, "color:a", 0.0, flip_duration)
		
		tween.chain().tween_callback(func():
			flip_sheet.visible = false
			is_animating = false
		)

func _render_spread(index: int) -> void:
	if index < 0 or index >= spreads.size():
		return
		
	var data = spreads[index]
	
	# Left Page
	left_title.text = data["left"]["title"]
	if data["left"]["image"]:
		left_image.texture = data["left"]["image"]
		var h = data["left"].get("image_height", 140)
		left_image.custom_minimum_size = Vector2(0, h)
		left_image.visible = true
	else:
		left_image.visible = false
	left_text.text = data["left"]["desc"]
	page_num_left.text = str(index * 2 + 1)
	
	# Right Page
	right_title.text = data["right"]["title"]
	right_text.text = data["right"]["body"]
	if data["right"]["image"]:
		right_image.texture = data["right"]["image"]
		var h = data["right"].get("image_height", 100)
		right_image.custom_minimum_size = Vector2(0, h)
		right_image.visible = true
	else:
		right_image.visible = false
	page_num_right.text = str(index * 2 + 2)
	
	# Button states
	prev_btn.disabled = (index == 0)
	prev_btn.modulate.a = 0.35 if prev_btn.disabled else 1.0
	
	next_btn.disabled = (index == spreads.size() - 1)
	next_btn.modulate.a = 0.35 if next_btn.disabled else 1.0

func _setup_button_hover(btn: TextureButton) -> void:
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	btn.button_down.connect(func():
		if not btn.disabled:
			var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08)
	)
	btn.button_up.connect(func():
		var target = Vector2(1.12, 1.12) if btn.is_hovered() and not btn.disabled else Vector2(1.0, 1.0)
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", target, 0.1)
	)

# Sound Synthesis: Book Open Chime
func play_book_open_sfx() -> void:
	_play_synth_tone([523.25, 659.25, 783.99], 0.18, 0.3)

# Sound Synthesis: Book Close Tone
func play_book_close_sfx() -> void:
	_play_synth_tone([783.99, 523.25], 0.14, 0.3)

# Sound Synthesis: Crisp Paper Turn Rustle
func play_page_flip_sfx() -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	# Generate filtered noise with paper whoosh envelope
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = sin(t / duration * PI) * exp(-t * 12.0)
		# Combine noise with soft frequency sweep
		var noise = randf_range(-1.0, 1.0)
		var flutter = sin(t * 1200.0 * TAU) * 0.25
		var sample_val = (noise * 0.7 + flutter) * envelope * 0.4
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _play_synth_tone(notes: Array, note_duration: float, volume: float) -> void:
	if not audio_player:
		return
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
		var note_idx = int(t_total / note_duration)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var freq = notes[note_idx]
		var t_note = fmod(t_total, note_duration)
		var envelope = exp(-t_note * 18.0)
		var sample_val = sin(t_note * freq * TAU) * envelope * volume
		var int_val = int(clamp(sample_val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
