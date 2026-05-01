class_name StandBlockState
extends State

@export var block_friction: float = 2500.0 # Atrito forte para o pushback não ser exagerado

var _timer: float = 0.0
var _blockstun_duration: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	
	# ==========================================
	# 1. LÊ OS DADOS DO IMPACTO (Vindos da Hurtbox)
	# ==========================================
	# Geralmente, o Blockstun é um pouco menor que o Hitstun original do golpe
	_blockstun_duration = payload.get("hitstun", 0.3) * 0.8 
	var knockback_x = payload.get("knockback", 0.0)
	var chip_damage = payload.get("damage", 0.0)
	
	# ==========================================
	# 2. APLICA CHIP DAMAGE (Se houver)
	# ==========================================
	if chip_damage > 0:
		var health = get_component("HealthComponent")
		if health:
			health.take_damage(chip_damage)
	
	# ==========================================
	# 3. APLICA O PUSHBACK (Recuo da Defesa)
	# ==========================================
	if movement:
		# Pega a direção que o personagem está a olhar. 
		# O recuo da defesa empurra-o sempre de costas para o ataque!
		var facing_dir = facing.current_facing if facing else 1.0
		
		# Zera a inércia atual e empurra para trás
		fighter.velocity = Vector2.ZERO
		movement.apply_impulse(Vector2(-facing_dir * abs(knockback_x), 0))
		
	# 4. TOCA A ANIMAÇÃO
	if anim:
		anim.play("block_stand")

func physics_update(delta: float) -> void:
	_timer += delta
	
	# ==========================================
	# 1. FÍSICA DO RECUO
	# ==========================================
	if movement:
		movement.apply_friction(block_friction, delta)
		movement.apply_gravity(delta)
		movement.commit_movement()
		
	# ==========================================
	# 2. FIM DA TRAVA DE DEFESA (BLOCKSTUN)
	# ==========================================
	if _timer >= _blockstun_duration:
		_evaluate_exit()

func _evaluate_exit() -> void:
	# Quando o impacto da defesa acaba, o que o jogador está a fazer?
	if not input:
		transition_requested.emit("IdleState")
		return
		
	var dir = input.get_movement_direction()
	
	# Continua a segurar para trás? (Pode estar a manter a Guarda de Proximidade)
	if dir.x != 0 and facing and dir.x == -facing.current_facing:
		# Se estiver a segurar a diagonal para baixo/trás, vai para a defesa agachada!
		if dir.y > 0:
			transition_requested.emit("CrouchBlockState")
		else:
			transition_requested.emit("WalkState") # Recua normalmente
		return
		
	# Soltou para trás, mas segurou para baixo?
	if dir.y > 0:
		transition_requested.emit("CrouchState")
		return
		
	# Não está a segurar nada de especial
	transition_requested.emit("IdleState")

func exit() -> void:
	# Garante que o pushback para completamente ao sair do estado
	fighter.velocity.x = 0

# Tags: No chão e defendendo. Sem "Cancellable" (não pode atacar enquanto defende o impacto)	
func get_tags() -> Array[String]:
	return ["Blocking", "Grounded" , "Blockstun"]
