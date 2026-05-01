class_name AirHitState
extends State

# Tags: No ar, a receber dano. Sem "Cancellable", logo não pode fazer NADA.
const STATE_TAGS: Array[String] = ["Airborne", "Hitstun"]

@export var air_drag: float = 300.0 # Um leve atrito no ar para o corpo não voar infinitamente

var _timer: float = 0.0
var _hitstun_duration: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	
	# ==========================================
	# 1. EXTRAI OS DADOS DO LANÇAMENTO
	# ==========================================
	_hitstun_duration = payload.get("hitstun", 0.5)
	var knockback_x = payload.get("knockback_x", 0.0)
	var knockback_y = payload.get("knockback_y", -500.0) # Força para cima!
	var attacker = payload.get("attacker", null)
	
	# ==========================================
	# 2. AUTO-TURN (Vira para quem bateu)
	# ==========================================
	if attacker and facing:
		var dir_to_attacker = sign(attacker.global_position.x - fighter.global_position.x)
		if dir_to_attacker != 0:
			facing.current_facing = dir_to_attacker

	# ==========================================
	# 3. APLICA A FORÇA DO VOO
	# ==========================================
	if movement:
		# Zera a inércia anterior e aplica o arremesso nos dois eixos (X e Y)
		fighter.velocity = Vector2.ZERO
		movement.apply_impulse(Vector2(knockback_x, knockback_y))
		
	# 4. TOCA A ANIMAÇÃO
	if anim:
		anim.play("hit_air")

func physics_update(delta: float) -> void:
	_timer += delta
	
	# ==========================================
	# 1. FÍSICA AÉREA
	# ==========================================
	if movement:
		movement.apply_gravity(delta)
		# O atrito no ar (drag) ajuda a manter os combos dentro do ecrã
		movement.apply_friction(air_drag, delta)
		movement.commit_movement()
		
	# ==========================================
	# 2. CONDIÇÃO A: BATEU NO CHÃO (KNOCKDOWN)
	# ==========================================
	# Se a velocidade Y for positiva (a cair) e ele tocar no chão:
	if fighter.velocity.y > 0 and fighter.is_on_floor():
		# O boneco cai estatelado no chão!
		transition_requested.emit("KnockdownState")
		return
		
	# ==========================================
	# 3. CONDIÇÃO B: RECUPERAÇÃO AÉREA (AIR TECH)
	# ==========================================
	# Se a dor (hitstun) passar ANTES de ele bater no chão:
	if _timer >= _hitstun_duration:
		# Opcional: Pode ter um "AirRecoveryState" aqui para tocar uma 
		# animação de cambalhota no ar. Por agora, volta a cair livremente.
		transition_requested.emit("FallState")
