class_name GameDialog
extends Control

# Reusable Notification Dialog Component ("GameDialog")
# Standardized across ALL stages and levels:
# - Misi Gagal (Game Over)
# - Misi Berhasil / Misi Selesai (Win with star rating)
# - Konfirmasi keluar level / game
# - Info & petunjuk
# Design matches the project's "Misi Gagal" popup:
# - Creamy rounded card with thick accent-colored border
# - CloseButton (silang merah) at top-right
# - All buttons always have identical width and fixed size (no scale change on hover/pressed)
# - Soft fade-in and pop animation

signal button_clicked(index: int, text: String)
signal closed

const TYPE_CONFIG = {
	"gagal": {
		"border_color": Color("#dc2626"),
		"bg_color": Color("#fff5f5"),
		"title_color": Color("#dc2626"),
		"message_color": Color("#7f1d1d"),
		"primary_btn_bg": Color("#dc2626"),
		"primary_btn_hover": Color("#ef4444"),
		"primary_btn_pressed": Color("#b91c1c"),
		"primary_btn_text": Color("#ffffff"),
	},
	"sukses": {
		"border_color": Color("#16a34a"),
		"bg_color": Color("#f0fdf4"),
		"title_color": Color("#15803d"),
		"message_color": Color("#166534"),
		"primary_btn_bg": Color("#16a34a"),
		"primary_btn_hover": Color("#22c55e"),
		"primary_btn_pressed": Color("#15803d"),
		"primary_btn_text": Color("#ffffff"),
	},
	"konfirmasi": {
		"border_color": Color("#ea580c"),
		"bg_color": Color("#fffaf0"),
		"title_color": Color("#c2410c"),
		"message_color": Color("#7c2d12"),
		"primary_btn_bg": Color("#ea580c"),
		"primary_btn_hover": Color("#f97316"),
		"primary_btn_pressed": Color("#c2410c"),
		"primary_btn_text": Color("#ffffff"),
	},
	"info": {
		"border_color": Color("#2563eb"),
		"bg_color": Color("#f0f7ff"),
		"title_color": Color("#1d4ed8"),
		"message_color": Color("#1e3a8a"),
		"primary_btn_bg": Color("#2563eb"),
		"primary_btn_hover": Color("#3b82f6"),
		"primary_btn_pressed": Color("#1d4ed8"),
		"primary_btn_text": Color("#ffffff"),
	}
}

const SECONDARY_BTN_BG = Color("#e2e8f0")
const SECONDARY_BTN_HOVER = Color("#cbd5e1")
const SECONDARY_BTN_PRESSED = Color("#94a3b8")
const SECONDARY_BTN_TEXT = Color("#334155")

@onready var dim_overlay: ColorRect = %DimOverlay
@onready var card_wrapper: Control = %CardWrapper
@onready var card_panel: PanelContainer = %CardPanel
@onready var title_label: Label = %TitleLabel
@onready var stars_container: HBoxContainer = %StarsContainer
@onready var detail_label: Label = %DetailLabel
@onready var message_label: Label = %MessageLabel
@onready var buttons_container: BoxContainer = %ButtonsContainer
@onready var close_button: CloseButton = %CloseButton
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")
var tex_star_gold = preload("res://art/ui-ux/levelpath/star_gold.png")
var tex_star_gray = preload("res://art/ui-ux/levelpath/star_gray.png")

var is_animating: bool = false
var button_actions: Array[Callable] = []

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	z_index = 250
	
	if close_button:
		close_button.closed.connect(_on_close_button_clicked)
		
	# Clicking dimmed backdrop does not accidentally dismiss game-over or win dialogs
	if dim_overlay:
		dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func setup_dialog(title: String, message: String, buttons_data: Array = [], dialog_type: String = "info") -> void:
	setup({
		"title": title,
		"message": message,
		"buttons": buttons_data,
		"type": dialog_type
	})

