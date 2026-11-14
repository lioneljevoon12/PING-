extends Control

# Character Customization Modal (Kustomisasi Karakter Teknisi)
# Live preview of router mascot with selectable skins, accessories, and technician titles

signal closed
signal applied(skin: String, accessory: String, title_name: String)

const CloseButtonScene = preload("res://scenes/close_button.tscn")

var font_black = preload("res://art/assets/PING! Assets/Fonts/Nunito-Black.ttf")
var font_extrabold = preload("res://art/assets/PING! Assets/Fonts/Nunito-ExtraBold.ttf")
var font_bold = preload("res://art/assets/PING! Assets/Fonts/Nunito-Bold.ttf")
var font_semibold = preload("res://art/assets/PING! Assets/Fonts/Nunito-SemiBold.ttf")

var tex_router = preload("res://art/assets/PING! Assets/Character/main-char-router.png")

@onready var backdrop: ColorRect = %Backdrop
@onready var card_wrapper: PanelContainer = %CardWrapper
@onready var close_btn_slot: Control = %CloseButtonSlot

# Preview Nodes
@onready var preview_mascot: TextureRect = %PreviewMascot
@onready var preview_accessory_label: Label = %PreviewAccessoryLabel
@onready var preview_name_label: Label = %PreviewNameLabel
@onready var preview_title_label: Label = %PreviewTitleLabel
@onready var preview_desc_label: Label = %PreviewDescLabel

# Tabs & Option Containers
@onready var tab_btn_skin: Button = %TabBtnSkin
@onready var tab_btn_acc: Button = %TabBtnAcc
@onready var tab_btn_title: Button = %TabBtnTitle
@onready var options_container: VBoxContainer = %OptionsContainer
@onready var apply_btn: Button = %ApplyBtn

var current_tab: String = "skin" # "skin", "acc", "title"
var temp_skin: String = "classic"
var temp_accessory: String = "none"
var temp_title: String = "Junior Technician"

func _ready() -> void:
	visible = false
	_build_close_button()
	_setup_tabs()
	_setup_apply_button()
	
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
	tab_btn_skin.pressed.connect(func(): _select_tab("skin"))
	tab_btn_acc.pressed.connect(func(): _select_tab("acc"))
	tab_btn_title.pressed.connect(func(): _select_tab("title"))
	_update_tab_buttons_ui()

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	_update_tab_buttons_ui()
	_render_options()

func _update_tab_buttons_ui() -> void:
	var tabs = [
		{ "id": "skin", "btn": tab_btn_skin },
		{ "id": "acc", "btn": tab_btn_acc },
		{ "id": "title", "btn": tab_btn_title }
	]
	for t in tabs:
		var btn = t["btn"] as Button
		var is_act = (t["id"] == current_tab)
		var sb = StyleBoxFlat.new()
		if is_act:
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

func _setup_apply_button() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#10b981")
	sb.border_color = Color("#047857")
	sb.set_border_width_all(2.5)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.02, 0.47, 0.34, 0.3)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	apply_btn.add_theme_stylebox_override("normal", sb)
	apply_btn.add_theme_stylebox_override("hover", sb)
	apply_btn.add_theme_stylebox_override("pressed", sb)
	apply_btn.add_theme_font_override("font", font_black)
	apply_btn.add_theme_font_size_override("font_size", 16)
	apply_btn.add_theme_color_override("font_color", Color.WHITE)
	apply_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	apply_btn.pressed.connect(_on_apply_pressed)

func open() -> void:
	if PlayerData:
		temp_skin = PlayerData.current_skin
		temp_accessory = PlayerData.current_accessory
		temp_title = PlayerData.current_title
		preview_name_label.text = PlayerData.current_username
	else:
		temp_skin = "classic"
		temp_accessory = "none"
		temp_title = "Junior Technician"
		preview_name_label.text = "Teknisi"
		
	_select_tab("skin")
	_update_live_preview()
	
	visible = true
	card_wrapper.scale = Vector2(0.85, 0.85)
	card_wrapper.modulate.a = 0.0
	backdrop.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.22)
	tw.tween_property(card_wrapper, "modulate:a", 1.0, 0.18)
	tw.tween_property(backdrop, "modulate:a", 1.0, 0.18)

