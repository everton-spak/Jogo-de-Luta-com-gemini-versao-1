class_name StandTatsumaki
extends StateAttack

@export var base_travel_speed: float = 350.0
@export var base_damage: float = 8.0 # Dano por cada "pulso"
@export var pulse_rate: float = 0.15 

var _pulse_timer: float = 0.0
var current_travel_speed: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	_pulse_timer = 0.0
	var f_dir = facing.current_facing if facing else 1.0
	
	# 1. TEMPO DE GIRO E VELOCIDADE (Fraco vs Forte)
	if btn_strength == "light":
		# Chute Fraco: Roda menos tempo e viaja mais devagar (ótimo para combos curtos)
		active_time = 0.45 
		current_travel_speed = base_travel_speed * 0.6
	else:
		# Chute Forte: Roda quase 1 segundo e atravessa a tela
		active_time = 0.9  
		current_travel_speed = base_travel_speed
		
	startup_time = 0.1
	recovery_time = 0.2
	
	# 2. MORFOLOGIA DA HITBOX E CARGA
	hitbox_pos = Vector2(0, -20)
	hitbox_size = Vector2(100, 30)
	
	if hitbox:
		hitbox.damage = base_damage * multiplier
		if charge_level == "super":
			animation_name = "tatsumaki_spin_super"
			hitbox.knockdown = true # Se for Super, o último hit derruba de certeza!
		else:
			animation_name = "tatsumaki_spin"
			hitbox.knockdown = false
			
	attack_tags = ["Attacking", "Special", "Airborne"]
	
	# Impulso Inicial
	fighter.velocity.y = -200
	fighter.velocity.x = current_travel_speed * f_dir
	
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if _phase == 1:
		fighter.velocity.y = 0 
		var f_dir = facing.current_facing if facing else 1.0
		fighter.velocity.x = current_travel_speed * f_dir
		
		# Multi-hit contínuo
		_pulse_timer += delta
		if _pulse_timer >= pulse_rate:
			_pulse_timer = 0.0
			if hitbox:
				hitbox.disable_box()
				hitbox.enable_box()