func setup(options: Dictionary) -> void:
	var title: String = options.get("title", "NOTIFIKASI")
	var message: String = options.get("message", "")
	var dialog_type: String = options.get("type", "info").to_lower()
	var buttons_data: Array = options.get("buttons", [])
	var stars: int = options.get("stars", -1)
	var detail_text: String = options.get("detail_text", "")
	var show_close: bool = options.get("show_close", false)
	
	var cfg = TYPE_CONFIG.get(dialog_type, TYPE_CONFIG["info"])
	
	# 1. Card Panel Styling
	var sb_card = StyleBoxFlat.new()
	sb_card.bg_color = cfg["bg_color"]
	sb_card.border_color = cfg["border_color"]
	sb_card.set_border_width_all(3.5)
	sb_card.set_corner_radius_all(22)
	sb_card.shadow_color = Color(0, 0, 0, 0.28)
	sb_card.shadow_size = 12
	sb_card.shadow_offset = Vector2(0, 6)
	sb_card.content_margin_left = 32
	sb_card.content_margin_right = 32
	sb_card.content_margin_top = 28
	sb_card.content_margin_bottom = 28
	card_panel.add_theme_stylebox_override("panel", sb_card)
	
	# 2. Title
	title_label.text = title
	title_label.add_theme_font_override("font", font_black)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", cfg["title_color"])
	
	# 3. Stars (for success/win)
	for c in stars_container.get_children():
		c.queue_free()
		
	if stars >= 0:
		stars_container.visible = true
		for i in range(3):
			var star_rect = TextureRect.new()
			star_rect.texture = tex_star_gold if (i < stars) else tex_star_gray
			star_rect.custom_minimum_size = Vector2(46, 46)
			star_rect.size = Vector2(46, 46)
			star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars_container.add_child(star_rect)
	else:
		stars_container.visible = false
		
	# 4. Detail Label (Time, Score, etc.)
	if detail_text.strip_edges() != "":
		detail_label.visible = true
		detail_label.text = detail_text
		detail_label.add_theme_font_override("font", font_bold)
		detail_label.add_theme_font_size_override("font_size", 15)
		detail_label.add_theme_color_override("font_color", Color("#4a2e2b"))
	else:
		detail_label.visible = false
		
	# 5. Message
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_override("font", font_semibold)
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", cfg["message_color"])
	
	# 6. Close Button
	if close_button:
		close_button.visible = show_close
		
	# 7. Action Buttons (All buttons strictly identical in width and fixed size on hover/pressed)
	_build_buttons(buttons_data, cfg)

func _build_buttons(buttons_data: Array, cfg: Dictionary) -> void:
	for c in buttons_container.get_children():
		c.queue_free()
	button_actions.clear()
	
	if buttons_data.is_empty():
		return
		
	# Layout mode: if <= 2 buttons, horizontal row; if > 2, vertical stack
	var use_vertical = buttons_data.size() > 2
	
	# Target button dimensions: identical width for all buttons
	var target_width = 175.0 if not use_vertical else 280.0
	var target_height = 46.0
	
	for idx in range(buttons_data.size()):
		var b_data: Dictionary = buttons_data[idx]
		var btn_text: String = b_data.get("text", "OK")
		var is_primary: bool = b_data.get("is_primary", idx == 0)
		var action: Callable = b_data.get("action", Callable())
		button_actions.append(action)
		
		var btn = Button.new()
		btn.text = btn_text
		btn.custom_minimum_size = Vector2(target_width, target_height)
		btn.size = Vector2(target_width, target_height)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if not use_vertical else Control.SIZE_SHRINK_CENTER
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", font_black)
		btn.add_theme_font_size_override("font_size", 14)
		
		# Colors
		var bg_norm: Color
		var bg_hover: Color
		var bg_pressed: Color
		var text_col: Color
		
		if is_primary:
			bg_norm = b_data.get("bg_color", cfg["primary_btn_bg"])
			bg_hover = cfg["primary_btn_hover"]
			bg_pressed = cfg["primary_btn_pressed"]
			text_col = b_data.get("text_color", cfg["primary_btn_text"])
		else:
			bg_norm = b_data.get("bg_color", SECONDARY_BTN_BG)
			bg_hover = SECONDARY_BTN_HOVER
			bg_pressed = SECONDARY_BTN_PRESSED
			text_col = b_data.get("text_color", SECONDARY_BTN_TEXT)
			
		# StyleBoxes for normal, hover, pressed (fixed size, NO scale shift!)
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = bg_norm
		sb_norm.set_corner_radius_all(12)
		sb_norm.content_margin_left = 16
		sb_norm.content_margin_right = 16
		sb_norm.content_margin_top = 10
		sb_norm.content_margin_bottom = 10
		
		var sb_hov = StyleBoxFlat.new()
		sb_hov.bg_color = bg_hover
		sb_hov.set_corner_radius_all(12)
		sb_hov.content_margin_left = 16
		sb_hov.content_margin_right = 16
		sb_hov.content_margin_top = 10
		sb_hov.content_margin_bottom = 10
		
		var sb_press = StyleBoxFlat.new()
		sb_press.bg_color = bg_pressed
		sb_press.set_corner_radius_all(12)
		sb_press.content_margin_left = 16
		sb_press.content_margin_right = 16
		sb_press.content_margin_top = 10
		sb_press.content_margin_bottom = 10
		
		btn.add_theme_stylebox_override("normal", sb_norm)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("pressed", sb_press)
		btn.add_theme_stylebox_override("focus", sb_hov)
		btn.add_theme_color_override("font_color", text_col)
		btn.add_theme_color_override("font_hover_color", text_col)
		btn.add_theme_color_override("font_pressed_color", text_col)
		
		# STRICT REQUIREMENT: No scale tween on hover/pressed. Size stays 100% stable.
		var button_idx = idx
		btn.pressed.connect(func(): _on_button_pressed(button_idx, btn_text))
		
		buttons_container.add_child(btn)

