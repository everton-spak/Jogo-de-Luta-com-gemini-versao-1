class_name FallState
extends State

func enter(_payload: Dictionary = {}) -> void:
	# Toca a animação de queda
	anim.play("fall")

func physics_update(_delta: float) -> void:
	# ==========================================
	# 3. CHECAGEM DE WALL SLIDE
	# ==========================================
	_check_wall_slide()
	# ==========================================
	# 4. GOLPES ESPECIAIS E NORMAIS AÉREOS
	# ==========================================
	_check_aerial_attacks()
# --- FUNÇÕES DE TRANSIÇÃO ---
func _check_wall_slide() -> void:
	if fighter.is_on_wall() and input and input_buffer.input:
		# Pega a direção que o jogador está segurando
		var input_dir = input_buffer.input.get_movement_direction().x
		
		# Descobre para que lado a parede está fisicamente
		var wall_dir = -fighter.get_wall_normal().x
		
		# Se está caindo (velocity.y > 0) e segurando contra a parede, gruda!
		if fighter.velocity.y > 0 and input_dir == wall_dir and input_dir != 0:
			transition_requested.emit("WallSlideState")

func _check_aerial_attacks() -> void:
	if not input: return
	# A MÁGICA DO SEU CÓDIGO AQUI:
	# O buffer vai checar todos os `MoveComponent` filhos dele que tenham
	# a tag "Airborne" ou "Cancellable" permitida!
	#var special_cmd = input_buffer.check_special_moves(get_tags())
	#if special_cmd.has("state"):
		#transition_requested.emit(special_cmd["state"], special_cmd["payload"])
		#return
		
	# Checagem de botões normais (Ataques aéreos básicos)
	###if input_buffer.input.is_action_just_pressed("punch_light"):
		#transition_requested.emit("AirLightPunchState")
	#elif input_buffer.input.is_action_just_pressed("kick_heavy"):
		#transition_requested.emit("AirHeavyKickState")
		
func get_tags() -> Array[String]:
	return ["Airborne", "Cancellable"]
