class_name CrouchState
extends StateMachine

func _on_enter(_payload: Dictionary = {}) -> void:
	# 1. Ativa o Low Profile na Hurtbox para todos os filhos
	#var hurtbox = get_component("HurtboxComponent")
	if hurtbox and hurtbox.has_method("set_low_profile"):
		hurtbox.set_low_profile(true)

func _on_physics_update(_delta: float) -> void:
	var dir = input.get_movement_direction()
	
	# REGRA GLOBAL: Se soltar o "baixo", sai de toda a hierarquia de agachamento
	if dir.y <= 0.5:
		transition_requested.emit("IdleState", {})
		return

func _on_exit() -> void:
	# REGRA DE SEGURANÇA: Sempre restaura a Hurtbox ao levantar
	#var hurtbox = get_component("HurtboxComponent")
	if hurtbox and hurtbox.has_method("set_low_profile"):
		hurtbox.set_low_profile(false)

# O Galho apenas informa a FSM de quais são as suas tags base
func get_machine_tags() -> Array[String]:
	return ["Crouching"]
