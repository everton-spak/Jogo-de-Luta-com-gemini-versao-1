class_name StateAttack
extends State

# Tags que o InputBuffer lerá (ex: "Cancellable" permite interromper o golpe com um especial)
@export var attack_tags: Array[String] = ["Attacking"]

@export_group("Frame Data")
@export var startup_time: float = 0.05
@export var active_time: float = 0.1
@export var recovery_time: float = 0.15

@export_group("Visuals & Hitbox")
@export var animation_name: String = ""
@export var hitbox_pos: Vector2 = Vector2(60, -10)
@export var hitbox_size: Vector2 = Vector2(50, 30)

var _timer: float = 0.0
var _phase: int = 0 # 0: Startup, 1: Active, 2: Recovery



func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_phase = 0
	#print("🎬 TENTANDO TOCAR A ANIMAÇÃO: ", animation_name)
	# 1. Toca a animação específica definida no Inspector
	if anim and animation_name != "":
		anim.play(animation_name)
	
	# 2. Configura a Hitbox para este golpe específico
	_setup_hitbox()
	
	# 👇 NOVO: Mantém o boneco encolhido durante golpes agachados!
	#var posture = _payload.get("forced_posture", "stand")
	#if fighter:
		#fighter.set_posture_collision(posture == "crouch")

func _setup_hitbox() -> void:
	if not hitbox: return
	
	# Garante que começa desligada
	hitbox.disable_box() 
	
	# Inverte a posição horizontal com base no FacingComponent
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.area_2d.position = Vector2(hitbox_pos.x * f_dir, hitbox_pos.y)
	
	# Ajusta o tamanho da colisão (se for um RectangleShape2D)
	if hitbox.collision_shape and hitbox.collision_shape.shape is RectangleShape2D:
		hitbox.collision_shape.shape.size = hitbox_size

func physics_update(_delta: float) -> void:
	_timer += _delta
	
	# =========================================================
	# ⚡ CANCELAMENTOS DO ATAQUE
	# =========================================================
	# O soco/chute continua a mandar: "Só permito cancelar a partir da fase Active!"
	if _phase >= 1:
		# Chama a função do Pai. Se ele retornar true, o combo saiu, então paramos este script com "return"
		if process_cancel_routes():
			return
	# =========================================================
	# MÁQUINA DE ESTADOS INTERNA DO GOLPE
	# =========================================================
	match _phase:
		0: # STARTUP (Preparação)
			if _timer >= startup_time:
				_phase = 1
				if hitbox: hitbox.enable_box()
		
		1: # ACTIVE (Dano ativo)
			if _timer >= (startup_time + active_time):
				_phase = 2
				if hitbox: hitbox.disable_box()
		
		2: # RECOVERY (Recuperação / Vulnerável)
			if _timer >= (startup_time + active_time + recovery_time):
				_on_attack_finished()
func _on_attack_finished() -> void:
	# Pede à StateMachine pai (NormalAttack ou SpecialAttack) para sair.
	# Como o pai não tem "IdleState", ele passará o pedido para a RootStateMachine.
	if fighter.is_on_floor():
		transition_requested.emit("GroundState", {})
	else:
		transition_requested.emit("AirState", {})

func exit() -> void:
	# Limpeza de segurança
	if hitbox: hitbox.disable_box()
	
func get_tags() -> Array[String]:
	return attack_tags
	
#=========================================================
# NOVA FUNÇÃO DE SUPORTE PARA ATAQUES DE PERTO (CLOSE)
# =========================================================
func _is_near_opponent() -> bool:
	# Lê a variável "target_fighter" definida no teu Fighter.gd
	if "target_fighter" in fighter and fighter.target_fighter != null:
		
		# Calcula a distância horizontal entre os dois lutadores
		var distance = abs(fighter.global_position.x - fighter.target_fighter.global_position.x)
		
		# Procura a variável proximity_threshold no script filho (LightPunch, HeavyPunch, etc)
		var threshold = get("proximity_threshold")
		if threshold == null: 
			threshold = 80.0 # Valor padrão de segurança
			
		return distance <= threshold
		
	return false # Se não houver inimigo, ataca sempre de longe
