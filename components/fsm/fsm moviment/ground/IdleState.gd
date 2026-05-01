class_name IdleState
extends State

func enter(_payload: Dictionary = {}) -> void:
	# Trava de segurança da Animação
	if anim:
		anim.play("idle")
	else:
		push_error("AVISO: O IdleState não encontrou a variável 'anim'!")
		
	# Trava de segurança da Física (Impede o erro da linha 16!)
	if fighter != null:
		fighter.velocity.x = 0
		# 👇 O boneco volta a ficar em pé fisicamente aqui!
		#fighter.set_posture_collision(false)
	else:
		push_error("AVISO: O IdleState tentou parar o lutador, mas 'fighter' está vazio!")
	

func physics_update(delta: float) -> void:
	#print("🚨 TAGS DO IDLE: ", get_tags())
	# O GroundState já está rodando apply_gravity() e checando is_on_floor()!
	# Aqui só aplicamos um atrito forte para manter o boneco firme.
	movement.apply_friction(3000.0, delta)
	movement.commit_movement()
	
	
	# 1. Prioridade: Golpes Especiais (Hadouken, etc)
	var special_cmd = input_buffer.check_special_moves(get_tags())
	if special_cmd.has("state"):
		transition_requested.emit(special_cmd["state"], special_cmd["payload"])
		return

	# 2. Movimentação Básica
	var dir = input.get_movement_direction()
	
	 #Pulo (O GroundState enviará para AirState se sairmos do chão)
	if input.is_action_just_pressed("up") or dir.y < -0.5:
		transition_requested.emit("JumpState", {})
		return
		
		# Lê a alavanca direcional horizontal no momento do pulo
	var dir_x = input.get_movement_direction().x
	
	if dir_x == 0:
		transition_requested.emit("JumpNeutral", {})
	elif sign(dir_x) == 1.0:
		transition_requested.emit("JumpForward", {})
	else:
		transition_requested.emit("JumpBackward", {})
		
	# Agachar
	if dir.y > 0.5:
		transition_requested.emit("CrouchState", {})
		return
		
	# Andar
	if dir.x != 0:
		transition_requested.emit("WalkState", {})
		return

	# Ataques Normais
	if input.is_action_just_pressed("punch_light"):
		transition_requested.emit("LightPunchState", {})
		
func get_tags() -> Array[String]:
	return ["Idle", "Cancellable"]
