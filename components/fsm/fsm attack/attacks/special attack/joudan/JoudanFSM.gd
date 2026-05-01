# JoudanFSM.gd
class_name JoudanFSM
extends StateMachine

func _on_enter(payload: Dictionary = {}) -> void:
	var target_sub_state = "StandJoudan"
	
	if not fighter.is_on_floor():
		target_sub_state = "AirJoudan"
	elif payload.has("forced_posture"):
		target_sub_state = payload.get("forced_posture").capitalize() + "Joudan"
	else:
		var input = fighter.get_component("Input")
		if input and input.is_action_pressed("crouch"):
			target_sub_state = "CrouchJoudan"
			
	# 👇 A CORREÇÃO: Em vez de gritar para o Pai, nós mudamos internamente!
	change_state(target_sub_state, payload)
