extends Node

# Tema oscuro y limpio para el menú
static func create_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)  # Gris oscuro
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 1.0)  # Borde gris
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func create_button_hover_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.25, 0.25, 1.0)  # Más claro al hover
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.6, 0.6, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func create_button_pressed_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 1.0)  # Más oscuro al presionar
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.8, 0.8, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

static func style_button(button: Button):
	button.add_theme_stylebox_override("normal", create_button_style())
	button.add_theme_stylebox_override("hover", create_button_hover_style())
	button.add_theme_stylebox_override("pressed", create_button_pressed_style())
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
