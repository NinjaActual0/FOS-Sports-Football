extends Node
class_name EnvironmentManager

# Weather
var temperature_c: float = 15.0
var wind_mps: Vector2 = Vector2.ZERO
var precipitation: String = \"none\" # none, rain, snow
var humidity: float = 0.5
var visibility: float = 1.0
var altitude_m: float = 0.0

# Field
var field_surface: String = \"natural_grass\" # natural_grass, turf, mud, wet, ice, snow
var field_wetness: float = 0.0
var field_traction: float = 1.0

func update_effects() -> void:
	# Traction affected by weather/field
	match field_surface:
		\"turf\": field_traction = 0.98
		\"natural_grass\": field_traction = 0.95
		\"wet\": field_traction = 0.85
		\"mud\": field_traction = 0.7
		\"snow\": field_traction = 0.65
		\"ice\": field_traction = 0.5
		_: field_traction = 0.95
	
	if precipitation == \"rain\": field_wetness = clampf(field_wetness + 0.01, 0.0, 1.0)
	if precipitation == \"snow\": pass
