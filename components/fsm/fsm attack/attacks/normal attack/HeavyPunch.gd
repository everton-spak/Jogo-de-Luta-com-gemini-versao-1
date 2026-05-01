class_name HeavyPunch
extends StateAttack

# Distância para ativar o soco de perto (ex: gancho ou cotovelada)
@export var proximity_threshold: float = 85.0

func enter(payload: Dictionary = {}) -> void:
	# 1. IDENTIFICAÇÃO DO CONTEXTO
	var posture = payload.get("forced_posture", "stand")
	var is_close: bool = false
	
	if posture == "stand":
		is_close = _is_near_opponent()

	# =========================================================
	# 2. CONFIGURAÇÃO DINÂMICA (Postura e Proximidade)
	# =========================================================
	match posture:
		"stand":
			if is_close:
				# --- Perto: GANCHO (Ótimo para iniciar combos) ---
				animation_name = "hp_close"
				startup_time = 0.1     # Rápido para um golpe pesado
				active_time = 0.06
				recovery_time = 0.22
				hitbox_pos = Vector2(45, -45)
				hitbox_size = Vector2(40, 50)
				if hitbox: hitbox.hit_type = "mid"
			else:
				# --- Longe: SOCO DIRETO (Excelente alcance) ---
				animation_name = "hp_far"
				startup_time = 0.16    # Mais lento e pesado
				active_time = 0.08
				recovery_time = 0.3
				hitbox_pos = Vector2(85, -40)
				hitbox_size = Vector2(65, 25)
				if hitbox: hitbox.hit_type = "mid"
			
		"crouch":
			# --- SOCO PESADO AGACHADO (Anti-Aéreo clássico) ---
			animation_name = "hp_crouch"
			startup_time = 0.14
			active_time = 0.1
			recovery_time = 0.28
			hitbox_pos = Vector2(55, -55) # Aponta para cima para pegar quem pula
			hitbox_size = Vector2(50, 60)
			if hitbox: hitbox.hit_type = "mid"
			
		"air":
			# --- SOCO AÉREO PESADO (Martelo) ---
			animation_name = "hp_air"
			startup_time = 0.15
			active_time = 0.15
			recovery_time = 0.2
			hitbox_pos = Vector2(50, 20) # Bate em diagonal para baixo
			hitbox_size = Vector2(55, 40)
			if hitbox: hitbox.hit_type = "high" # Overhead

	# =========================================================
	# 3. PROPRIEDADES DE DANO
	# =========================================================
	if hitbox:
		hitbox.damage = 15.0
		# Socos pesados podem ou não derrubar. 
		# Geralmente, a versão de longe (far) derruba em contra-ataque.
		hitbox.knockdown = false 
	
	# Tags táticas
	attack_tags = ["Attacking", "Normal", "Heavy", posture.capitalize()]
	
	# Quase todos os Heavy Punches são canceláveis em especiais no chão
	if posture != "air":
		attack_tags.append("Cancellable")
	
	# 4. EXECUÇÃO
	super.enter(payload)
