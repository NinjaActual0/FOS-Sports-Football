class_name FieldMarkings
extends Node3D
## Procedural football-field markings for the greybox sandbox.
##
## Everything is flat geometry generated at runtime a few millimetres above the
## turf. No textures to import, no collision, and the lines stay crisp at any
## distance. Purely cosmetic -- nothing here feeds gameplay.
##
## The long axis of the field runs along Z. "Forward" (W / stick up) is down-field
## toward -Z, which is the direction the chase camera looks, so the yard lines
## recede into the distance and give a strong sense of speed.

const YARD := 0.9144
const PLAYING_YARDS := 100.0
const END_ZONE_YARDS := 10.0
const WIDTH_YARDS := 53.3333

const FIELD_LENGTH_M := (PLAYING_YARDS + END_ZONE_YARDS * 2.0) * YARD  # 109.728
const FIELD_WIDTH_M := WIDTH_YARDS * YARD                              # 48.768
const HALF_LENGTH := FIELD_LENGTH_M * 0.5
const HALF_WIDTH := FIELD_WIDTH_M * 0.5
const GOAL_LINE_Z := PLAYING_YARDS * 0.5 * YARD                        # 45.72
const FIVE_YARDS := 5.0 * YARD

## Unpainted turf beyond the sidelines, so you can drift out of bounds instead
## of walking off the edge of the world.
const APRON := 10.0
const GROUND_WIDTH_M := FIELD_WIDTH_M + APRON * 2.0
const GROUND_LENGTH_M := FIELD_LENGTH_M + APRON * 2.0

const HASH_X := 2.794        # NFL hash marks sit 70'9" in from each sideline
const HASH_LENGTH := 0.61
const HASH_WIDTH := 0.10
const LINE_WIDTH := 0.12
const TEN_LINE_WIDTH := 0.20
const EDGE_WIDTH := 0.12

# Small height steps keep the layers out of each other's depth range.
const BAND_Y := 0.001
const END_ZONE_Y := 0.002
const GRID_Y := 0.006
const HASH_Y := 0.010
const LINE_Y := 0.012
const NUMBER_Y := 0.020

@export var show_grid := false

var _verts := PackedVector3Array()
var _grid: MeshInstance3D

func _ready() -> void:
	_build_mow_bands()
	_build_end_zones()
	_build_lines()
	_build_hashes()
	_build_numbers()
	_build_grid()
	_grid.visible = show_grid

func toggle_grid() -> void:
	if _grid != null:
		_grid.visible = not _grid.visible

func is_grid_visible() -> bool:
	return _grid != null and _grid.visible

## Nearest painted yard line (0-50), for the debug readout.
static func yard_line_at(z: float) -> int:
	var yards := (z + GOAL_LINE_Z) / YARD
	var n := int(round(clampf(yards, 0.0, PLAYING_YARDS)))
	return n if n <= 50 else 100 - n

# --- building blocks ------------------------------------------------------

func _begin() -> void:
	_verts = PackedVector3Array()

