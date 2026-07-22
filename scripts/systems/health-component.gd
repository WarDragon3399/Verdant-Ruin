class_name HealthComponent extends Node
## A custom node (no scene needed!) that handles health of an entity
##
## It provides four functions: [method HealthComponent.heal], [method HealthComponent.damage]
## [method HealthComponent.add_continuous_damage_source], 
## [method HealthComponent.add_continuous_heal_source]


## Emitted when health gets smaller
signal damaged
## Emitted when health gets bigger
signal healed
## Emitted when health is 0
signal died


## The max health allowed
@export var max_health: int = 100
## The actuall health variable
var health: int = max_health:
	set(v):
		health = clampi(v, 0, max_health)
		if health == 0:
			died.emit()


# - PRIVATE ----------------------------------------------------------------------------------------

var _continuous_dmg_srcs: Array[Dictionary]
var _continuous_heal_srcs: Array[Dictionary]


# - PUBLIC -----------------------------------------------------------------------------------------

## This function subtracts the `amount` from `health` and emits the [signal HealthComponent.damaged]
## signal
func damage(amount: int) -> void:
	health -= amount
	damaged.emit()


## This function adds the `amount` to `health` and emits the [signal HealthComponent.health] signal
func heal(amount: int) -> void:
	health += amount
	healed.emit()


## Appends an entry with the provided information and references to the timers and starts dealing
## `amount` of damage every `interval` seconds for `duration` seconds. After the end the entry gets
## removed - each time a signal [signal HealthComponent.damaged] will get emitted.
func add_continuous_damage_source(amount: int, interval: float, duration: float) -> void: 
	var new_dmg_src: Dictionary = {
			&"ammount": amount, 
			&"interval": interval, 
			&"duration": duration, 
			&"interval_timer": null,
			&"duration_timer": null}
	
	_add_timers((func():
		damage(amount)
		), new_dmg_src)
	
	new_dmg_src[&"duration_timer"].timeout.connect(func():
		_continuous_dmg_srcs.erase(new_dmg_src)
		)
	
	_continuous_dmg_srcs.append(new_dmg_src)


## Appends an entry with the provided information and references to the timers and starts healing
## `amount` of health every `interval` seconds for `duration` seconds. After the end the entry gets
## removed - each time a signal [signal HealthComponent.healed] will get emitted.
func add_continuous_heal_source(amount: int, interval: float, duration: float) -> void:
	var new_heal_src: Dictionary = {
			&"ammount": amount, 
			&"interval": interval, 
			&"duration": duration, 
			&"interval_timer": null,
			&"duration_timer": null}
	
	_add_timers((func(): 
		heal(amount)
		)
		,new_heal_src)
	
	new_heal_src[&"duration_timer"].timeout.connect(func():
		_continuous_heal_srcs.erase(new_heal_src)
		)
	
	_continuous_heal_srcs.append(new_heal_src)


# - PRIVATE ----------------------------------------------------------------------------------------

func _add_timers(interval_func: Callable, dict: Dictionary) -> void:
	var interval_timer: Timer = Timer.new()
	interval_timer.wait_time = dict[&"interval"]
	interval_timer.autostart = true
	interval_timer.one_shot = false
	dict[&"interval_timer"] = interval_timer
	var duration_timer: Timer = Timer.new()
	duration_timer.wait_time = dict[&"duration"]
	duration_timer.autostart = true
	duration_timer.one_shot = true
	dict[&"duration_timer"] = duration_timer
	
	interval_timer.timeout.connect(interval_func)
	duration_timer.timeout.connect(func(): 
		interval_timer.queue_free()
		duration_timer.queue_free()
		)
