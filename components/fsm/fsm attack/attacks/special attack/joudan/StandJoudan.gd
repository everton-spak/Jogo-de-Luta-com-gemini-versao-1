class_name StandJoudan
extends StateAttack

@export var base_impulse_speed: float = 1700.0
@export var base_damage: float = 12.0

func enter(payload: Dictionary = {}) -> void:
	print("🟢 ENTROU NO STAND JOUDAN")
	# =========================================================
	# 1. LEITURA DOS DADOS TÁTICOS (O Payload)
	# =========================================================
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	# =========================================================
	# 2. AJUSTE DE VELOCIDADE (Fraco vs Forte)
	# =========================================================
	var f_dir = facing.current_facing if facing else 1.0
	
	if btn_strength == "light":
		# Chute Fraco: Avança menos, mas recupera mais rápido
		fighter.velocity.x = (base_impulse_speed * 0.4) * f_dir
		startup_time = 0.5
		recovery_time = 0.8
	else:
		# Chute Forte: Avança muito, ideal para punir de longe
		fighter.velocity.x = base_impulse_speed * f_dir
		startup_time = 0.2
		recovery_time = 0.25
		
	active_time = 0.1
	
	# =========================================================
	# 3. MORFOLOGIA DA HITBOX E NÍVEL DE CARGA (Super vs Normal)
	# =========================================================
	hitbox_pos = Vector2(80, -25)
	hitbox_size = Vector2(60, 30)
	
	if hitbox:
		hitbox.damage = base_damage * multiplier # O multiplicador atua aqui!
		
		if charge_level == "super":
			# Se for carregado ao máximo, o golpe derruba e muda de animação
			hitbox.knockdown = true 
			animation_name = "joudan_stand_super"
			attack_tags = ["Attacking", "Special", "Grounded", "Knockdown"]
		else:
			# Joudan normal apenas dá dano padrão
			hitbox.knockdown = false
			animation_name = "joudan_stand"
			attack_tags = ["Attacking", "Special", "Grounded"]
			
	# Passa o bastão para a classe pai
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Trava o personagem no chão assim que a fase ativa termina
	if _phase == 2:
		fighter.velocity.x = 0
		
func exit() -> void:
	print("🔴 SAIU DO STAND JOUDAN")
