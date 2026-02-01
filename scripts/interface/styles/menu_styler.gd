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

# VERSIÓN SIN FORZAR TAMAÑO DE FUENTE - Ahora puedes controlarlo manualmente desde el editor
static func style_button(button: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)  # Transparente
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.3, 0.3, 0.3, 1)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.15, 0.15, 0.15, 1)
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color.WHITE
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.05, 0.05, 0.05, 1)
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color.WHITE
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	# ❌ REMOVIDO: button.add_theme_font_size_override("font_size", 28)
	# Ahora puedes controlar el tamaño desde el Inspector de cada botón
	button.add_theme_color_override("font_color", Color.WHITE)
