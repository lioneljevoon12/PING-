class_name CloseButton
extends TextureButton

signal closed

func _ready() -> void:
	custom_minimum_size = Vector2(38, 38)
	size = Vector2(38, 38)
	pivot_offset = Vector2(19, 19)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if not texture_normal:
		texture_normal = preload("res://art/ui-ux/icons/icon_close_red.png")
		
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_pressed() -> void:
	closed.emit()

func _on_mouse_entered() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)
