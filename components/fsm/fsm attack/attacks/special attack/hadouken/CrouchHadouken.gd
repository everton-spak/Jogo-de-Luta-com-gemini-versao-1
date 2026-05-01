class_name CrouchHadouken
extends StateAttack

@export var fireball_scene: PackedScene
var has_fired: bool = false

func enter(payload: Dictionary = {}) -> void:
	has_fired = false
	animation_name = "hadouken_crouch"
	
	startup_time = 0.3 # Ligeiramente mais demorado para compensar a evasão
	active_time = 0.1
	recovery_time = 0.35
	
	attack_tags = ["Attacking", "Special", "Grounded", "Projectile", "Low_Profile"]
	
	fighter.velocity.x = 0
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if _phase == 1 and not has_fired:
		_fire_projectile()
		has_fired = true

func _fire_projectile() -> void:
	if not fireball_scene: return
	
	var fireball = fireball_scene.instantiate()
	var f_dir = facing.current_facing if facing else 1.0
	
	if fireball.has_method("setup"):
		fireball.setup(fighter, "normal", 1.0, Vector2(f_dir, 0))
		
	fighter.get_tree().current_scene.add_child(fireball)
	
	# Posição de spawn: Muito mais baixa (Y próximo de 0)
	fireball.global_position = fighter.global_position + Vector2(50 * f_dir, -5)
