class_name Attack
extends StateMachine

var _shared_tags: Array[String] = ["Attacking"]

func _on_enter(_payload: Dictionary = {}) -> void:
	if hitbox: hitbox.disable_box()
	_update_shared_tags()

func _on_physics_update(delta: float) -> void:
	if "Airborne" in _shared_tags and fighter.is_on_floor():
		_handle_landing_interruption()
		return

	if not fighter.is_on_floor():
		movement.apply_gravity(delta)
	else:
		movement.apply_friction(2000.0, delta)
	
	movement.commit_movement()

func _handle_landing_interruption() -> void:
	if hitbox: hitbox.disable_box()
	transition_requested.emit("GroundState", {"landed": true})

func _update_shared_tags() -> void:
	if fighter.is_on_floor():
		if not "Grounded" in _shared_tags: _shared_tags.append("Grounded")
		if "Airborne" in _shared_tags: _shared_tags.erase("Airborne")
	else:
		if not "Airborne" in _shared_tags: _shared_tags.append("Airborne")
		if "Grounded" in _shared_tags: _shared_tags.erase("Grounded")

func get_machine_tags() -> Array[String]:
	return _shared_tags
