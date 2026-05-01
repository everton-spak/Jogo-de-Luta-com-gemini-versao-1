class_name TatsumakiMove
extends MoveComponent

# =========================================================
# AS DUAS POSSIBILIDADES DE COMANDO (Tatsumaki Clássico)
# =========================================================
@export var sequence_heavy: Array[String] = ["D", "DB", "B", "kick_strong"]
@export var sequence_light: Array[String] = ["D", "DB", "B", "kick_light"]

#@export var target_state_name: String = "SpecialAttack"
@export var sub_state: String = "Tatsumaki"

var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

var _forced_posture: String = "stand"
var _is_charging_motion: bool = false 
var _active_charge_btn: String = "" 
var _active_strength: String = ""   

func check_execution(buffer: InputBuffer) -> bool:
	var mechanic = buffer.fighter.get_component("SpecialMechanicComponent")
	if not mechanic: return false
	
	# =========================================================
	# FASE B: CARGA DO TATSUMAKI
	# =========================================================
	if _is_charging_motion:
		var delta = buffer.get_physics_process_delta_time()
		var result = mechanic.process_charge(_active_charge_btn, delta)
		var status = result.get("status", "inactive")
		
		if status == "charging":
			return false 
			
		_is_charging_motion = false
		payload_to_inject.clear()
		
		match status:
			"normal", "strong", "super":
				dynamic_target_state = target_state_name
				payload_to_inject["sub_state"] = sub_state
				payload_to_inject["forced_posture"] = _forced_posture 
				payload_to_inject["charge_level"] = status
				payload_to_inject["multiplier"] = result.get("multiplier", 1.0) 
				payload_to_inject["button_strength"] = _active_strength
				return true
				
			"inactive":
				return false
				
			_: 
				dynamic_target_state = "SystemState" 
				payload_to_inject["sub_state"] = status
				return true

	# =========================================================
	# FASE A: DETEÇÃO DO COMANDO
	# =========================================================
	var detected_btn = ""
	var detected_strength = ""
	
	if buffer.is_sequence_buffered(sequence_heavy):
		buffer.consume_sequence()
		detected_btn = "kick_strong"
		detected_strength = "heavy"
		
	elif buffer.is_sequence_buffered(sequence_light):
		buffer.consume_sequence()
		detected_btn = "kick_light"
		detected_strength = "light"
		
	if detected_btn != "":
		var input_comp = buffer.input_provider
		if input_comp and input_comp.get_movement_direction().y > 0.5:
			_forced_posture = "crouch"
		else:
			_forced_posture = "stand"
			
		_active_charge_btn = detected_btn
		_active_strength = detected_strength
		_is_charging_motion = true
		mechanic.reset_charge()
		
		return false 
		
	return false
