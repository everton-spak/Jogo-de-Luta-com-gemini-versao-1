class_name CrouchJoudan
extends StateAttack

@export var sweep_speed: float = 300.0
@export var base_damage: float = 10.0

func enter(payload: Dictionary = {}) -> void:
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	var f_dir = facing.current_facing if facing else 1.0
	
	# Se for o Chute Fraco, o deslize rasteiro é mais curto e rápido
	if btn_strength == "light":
		fighter.velocity.x = (sweep_speed * 0.5) * f_dir
		startup_time = 0.15
	else:
		fighter.velocity.x = sweep_speed * f_dir
		startup_time = 0.25
		
	active_time = 0.12
	recovery_time = 0.3
	
	hitbox_pos = Vector2(70, 10)
	hitbox_size = Vector2(90, 20)
	
	if hitbox:
		hitbox.damage = base_damage * multiplier
		
		if charge_level == "super":
			# O Joudan Rasteiro Super joga o inimigo para o ar para combos!
			animation_name = "joudan_crouch_super"
			hitbox.hit_type = "launcher" 
			attack_tags = ["Attacking", "Special", "Grounded", "Low", "Launcher"]
		else:
			animation_name = "joudan_crouch"
			hitbox.hit_type = "low" 
			attack_tags = ["Attacking", "Special", "Grounded", "Low", "Knockdown"]
			
	super.enter(payload)