func _on_button_pressed(idx: int, text: String) -> void:
	_play_click_sfx()
	button_clicked.emit(idx, text)
	
	if idx < button_actions.size() and button_actions[idx].is_valid():
		button_actions[idx].call()

func _on_close_button_clicked() -> void:
	close()
	closed.emit()

func open() -> void:
	if is_animating:
		return
	is_animating = true
	visible = true
	
	_center_card()
	card_wrapper.pivot_offset = card_wrapper.size / 2.0
	card_wrapper.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.22)
	await tw.finished
	is_animating = false

func close() -> void:
	if is_animating or not visible:
		return
	is_animating = true
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_property(card_wrapper, "scale", Vector2(0.85, 0.85), 0.14)
	await tw.finished
	visible = false
	is_animating = false

func _center_card() -> void:
	var vp_sz = get_viewport_rect().size
	if vp_sz.x > 0 and vp_sz.y > 0 and card_wrapper:
		card_wrapper.position = Vector2(
			(vp_sz.x - card_wrapper.size.x) / 2.0,
			(vp_sz.y - card_wrapper.size.y) / 2.0
		)

# --- CONVENIENCE HELPER METHODS ---
func show_game_over(reason: String, on_retry: Callable, on_map: Callable) -> void:
	setup({
		"title": "MISI GAGAL",
		"message": reason if reason != "" else "Nyawa teknisi habis atau waktu telah habis!",
		"type": "gagal",
		"buttons": [
			{
				"text": "COBA LAGI",
				"is_primary": true,
				"action": on_retry
			},
			{
				"text": "KEMBALI KE MAP",
				"is_primary": false,
				"action": on_map
			}
		],
		"show_close": false
	})
	open()

func show_win(title: String, desc: String, stars: int, time_str: String, on_next: Callable, on_map: Callable, next_btn_text: String = "LANJUT") -> void:
	setup({
		"title": title if title != "" else "MISI SELESAI!",
		"message": desc,
		"type": "sukses",
		"stars": stars,
		"detail_text": time_str,
		"buttons": [
			{
				"text": next_btn_text,
				"is_primary": true,
				"action": on_next
			},
			{
				"text": "KEMBALI KE MAP",
				"is_primary": false,
				"action": on_map
			}
		],
		"show_close": false
	})
	open()

func show_confirmation(title: String, message: String, on_confirm: Callable, on_cancel: Callable = Callable(), confirm_text: String = "YA", cancel_text: String = "BATAL") -> void:
	var act_confirm = func():
		await close()
		if on_confirm.is_valid():
			on_confirm.call()
			
	var act_cancel = func():
		await close()
		if on_cancel.is_valid():
			on_cancel.call()

	setup({
		"title": title,
		"message": message,
		"type": "konfirmasi",
		"buttons": [
			{
				"text": confirm_text,
				"is_primary": true,
				"action": act_confirm
			},
			{
				"text": cancel_text,
				"is_primary": false,
				"action": act_cancel
			}
		],
		"show_close": true
	})
	open()

func show_info(title: String, message: String, on_ok: Callable = Callable(), ok_text: String = "OK") -> void:
	var act_ok = func():
		await close()
		if on_ok.is_valid():
			on_ok.call()

	setup({
		"title": title,
		"message": message,
		"type": "info",
		"buttons": [
			{
				"text": ok_text,
				"is_primary": true,
				"action": act_ok
			}
		],
		"show_close": true
	})
	open()

func _play_click_sfx() -> void:
	if not audio_player:
		return
	var sample_rate = 44100
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var env = sin(t * PI)
		var val = sin(2.0 * PI * 659.25 * (float(i) / float(sample_rate))) * env * 0.22
		var sample_val = int(clamp(val * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_val)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
