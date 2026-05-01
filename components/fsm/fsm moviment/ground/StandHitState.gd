class_name StandHitState
extends State

@export var hit_friction: float = 2000.0 # O atrito que faz o boneco derrapar no chão após o golpe

var _timer: float = 0.0
var _hitstun_duration: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	
	# ==========================================
	# 1. EXTRAI OS DADOS DO PAYLOAD (Enviados pela Hurtbox)
	# ==========================================
	_hitstun_duration = payload.get("hitstun", 0.3)
	var knockback_x = payload.get("knockback_x", 0.0)
	var attacker = payload.get("attacker", null)
	
	# ==========================================
	# 2. VIRA PARA QUEM BATEU (Auto-Turn / Cross-up Fix)
	# ==========================================
	# Em jogos de luta, se o inimigo pular nas suas costas e te bater (Cross-up),
	# o seu personagem deve virar automaticamente para a cara do inimigo ao apanhar.
	if attacker and facing:
		var dir_to_attacker = sign(attacker.global_position.x - fighter.global_position.x)
		if dir_to_attacker != 0:
			facing.current_facing = dir_to_attacker

	# ==========================================
	# 3. APLICA A FORÇA DE RECUO (Knockback)
	# ==========================================
	if movement:
		# Zera a inércia atual (se ele estava a correr, para na hora)
		fighter.velocity = Vector2.ZERO
		# Dá o empurrão para trás apenas no eixo X (Golpes no chão não levantam)
		movement.apply_impulse(Vector2(knockback_x, 0))
		
	# 4. TOCA A ANIMAÇÃO
	if anim:
		anim.play("hit_stand")

func physics_update(delta: float) -> void:
	_timer += delta
	
	# ==========================================
	# 1. FÍSICA DO RECUO
	# ==========================================
	if movement:
		# O atrito vai travando o boneco suavemente enquanto ele derrapa
		movement.apply_friction(hit_friction, delta)
		movement.apply_gravity(delta)
		movement.commit_movement()
		
	# ==========================================
	# 2. FIM DA DOR (Fim do Hitstun)
	# ==========================================
	if _timer >= _hitstun_duration:
		transition_requested.emit("IdleState")

func exit() -> void:
	# Por segurança, garante que o boneco para de deslizar ao sair do estado
	fighter.velocity.x = 0
	
# Tags: Totalmente vulnerável, no chão, e NÃO pode cancelar (sem "Cancellable")
func get_tags() -> Array[String]:
	return ["Grounded" , "Hitstun"]
