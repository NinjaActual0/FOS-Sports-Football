class_name HealthState
extends RefCounted
## The physical condition of one player.
##
## These are continuous physical variables that scale real output — never a
## hidden "is he too hurt to succeed" roll.

var stamina: float = 1.0          ## 0..1 energy available right now
var hydration: float = 1.0        ## 0..1 affects cramp risk and recovery rate
var soreness: float = 0.0         ## 0..1 accumulated wear
var injury_severity: float = 0.0  ## 0..1  0 = healthy, 1 = cannot play
var injury_part: String = ""

func _init(start_stamina: float = 1.0) -> void:
	stamina = start_stamina

## Fraction of full physical output he can currently produce.
func performance_modifier() -> float:
	var m := stamina
	m *= lane(hydration, 0.55, 1.0)
	m *= 1.0 - soreness * 0.30
	m *= 1.0 - injury_severity * 0.85
	return clampf(m, 0.25, 1.0)

func top_speed_modifier() -> float:
	return lane(performance_modifier(), 0.55, 1.0)

## Fatigue costs a burst more than it costs top-end speed.
func accel_modifier() -> float:
	return lane(performance_modifier(), 0.40, 1.0)

## Agility degrades faster than straight-line speed when hurt.
func agility_modifier() -> float:
	return lane(performance_modifier(), 0.35, 1.0)

static func lane(value: float, lo: float, hi: float) -> float:
	return clampf(value, lo, hi)
