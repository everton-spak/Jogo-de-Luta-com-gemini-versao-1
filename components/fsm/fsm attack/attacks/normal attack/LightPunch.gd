class_name LightPunch
extends StateAttack

# Distância em pixels para ativar o golpe de perto
@export var proximity_threshold: float = 80.0

func enter(payload: Dictionary = {}) -> void:
	# 1. PEGA A POSTURA (Padrão: stand)
	var posture = payload.get("forced_posture", "stand")
	
	# =========================================================
	# 2. LÓGICA DE PROXIMIDADE (Apenas para o estado em pé)
	# =========================================================
	var is_close: bool = false
	if posture == "stand":
		is_close = _is_near_opponent()

	# =========================================================
	# 3. CONFIGURAÇÃO DINÂMICA POR CONTEXTO
	# =========================================================
	match posture:
		"stand":
			if is_close:
				# --- SOCO CURTO (Ex: Cotovelada ou Soco no Estômago) ---
				animation_name = "lp_close"
				startup_time = 0.001    # Mais rápido
				active_time = 0.1
				recovery_time = 0.4
				hitbox_pos = Vector2(40, -35) 
				hitbox_size = Vector2(35, 20)
				# 👇 A MÁGICA AQUI: Este soco SÓ pode cancelar para magias e especiais!
				# (Substitua pelos nomes exatos dos seus estados de magia)
				#cancel_routes = ["StandHadouken", "ShoryukenState"] 
				
				# Pode até remover a tag "Cancellable" das attack_tags, pois já não precisamos dela!
				attack_tags = ["Attacking", "Normal", "Light", "Close", "Stand", "Grounded"]
			else:
				# --- JAB PADRÃO (De longe) ---
				animation_name = "lp_far"
				startup_time = 0.07
				active_time = 0.1
				recovery_time = 0.1
				hitbox_pos = Vector2(70, -35)
				hitbox_size = Vector2(50, 20)
				attack_tags = ["Attacking", "Normal", "Light", "Far", "Stand",]
				# Exemplo: Digamos que o jab de longe NÃO pode ser cancelado em nada.
				#cancel_routes = [] # Lista vazia = nada cancela este golpe! 
			
			if hitbox: hitbox.hit_type = "mid"
			
		"crouch":
			# --- SOCO AGACHADO ---
			animation_name = "lp_crouch"
			startup_time = 0.08
			active_time = 0.1
			recovery_time = 0.2
			hitbox_pos = Vector2(60, -10)
			hitbox_size = Vector2(50, 15)
			attack_tags = ["Attacking", "Normal", "Light", "Crouch", "Cancellable"] # ⚡ Adicionei Cancellable!
			if hitbox: hitbox.hit_type = "mid"
			
		"air":
			# --- SOCO AÉREO (Jump-in) ---
			animation_name = "lp_air"
			startup_time = 0.06
			active_time = 0.2
			recovery_time = 0.3
			hitbox_pos = Vector2(45, 15)
			hitbox_size = Vector2(40, 35)
			attack_tags = ["Attacking", "Normal", "Light", "Air"] # Normalmente não se cancela golpes aéreos
			if hitbox: hitbox.hit_type = "high" # Golpes aéreos costumam ter de ser defendidos de pé (Overhead)
			
	# =========================================================
	# 4. PUXAR O GATILHO (CRUCIAL!)
	# =========================================================
	# Como este script herda de StateAttack, precisamos de mandar o "Pai" 
	# executar a animação e ligar a hitbox usando os números que acabámos de definir!
	super.enter(payload)
