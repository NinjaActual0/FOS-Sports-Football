extends Node
## Health, fatigue, and injury state. Autoloaded as `HealthManager`.
## These are continuous physical variables that scale a player's real output,
## never a hidden "is he injured enough to fail this play" roll.

class HealthState:
	var stamina: float = 1.0          ## 0..1 energy available right now
	var hydration: float = 1.0        ## 0..1 affects cramp risk and stamina regen
	var soreness: float = 0.0         ## 0..1 accumulated wear
	var injury_severity: float = 0.0  ## 0..1 0 = healthy, 1 = cannot play
	var injury_part: String = ""

	func _init(s: float = 1.0) -> void:
		stamina = s

	func performance_modifier() -> float:
		## Output scales with what the body can actually produce.
		var m := stamina
		m *= lane(hydration, 0.55, 1.0)
		m *= 1.0 - soreness * 0.30
		m *= 1.0 - injury_severity * 0.85
		return clampf(m, 0.25, 1.0)

	func top_speed_modifier() -> float:
		return lane(performance_modifier(), 0.55, 1.0)

	func accel_modifier() -> float:
		## Fatigue costs a burst more than it costs top-end speed.
		return lane(performance_modifier(), 0.40, 1.0)

	static func lane(value: float, lo: float, hi: float) -> float:
		return clampf(value, lo, hi)

## Per-player states keyed by a stable player id.
var _states: Dictionary = {}

func get_state(player_id: String) -> HealthState:
	if not _states.has(player_id):
		_states[player_id] = HealthState.new()
	return _states[player_id]

## Apply the physical cost of one play.
func exert(player_id: String, effort: float, dt: float) -> void:
	var s := get_state(player_id)
	s.stamina = maxf(s.stamina - effort * dt * 0.04, 0.0)
	s.hydration = maxf(s.hydration - effort * dt * 0.01, 0.0)
	s.soreness = minf(s.soreness + effort * dt * 0.004, 1.0)

## Recovery during time between plays.
func recover(player_id: String, dt: float, resting: bool) -> void:
	var s := get_state(player_id)
	var rate := 0.02 if resting else 0.005
	s.stamina = minf(s.stamina + rate * dt * s.hydration, 1.0)
	if resting:
		s.soreness = maxf(s.soreness - 0.002 * dt, 0.0)
