class_name AirState
extends StateMachine # <-- Herda da FSM para gerir sub-estados aéreos

func _on_enter(_payload: Dictionary = {}) -> void:
	# Lógica executada assim que o personagem sai do chão
	pass

func _on_physics_update(delta: float) -> void:
	if fighter and fighter.is_on_floor():
		#print("CHÃO DETECTADO PELO AIR_STATE!")
		fighter.velocity.y = 0
		# Tentamos mandar para o IdleState que é o destino final real
		transition_requested.emit("GroundState", {})
		return

	# ==========================================
	# 2. GRAVIDADE
	# ==========================================
	if movement:
		movement.apply_gravity(delta)
		# Se o boneco estiver a cair muito rápido, o Godot pode "pular" o chão.
		# O commit_movement() aplica a velocidade final.
		movement.commit_movement()
	# ==========================================
	# 3. DETECÇÃO GLOBAL DE PAREDE (Wall Detection)
	# ==========================================
	_check_wall_interaction()

func _check_wall_interaction() -> void:
	if not fighter.is_on_wall() or not input: return
	
	var dir_x = input.get_movement_direction().x
	var wall_normal = fighter.get_wall_normal().x
	
	# Se o jogador estiver empurrando o direcional CONTRA a parede
	if dir_x != 0 and sign(dir_x) == -sign(wall_normal):
		if current_state_name != "WallSlideState":
			change_state("WallSlideState")

func get_machine_tags() -> Array[String]:
	return ["Airborne"]
