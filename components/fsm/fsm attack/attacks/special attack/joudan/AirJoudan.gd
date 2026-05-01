class_name AirJoudan
extends StateAttack

@export var dive_speed_x: float = 350.0
@export var dive_speed_y: float = 400.0
@export var base_damage: float = 10.0

var current_dive_x: float = 0.0
var current_dive_y: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	var f_dir = facing.current_facing if facing else 1.0
	
	# =========================================================
	# TÁTICA DO DIVEKICK: O Botão muda o ângulo de mergulho!
	# =========================================================
	if btn_strength == "light":
		# Chute Fraco: Cai muito a pique (quase a direito para baixo) e mais rápido
		current_dive_x = dive_speed_x * 0.4 * f_dir
		current_dive_y = dive_speed_y * 1.2
	else:
		# Chute Forte: Cai numa diagonal longa (atravessa mais a tela)
		current_dive_x = dive_speed_x * f_dir
		current_dive_y = dive_speed_y
		
	# FRAME DATA
	startup_time = 0.1
	active_time = 0.3 
	recovery_time = 0.2
	
	# MORFOLOGIA DA HITBOX
	hitbox_pos = Vector2(40, 30)
	hitbox_size = Vector2(50, 60)
	
	if hitbox:
		hitbox.damage = base_damage * multiplier
		
		if charge_level == "super":
			# Se for carregado, o inimigo bate no chão e quica de volta!
			animation_name = "joudan_air_super"
			hitbox.hit_type = "ground_bounce"
		else:
			animation_name = "joudan_air"
			hitbox.hit_type = "high"
			
	attack_tags = ["Attacking", "Special", "Airborne", "Overhead"]
	
	# Aplica o impulso inicial
	fighter.velocity.x = current_dive_x
	fighter.velocity.y = current_dive_y
	
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Durante a fase ativa, garante que o mergulho é um míssil perfeito
	if _phase == 1:
		fighter.velocity.y = current_dive_y
	
	# =========================================================
	# A CORREÇÃO: Transição forçada ao tocar no chão
	# =========================================================
	if fighter.is_on_floor() and _phase == 1:
		# 1. Muda para a fase de Recovery (2)
		_phase = 2
		
		# 2. Desliga a hitbox manualmente para não dar dano enquanto aterra
		if hitbox: 
			hitbox.disable_box()
			
		# 3. Trava o personagem no chão para ele não deslizar
		fighter.velocity = Vector2.ZERO
		
		# 4. A MÁGICA: Adianta o relógio da classe StateAttack!
		# Isso faz com que a fase de recovery comece a contar exatamente a partir de agora.
		_timer = startup_time + active_time
