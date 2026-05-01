class_name HeavyKick
extends StateAttack

# Distância para ativar o golpe de proximidade (ex: joelhada)
@export var proximity_threshold: float = 90.0

func enter(payload: Dictionary = {}) -> void:
	# 1. IDENTIFICAÇÃO DO CONTEXTO
	var posture = payload.get("forced_posture", "stand")
	var is_close: bool = false
	
	if posture == "stand":
		is_close = _is_near_opponent()

	# =========================================================
	# 2. CONFIGURAÇÃO DINÂMICA (Frame Data e Hitboxes)
	# =========================================================
	match posture:
		"stand":
			if is_close:
				# --- Perto: JOELHADA (Rápida e ótima para combos) ---
				animation_name = "hk_close"
				startup_time = 0.1    # Mais rápido que o de longe
				active_time = 0.08
				recovery_time = 0.2
				hitbox_pos = Vector2(45, -30)
				hitbox_size = Vector2(40, 40)
				if hitbox: hitbox.hit_type = "mid"
			else:
				# --- Longe: PONTAPÉ CIRCULAR (Grande alcance) ---
				animation_name = "hk_far"
				startup_time = 0.18   # Mais lento, mas cobre muita distância
				active_time = 0.12
				recovery_time = 0.35
				hitbox_pos = Vector2(95, -20)
				hitbox_size = Vector2(80, 30)
				if hitbox: hitbox.hit_type = "mid"
			
		"crouch":
			# --- RASTEIRA (O famoso Sweep) ---
			animation_name = "hk_crouch" # Geralmente uma animação de giro baixo
			startup_time = 0.22   # Lento, para ser punível se defendido
			active_time = 0.15
			recovery_time = 0.4    # Grande risco se falhar
			hitbox_pos = Vector2(85, 18)
			hitbox_size = Vector2(110, 20)
			if hitbox: hitbox.hit_type = "low" # Obriga defesa agachada
			
		"air":
			# --- PONTAPÉ AÉREO (Voadora) ---
			animation_name = "hk_air"
			startup_time = 0.12
			active_time = 0.25   # Fica ativo durante muito tempo
			recovery_time = 0.2
			hitbox_pos = Vector2(75, 25)
			hitbox_size = Vector2(65, 45)
			if hitbox: hitbox.hit_type = "high" # Overhead

	# =========================================================
	# 3. PROPRIEDADES DE PESO E DANO
	# =========================================================
	if hitbox:
		hitbox.damage = 18.0      # Dano pesado
		hitbox.knockdown = true   # Quase todos os heavy kicks derrubam o inimigo
	
	# Tags para o sistema de combos
	attack_tags = ["Attacking", "Normal", "Heavy", posture.capitalize()]
	
	# Permitimos o cancelamento em especiais (Special Cancel) apenas no chão
	if posture != "air":
		attack_tags.append("Cancellable")
	
	# 4. EXECUÇÃO FINAL
	super.enter(payload)
