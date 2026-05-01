class_name CrouchIdleState
extends State

func enter(_payload: Dictionary = {}) -> void:
	# 1. Garante que o personagem está imóvel
	fighter.velocity.x = 0
	
	# 2. Toca a animação parado e agachado
	if anim:
		anim.play("crouch_idle")
		
	# 👇 O boneco encolhe fisicamente aqui!
	#if fighter: fighter.set_posture_collision(true)

func physics_update(delta: float) -> void:
	# O GroundState pai aplica gravidade e o CrouchState pai checa a saída do agachamento
	movement.apply_friction(3000.0, delta)
	movement.commit_movement()
	
	var dir = input.get_movement_direction()
	
	# TRANSICÃO PARA CAMINHAR AGACHADO (Crawl)
	if dir.x != 0:
		transition_requested.emit("CrawlState", {})
		return
		
	# TRANSICÃO PARA ATAQUE AGACHADO
	if input.is_action_just_pressed("punch_light"):
		transition_requested.emit("LightPunchState", {})
		
	var special_cmd = input_buffer.check_special_moves(get_tags())
	if special_cmd.has("state"):
		transition_requested.emit(special_cmd["state"], special_cmd["payload"])
		return
		
		
# As tags "Crouching" e "Grounded" já vêm dos pais (CrouchState e GroundState)
func get_tags() -> Array[String]:
	return ["Crouching", "Cancellable"]