## Flat quad on the XZ plane. Winding is ordered for Godot's front-face test,
## which treats a quad whose geometric normal points down as front-facing.
func _quad(x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	var a := Vector3(x0, y, z0)
	var b := Vector3(x1, y, z0)
	var c := Vector3(x1, y, z1)
	var d := Vector3(x0, y, z1)
	_verts.append_array(PackedVector3Array([a, c, d, a, b, c]))

func _commit(mesh_name: String, color: Color, unshaded: bool) -> MeshInstance3D:
	if _verts.is_empty():
		return null

	var normals := PackedVector3Array()
	normals.resize(_verts.size())
	normals.fill(Vector3.UP)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	# Single-sided ground decals. They are only ever seen from above, so leaving
	# culling off costs nothing and removes any per-platform winding surprises.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = mat
	# Flat decals must not cast shadows: sitting millimetres above the turf makes
	# them self-shadow (the whole stripe goes black).
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

	_verts = PackedVector3Array()
	return mi

# --- layers ---------------------------------------------------------------

## Alternating mow stripes. Single best cue for reading speed and distance.
func _build_mow_bands() -> void:
	_begin()
	var i := 0
	while i < 20:
		if i % 2 == 1:
			var z0 := -GOAL_LINE_Z + float(i) * FIVE_YARDS
			_quad(-HALF_WIDTH, z0, HALF_WIDTH, z0 + FIVE_YARDS, BAND_Y)
		i += 1
	_commit("MowBands", Color(0.16, 0.41, 0.20), false)

func _build_end_zones() -> void:
	_begin()
	_quad(-HALF_WIDTH, GOAL_LINE_Z, HALF_WIDTH, HALF_LENGTH, END_ZONE_Y)
	_commit("EndZoneHome", Color(0.10, 0.16, 0.34), false)

	_begin()
	_quad(-HALF_WIDTH, -HALF_LENGTH, HALF_WIDTH, -GOAL_LINE_Z, END_ZONE_Y)
	_commit("EndZoneAway", Color(0.34, 0.10, 0.12), false)

func _build_lines() -> void:
	_begin()
	# sidelines and end lines
	_quad(-HALF_WIDTH, -HALF_LENGTH, -HALF_WIDTH + EDGE_WIDTH, HALF_LENGTH, LINE_Y)
	_quad(HALF_WIDTH - EDGE_WIDTH, -HALF_LENGTH, HALF_WIDTH, HALF_LENGTH, LINE_Y)
	_quad(-HALF_WIDTH, -HALF_LENGTH, HALF_WIDTH, -HALF_LENGTH + EDGE_WIDTH, LINE_Y)
	_quad(-HALF_WIDTH, HALF_LENGTH - EDGE_WIDTH, HALF_WIDTH, HALF_LENGTH, LINE_Y)

	# yard lines every 5 yards, heavier every 10
	var k := 0
	while k <= 20:
		var z := -GOAL_LINE_Z + float(k) * FIVE_YARDS
		var w := TEN_LINE_WIDTH if k % 2 == 0 else LINE_WIDTH
		_quad(-HALF_WIDTH, z - w * 0.5, HALF_WIDTH, z + w * 0.5, LINE_Y)
		k += 1
	_commit("Lines", Color(0.93, 0.95, 0.96), true)

func _build_hashes() -> void:
	_begin()
	var z := -GOAL_LINE_Z + YARD
	while z < GOAL_LINE_Z - 0.01:
		# Hashes are skipped where they would land on a 5-yard line.
		var nearest := -GOAL_LINE_Z + roundf((z + GOAL_LINE_Z) / FIVE_YARDS) * FIVE_YARDS
		if absf(z - nearest) > 0.06:
			for side in [-1.0, 1.0]:
				var x: float = HASH_X * side
				_quad(
					x - HASH_LENGTH * 0.5, z - HASH_WIDTH * 0.5,
					x + HASH_LENGTH * 0.5, z + HASH_WIDTH * 0.5,
					HASH_Y
				)
		z += YARD
	_commit("HashMarks", Color(0.88, 0.90, 0.92), true)

func _build_numbers() -> void:
	var marks := [10, 20, 30, 40, 50, 40, 30, 20, 10]
	var i := 0
	while i < marks.size():
		var z := -GOAL_LINE_Z + float(i + 1) * 10.0 * YARD
		for side in [-1.0, 1.0]:
			_add_number(str(marks[i]), Vector3(17.0 * side, NUMBER_Y, z))
		i += 1

func _add_number(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 128
	label.pixel_size = 0.017
	label.modulate = Color(0.92, 0.94, 0.95)
	label.outline_size = 0
	label.shaded = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = pos
	# Lay it flat, top of the digits pointing down-field (away from the camera).
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(label)

## Optional fine reference grid, one line per yard. Toggled with F1.
func _build_grid() -> void:
	_begin()
	var z := -HALF_LENGTH
	while z <= HALF_LENGTH:
		_quad(-HALF_WIDTH, z - 0.02, HALF_WIDTH, z + 0.02, GRID_Y)
		z += YARD
	var x := -HALF_WIDTH
	while x <= HALF_WIDTH:
		_quad(x - 0.02, -HALF_LENGTH, x + 0.02, HALF_LENGTH, GRID_Y)
		x += YARD
	_grid = _commit("Grid", Color(0.25, 0.46, 0.28), true)
