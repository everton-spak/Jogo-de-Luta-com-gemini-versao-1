class_name Shoryuken
extends StateAttack

@export_group("Shoryuken Physics")
@export var vertical_force: float = -700.0
@export var forward_drift: float = 200.0

var _has_launched: bool = false

func enter(payload: Dictionary = {}) -> void:
	_has_launched = false
	
	# 1. PEGA A FORÇA DO GOLPE (Light vs Heavy)
	var strength = payload.get("strength", "light")
	
	# =========================================================
	# 2. CONFIGURAÇÃO DE FRAME DATA E FORÇA
	# =========================================================
	if strength == "light":
		animation_name = "shoryuken_light"
		startup_time = 0.05
		active_time = 0.2
		recovery_time = 0.4
		vertical_force = -650.0  # Sobe menos, recupera mais rápido
		forward_drift = 150.0
		if hitbox: hitbox.damage = 12.0
	else:
		animation_name = "shoryuken_heavy"
		startup_time = 0.08
		active_time = 0.3
		recovery_time = 0.6
		vertical_force = -900.0  # Sobe muito alto!
		forward_drift = 250.0
		if hitbox: hitbox.damage = 18.0

	# 3. HITBOX E TAGS
	hitbox_pos = Vector2(50, -60) # Hitbox sobe junto com o personagem
	hitbox_size = Vector2(40, 80) # Hitbox verticalmente longa
	
	attack_tags = ["Attacking", "Special", "DP", "Airborne", strength.capitalize()]
	
	# Chama o enter do StateAttack para iniciar os timers
	super.enter(payload)

# =========================================================
# LÓGICA DE MOVIMENTO (A ASCENSÃO)
# =========================================================
func physics_update(delta: float) -> void:
	# Chamamos o super para rodar os timers da StateAttack
	super.physics_update(delta)
	
	# FASE 0: STARTUP (No chão, preparando)
	if _phase == 0:
		fighter.velocity.x = 0
		
	# FASE 1: ACTIVE (O MOMENTO DO SALTO)
	elif _phase == 1 and not _has_launched:
		_launch_character()
		
	# FASE 1 e 2: NO AR (Controle de queda)
	if _phase >= 1:
		# Aplicamos um pouco de movimento para frente para o Shoryuken não ser puramente vertical
		var f_dir = facing.current_facing if facing else 1.0
		fighter.velocity.x = forward_drift * f_dir
		
		# NOTA: A gravidade já é aplicada pelo Attack.gd (Avô), 
		# então não precisamos de a aplicar aqui novamente.

func _launch_character() -> void:
	_has_launched = true
	# Aplica o impulso vertical
	fighter.velocity.y = vertical_force
	
	# Opcional: Invencibilidade de frames iniciais (comum em DPs)
	# var health = fighter.get_component("HealthComponent")
	# if health: health.set_invulnerable(0.1)

func exit() -> void:
	_has_launched = false
	super.exit()