func close() -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(card_wrapper, "scale", Vector2(0.9, 0.9), 0.14)
	tw.tween_property(card_wrapper, "modulate:a", 0.0, 0.14)
	tw.tween_property(backdrop, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(func():
		visible = false
		closed.emit()
	)

func _update_live_preview() -> void:
	# 1. Skin color modulation
	var skin_color = Color("#38bdf8")
	var skin_desc = "Warna asli maskot router PING!"
	if PlayerData and temp_skin in PlayerData.SKIN_CONFIG:
		skin_color = PlayerData.SKIN_CONFIG[temp_skin]["color"]
		skin_desc = PlayerData.SKIN_CONFIG[temp_skin]["desc"]
	preview_mascot.self_modulate = skin_color
	preview_desc_label.text = skin_desc
	
	# 2. Accessory overlay (posisi mengikuti badan karakter, tidak menutupi wajah)
	var acc_path = ""
	if PlayerData and temp_accessory in PlayerData.ACCESSORY_CONFIG:
		acc_path = PlayerData.ACCESSORY_CONFIG[temp_accessory].get("texture_path", "")
	AccessoryOverlay.apply(preview_mascot, temp_accessory, acc_path)
		
	if preview_accessory_label:
		preview_accessory_label.text = ""
	
	# 3. Title label
	preview_title_label.text = temp_title

func _render_options() -> void:
	for c in options_container.get_children():
		c.queue_free()
		
	if current_tab == "skin":
		_render_skin_options()
	elif current_tab == "acc":
		_render_accessory_options()
	elif current_tab == "title":
		_render_title_options()

func _render_skin_options() -> void:
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	options_container.add_child(grid)
	
	var configs = PlayerData.SKIN_CONFIG if PlayerData else {}
	for skin_id in configs.keys():
		var data = configs[skin_id]
		var is_selected = (skin_id == temp_skin)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 60)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#ffffff") if not is_selected else Color("#fef3c7")
		sb.border_color = data["color"] if not is_selected else Color("#ea580c")
		sb.set_border_width_all(3 if is_selected else 2)
		sb.set_corner_radius_all(14)
		sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		btn.add_child(hb)
		
		var color_swatch = PanelContainer.new()
		color_swatch.custom_minimum_size = Vector2(36, 36)
		var sb_c = StyleBoxFlat.new()
		sb_c.bg_color = data["color"]
		sb_c.border_color = Color("#4a2e2b")
		sb_c.set_border_width_all(2)
		sb_c.set_corner_radius_all(18)
		color_swatch.add_theme_stylebox_override("panel", sb_c)
		hb.add_child(color_swatch)
		
		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 2)
		hb.add_child(vb)
		
		var l_title = Label.new()
		l_title.text = data["name"]
		l_title.add_theme_font_override("font", font_black)
		l_title.add_theme_font_size_override("font_size", 13)
		l_title.add_theme_color_override("font_color", Color("#1e293b"))
		vb.add_child(l_title)
		
		var l_sub = Label.new()
		l_sub.text = "Aktif ✓" if is_selected else "Pilih Warna"
		l_sub.add_theme_font_override("font", font_bold)
		l_sub.add_theme_font_size_override("font_size", 10)
		l_sub.add_theme_color_override("font_color", Color("#ea580c") if is_selected else Color("#64748b"))
		vb.add_child(l_sub)
		
		var sid = skin_id
		btn.pressed.connect(func():
			temp_skin = sid
			_update_live_preview()
			_render_options()
		)
		grid.add_child(btn)

func _render_accessory_options() -> void:
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	options_container.add_child(grid)
	
	var configs = PlayerData.ACCESSORY_CONFIG if PlayerData else {}
	for acc_id in configs.keys():
		var data = configs[acc_id]
		var is_selected = (acc_id == temp_accessory)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 104)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#ffffff") if not is_selected else Color("#fef3c7")
		sb.border_color = Color("#ea580c") if is_selected else Color("#cbd5e1")
		sb.set_border_width_all(3 if is_selected else 2)
		sb.set_corner_radius_all(14)
		sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
		# Hanya gambar aksesoris (besar), tanpa tulisan
		var cc = CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cc)
		var p = data.get("texture_path", "")
		if p != "" and ResourceLoader.exists(p):
			var icon_tex = TextureRect.new()
			icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_tex.texture = AccessoryOverlay._cropped_texture(p)
			icon_tex.custom_minimum_size = Vector2(120, 84)
			icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cc.add_child(icon_tex)
		else:
			var icon_lbl = Label.new()
			icon_lbl.text = "❌"
			icon_lbl.add_theme_font_size_override("font_size", 46)
			icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cc.add_child(icon_lbl)
		btn.tooltip_text = str(data.get("name", ""))
		
		var aid = acc_id
		btn.pressed.connect(func():
			temp_accessory = aid
			_update_live_preview()
			_render_options()
		)
		grid.add_child(btn)

func _render_title_options() -> void:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 240)
	options_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	
	var titles = PlayerData.TITLE_OPTIONS if PlayerData else []
	for t_name in titles:
		var is_selected = (t_name == temp_title)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#ffffff") if not is_selected else Color("#fef3c7")
		sb.border_color = Color("#ea580c") if is_selected else Color("#cbd5e1")
		sb.set_border_width_all(2.5 if is_selected else 1.5)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		btn.add_child(hb)
		
		var badge = Label.new()
		badge.text = "🎖️" if is_selected else "▫️"
		badge.add_theme_font_size_override("font_size", 16)
		hb.add_child(badge)
		
		var lbl = Label.new()
		lbl.text = t_name
		lbl.add_theme_font_override("font", font_black if is_selected else font_bold)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color("#ea580c") if is_selected else Color("#334155"))
		hb.add_child(lbl)
		
		var t_val = t_name
		btn.pressed.connect(func():
			temp_title = t_val
			_update_live_preview()
			_render_options()
		)
		vbox.add_child(btn)

func _on_apply_pressed() -> void:
	if PlayerData:
		PlayerData.set_customization(temp_skin, temp_accessory, temp_title)
	applied.emit(temp_skin, temp_accessory, temp_title)
	close()
