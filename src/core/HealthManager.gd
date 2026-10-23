extends Node
class_name HealthManager

# Player health/fatigue affects performance
var stamina: float = 1.0
var fatigue: float = 0.0
var soreness: float = 0.0
var injury_severity: float = 0.0

func performance_modifier() -> float:
	var mod = stamina - (fatigue * 0.3) - (soreness * 0.2) - (injury_severity * 0.5)
	return clampf(mod, 0.3, 1.0)
