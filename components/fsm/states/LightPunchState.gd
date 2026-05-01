class_name LightPunchState
extends State

# Tags dinâmicas que serão ajustadas no enter()
var _current_tags: Array[String] = ["Attacking"]

@export_group("Attack Frame Data")
@export var startup_time: float = 0.05
@export var active_time: float = 0.1
@export var recovery_time: float = 0.15

var _timer: float = 0.0
var _phase: int = 0 # 0: Startup, 1: Active, 2: Recovery
var _is_air_attack: bool = false

func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_phase = 0
	_is_air_attack = not fighter.is_on_floor()
	
	# Garantimos que a hitbox começa desligada antes de a posicionarmos
	if hitbox: hitbox.disable_box()
	
	_setup_attack_context()

func _setup_attack_context() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	
	# ==========================================
	# CONFIGURAÇÃO DINÂMICA DE CAIXAS E ANIMS
	# ==========================================
	
	if _is_air_attack:
		# 1. ATAQUE AÉREO
		_current_tags = ["Airborne", "Attacking"]
		anim.play("light_punch_air")
		# Posiciona a Hitbox para um soco aéreo (ex: ligeiramente para baixo e frente)
		if hitbox:
			hitbox.area_2d.position = Vector2(45 * f_dir, 15)
			hitbox.collision_shape.shape.size = Vector2(50, 30)

	elif input.get_movement_direction().y > 0.5:
		# 2. ATAQUE AGACHADO
		_current_tags = ["Grounded", "Crouching", "Attacking"]
		anim.play("light_punch_crouch")
		fighter.velocity.x = 0
		# Posiciona a Hitbox rente ao chão
		if hitbox:
			hitbox.area_2d.position = Vector2(55 * f_dir, 40)
			hitbox.collision_shape.shape.size = Vector2(65, 25)
			
	else:
		# 3. ATAQUE EM PÉ (STAND)
		_current_tags = ["Grounded", "Attacking"]
		anim.play("light_punch_stand")
		fighter.velocity.x = 0
		# Posiciona a Hitbox na altura do peito/rosto
		if hitbox:
			hitbox.area_2d.position = Vector2(60 * f_dir, -10)
			hitbox.collision_shape.shape.size = Vector2(55, 30)

func physics_update(delta: float) -> void:
	_timer += delta
	
	# Gestão de Física
	if _is_air_attack:
		movement.apply_gravity(delta)
	else:
		movement.apply_friction(2500.0, delta)
	movement.commit_movement()

	# Máquina de Estados do Golpe
	match _phase:
		0: # STARTUP
			if _timer >= startup_time:
				_phase = 1
				if hitbox: hitbox.enable_box()
		1: # ACTIVE
			if _timer >= (startup_time + active_time):
				_phase = 2
				if hitbox: hitbox.disable_box()
		2: # RECOVERY
			if _timer >= (startup_time + active_time + recovery_time):
				_evaluate_exit()

func _evaluate_exit() -> void:
	if _is_air_attack:
		transition_requested.emit("FallState", {})
	else:
		if input.get_movement_direction().y > 0.5:
			transition_requested.emit("CrouchState", {})
		else:
			transition_requested.emit("IdleState", {})

func exit() -> void:
	if hitbox: hitbox.disable_box()

# Importante: O InputBuffer precisa de ler as tags que definimos no enter()
func get_tags() -> Array[String]:
	return _current_tags
