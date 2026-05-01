class_name DualAttackState
extends StateAttack

func enter(payload: Dictionary = {}) -> void:
	var dir = payload.get("direction_tag", "neutral")
	
	# =========================================================
	# CONFIGURAÇÃO POR DIREÇÃO
	# =========================================================
	match dir:
		"forward":
			# Ex: Soco de avanço (Step Punch)
			animation_name = "dual_punch_forward"
			startup_time = 0.15
			hitbox_pos = Vector2(80, -40)
			hitbox_size = Vector2(60, 30)
			fighter.velocity.x = 200 * facing.current_facing # Dá um passinho a frente
			
		"down":
			# Ex: Golpe baixo duplo (Ground Sweep)
			animation_name = "dual_punch_down"
			startup_time = 0.12
			hitbox_pos = Vector2(50, 15)
			hitbox_size = Vector2(70, 20)
			if hitbox: hitbox.hit_type = "low"
			
		"down_forward":
			# Ex: Gancho diagonal (Anti-Air)
			animation_name = "dual_punch_df"
			startup_time = 0.1
			hitbox_pos = Vector2(60, -70) # Bate alto e inclinado
			hitbox_size = Vector2(40, 60)
			if hitbox: hitbox.hit_type = "mid"
			
		_: # Neutral (Nenhuma direção ou outras)
			animation_name = "dual_punch_neutral"
			startup_time = 0.1
			hitbox_pos = Vector2(60, -35)
			hitbox_size = Vector2(50, 20)

	# Configurações de dano (Maior que um soco normal, menor que um especial)
	if hitbox:
		hitbox.damage = 10.0
		hitbox.knockdown = (dir == "down") # Derruba se for o golpe de baixo
	
	attack_tags = ["Attacking", "CommandNormal", dir.capitalize()]
	
	super.enter(payload)
