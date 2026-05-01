class_name StandHadouken
extends StateAttack

@export var fireball_scene: PackedScene

# Variáveis de controle interno do disparo
var has_fired: bool = false
var fire_multiplier: float = 1.0
var fire_level: String = "normal"

func enter(payload: Dictionary = {}) -> void:
	has_fired = false
	
	# =========================================================
	# 1. LEITURA DO PAYLOAD
	# =========================================================
	fire_multiplier = payload.get("multiplier", 1.0)
	fire_level = payload.get("charge_level", "normal")
	
	# =========================================================
	# 2. FRAME DATA E CONTEXTO
	# =========================================================
	animation_name = "hadouken_stand"
	startup_time = 0.005 
	active_time = 0.05  
	recovery_time = 0.9 
	
	attack_tags = ["Attacking", "Special", "Grounded", "Projectile"]
	fighter.velocity.x = 0
	
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta) 
	
	# =========================================================
	# 3. O DISPARO DETERMINÍSTICO
	# =========================================================
	if _phase == 1 and not has_fired:
		_fire_projectile()
		has_fired = true

func _fire_projectile() -> void:
	if not fireball_scene: return
	
	var fireball = fireball_scene.instantiate()
	var f_dir = facing.current_facing if facing else 1.0
	
	# INJEÇÃO DE DANO E ESCALA NA BOLA DE FOGO
	if fireball.has_method("setup"):
		var trajectory = Vector2(f_dir, 0)
		fireball.setup(fighter, fire_level, fire_multiplier, trajectory)
		
	if fire_level == "super":
		fireball.scale = Vector2(1.5, 1.5) 
		
	# Adiciona a bola de fogo à cena principal do jogo!
	fighter.get_tree().current_scene.add_child(fireball)
	
	# Coloca a bola na posição das mãos do personagem
	fireball.global_position = fighter.global_position + Vector2(100 * f_dir, -30)
