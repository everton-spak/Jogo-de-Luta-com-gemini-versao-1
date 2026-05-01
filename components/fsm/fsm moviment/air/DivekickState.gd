class_name DivekickState
extends State

# Tags: O jogo agora sabe que durante este golpe você está no ar e atacando
const STATE_TAGS: Array[String] = ["Airborne", "Attacking"]

@export_group("Divekick Physics")
@export var dive_speed_x: float = 600.0
@export var dive_speed_y: float = 900.0
@export var stall_duration: float = 0.1
@export var attack_data_name: String = "DivekickData" # O nome do nó de Hitbox no seu AttackComponent

var _timer: float = 0.0
var _is_diving: bool = false
#var movement: MovementComponent
var _attack_service: Component # Usamos Component genérico para evitar erros se a classe mudar

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	_is_diving = false
	movement = get_component("MovementComponent")
	_attack_service = get_component("Attack")
	
	# 1. O "CONGELAMENTO" (Stall)
	# Zera a velocidade atual para quebrar a inércia do pulo e parar no ar
	fighter.velocity = Vector2.ZERO
	
	# 2. SINCRONIZA A HITBOX
	if _attack_service and _attack_service.has_method("get_attack_data"):
		var data = _attack_service.get_attack_data(attack_data_name)
		if data: 
			_attack_service.sync_hitboxes(data)
			
	# 3. ANIMAÇÃO DE PREPARAÇÃO
	anim.play("divekick_startup")

func physics_update(delta: float) -> void:
	_timer += delta
	if not movement: return
	
	# ==========================================
	# FASE 1: PREPARAÇÃO NO AR (O Stall)
	# ==========================================
	if not _is_diving:
		# Força a ficar parado no ar caso alguma força tente empurrá-lo
		fighter.velocity = Vector2.ZERO
		
		if _timer >= stall_duration:
			_start_dive()
			
	# ==========================================
	# FASE 2: O MERGULHO
	# ==========================================
	else:
		# Pega a direção
		var facing = 1.0
		var facing_comp = get_component("FacingComponent")
		if facing_comp:
			facing = facing_comp.current_facing
			
		# Durante o mergulho, a gravidade não age normalmente. 
		# Ele vira um míssil com velocidade constante e cravada em 45 graus.
		fighter.velocity = Vector2(dive_speed_x * facing, dive_speed_y)
		
		# ATERRISSAGEM (O momento em que atinge o chão)
		if fighter.is_on_floor():
			_land()
			
	# Executa a física do frame
	movement.commit_movement()

func _start_dive() -> void:
	_is_diving = true
	anim.play("divekick_active")

func _land() -> void:
	# 1. Trava o deslizamento
	fighter.velocity.x = 0
	
	# 2. Desliga as Hitboxes para o golpe não continuar ativo no chão
	if _attack_service and _attack_service.has_method("clear_hitboxes"):
		_attack_service.clear_hitboxes()
	
	# 3. Volta para o Idle (ou um "LandingRecoveryState" se for um golpe punível)
	transition_requested.emit("IdleState")

# ==========================================
# SEGURANÇA MÁXIMA
# ==========================================
func exit() -> void:
	# Se o seu personagem tomar um Shoryuken do inimigo no meio do Divekick,
	# este exit() garante que as hitboxes do pé dele sejam desligadas!
	if _attack_service and _attack_service.has_method("clear_hitboxes"):
		_attack_service.clear_hitboxes()
