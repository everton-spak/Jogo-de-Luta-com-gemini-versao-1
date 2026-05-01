class_name AirHadouken
extends StateAttack

@export var fireball_scene: PackedScene
var has_fired: bool = false

func enter(payload: Dictionary = {}) -> void:
	has_fired = false
	animation_name = "hadouken_air"
	
	startup_time = 0.03 # Mais rápido no ar
	active_time = 0.03
	recovery_time = 0.9
	
	attack_tags = ["Attacking", "Special", "Airborne", "Projectile"]
	
	# Hang-time (Faz o lutador parar de cair momentaneamente durante o startup)
	fighter.velocity.y = 0 
	
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if _phase == 1 and not has_fired:
		_fire_projectile()
		has_fired = true
		
	# Lógica física pós-disparo (Recuo aéreo)
	if has_fired:
		# Volta a cair, mas o Avô (Attack.gd) já aplica a gravidade universal
		pass

func _fire_projectile() -> void:
	if not fireball_scene: return
	
	var fireball = fireball_scene.instantiate()
	var f_dir = facing.current_facing if facing else 1.0
	
	# RECUO (Pushback): Empurra o lutador levemente para trás e para cima
	fighter.velocity.x = -150 * f_dir
	fighter.velocity.y = -200 
	
	if fireball.has_method("setup"):
		# Trajetória diagonal para baixo! (Y positivo no Godot é para baixo)
		var diag_trajectory = Vector2(f_dir, 0.8).normalized()
		fireball.setup(fighter, "normal", 1.0, diag_trajectory)
		
	fighter.get_tree().current_scene.add_child(fireball)
	
	# Posição de spawn: Mais à frente e ligeiramente abaixo
	fireball.global_position = fighter.global_position + Vector2(40 * f_dir, -10)
