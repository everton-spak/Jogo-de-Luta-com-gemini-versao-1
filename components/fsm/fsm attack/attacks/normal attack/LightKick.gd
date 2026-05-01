class_name LightKick
extends StateAttack

# Distância para o chute curto (ex: joelhada ou biqueira)
@export var proximity_threshold: float = 75.0

func enter(payload: Dictionary = {}) -> void:
	# 1. FORÇA A LIMPEZA DA LISTA LOGO NO INÍCIO
	cancel_routes.clear()
	# 1. IDENTIFICAÇÃO DO CONTEXTO
	var posture = payload.get("forced_posture", "stand")
	var is_close: bool = false
	
	if posture == "stand":
		is_close = _is_near_opponent()

	# =========================================================
	# 2. CONFIGURAÇÃO DINÂMICA (Rápido e de curto alcance)
	# =========================================================
	match posture:
		"stand":
			if is_close:
				# --- Perto: JOELHADA CURTA (Excelente para "pressure") ---
				animation_name = "lk_close"
				startup_time = 0.02    # Quase instantâneo
				active_time = 0.05
				recovery_time = 0.6
				hitbox_pos = Vector2(45, -30)
				hitbox_size = Vector2(35, 30)
				attack_tags = ["Attacking", "Normal", "Light", "Close", "Stand", "Cancellable"] # ⚡ Permite cancelar para especial!
				if hitbox: hitbox.hit_type = "mid"
			else:
				# --- Longe: CHUTE FRONTAL RÁPIDO (Poke clássico) ---
				animation_name = "lk_far"
				startup_time = 0.03
				active_time = 0.1
				recovery_time = 0.7
				hitbox_pos = Vector2(75, -25)
				hitbox_size = Vector2(50, 20)
				attack_tags = ["Attacking", "Normal", "Light", "Far", "Stand",] 
				cancel_routes = ["HadoukenFSM" , "NormalAttack"]
				
				if hitbox: hitbox.hiat_type = "mid"
			
		"crouch":
			# --- CHUTE BAIXO (O famoso "Chutinho" Low) ---
			animation_name = "lk_crouch"
			startup_time = 0.05    # Muito rápido para um golpe low
			active_time = 0.2
			recovery_time = 0.6
			hitbox_pos = Vector2(65, 15) # No nível do tornozelo
			hitbox_size = Vector2(55, 15)
			attack_tags = ["Attacking", "Normal", "Light", "Crouch"] 
			
			if hitbox: hitbox.hit_type = "low" # Obriga defesa agachada!
			
		"air":
			# --- JOELHADA AÉREA ---
			animation_name = "lk_air"
			startup_time = 0.05
			active_time = 0.1
			recovery_time = 0.12
			hitbox_pos = Vector2(40, -10)
			hitbox_size = Vector2(40, 40)
			attack_tags = ["Attacking", "Normal", "Light", "Air"] # Golpes no ar normalmente não se cancelam
			
			if hitbox: hitbox.hit_type = "high"

	# =========================================================
	# 3. PUXAR O GATILHO (CRUCIAL!)
	# =========================================================
	# Manda o "Pai" (StateAttack) processar estas informações e iniciar o ataque fisicamente.
	super.enter(payload)
	# 👇 O RESET ABSOLUTO (Passando pelo Componente) 👇
	if anim != null and anim.sprite != null:
		anim.sprite.stop()                     # 1. Congela direto no nó nativo do Godot
		anim.sprite.animation = animation_name # 2. Força a agulha na faixa certa
		anim.sprite.frame = 0                  # 3. Puxa o frame para o zero absoluto
		
		anim.play(animation_name)              # 4. Dá o play usando o seu Componente!
