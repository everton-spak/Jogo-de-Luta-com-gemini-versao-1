class_name SlideState
extends State

@export_group("Slide Settings")
@export var slide_speed: float = 700.0       # A velocidade do "tiro" para a frente
@export var slide_friction: float = 1200.0   # O atrito para ele ir freando no chão
@export var slide_duration: float = 0.6      # Tempo máximo de duração da animação/estado
@export var attack_data_name: String = "SlideData" # Os dados da Hitbox de ataque

var _timer: float = 0.0
#var _movement: MovementComponent
#var _hurtbox: Node
var _attack_service: Component

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	#_movement = get_component("MovementComponent")
	#_hurtbox = get_component("HurtboxComponent")
	_attack_service = get_component("Attack")
	
	# 1. PEGA A DIREÇÃO
	var facing = 1.0
	var facing_comp = get_component("FacingComponent")
	if facing_comp:
		facing = facing_comp.current_facing
	
	# 2. IMPULSO DO SLIDE
	if movement:
		# Zera a velocidade e joga o personagem com tudo para a frente
		fighter.velocity = Vector2.ZERO
		movement.apply_impulse(Vector2(slide_speed * facing, 0))
		
	# 3. LOW PROFILE (Fica baixinho para desviar de magias altas)
	if hurtbox and hurtbox.has_method("set_low_profile"):
		hurtbox.set_low_profile(true)
		
	# 4. LIGA A HITBOX DE ATAQUE (Para dar dano nas pernas do inimigo)
	if _attack_service and _attack_service.has_method("get_attack_data"):
		var data = _attack_service.get_attack_data(attack_data_name)
		if data: 
			_attack_service.sync_hitboxes(data)
			
	# 5. ANIMAÇÃO
	anim.play("slide_attack")

func physics_update(delta: float) -> void:
	_timer += delta
	if not movement: return
	
	# ==========================================
	# 1. FÍSICA (Atrito e Gravidade)
	# ==========================================
	# Vai freando o carrinho aos poucos. Isso dá aquele "Game Feel" de ralar no chão
	movement.apply_friction(slide_friction, delta)
	
	# Gravidade para não flutuar caso passe por uma rampa ou buraco
	movement.apply_gravity(delta)
	movement.commit_movement()
	
	# ==========================================
	# 2. TRANSIÇÃO DE SAÍDA
	# ==========================================
	# O slide termina se o tempo acabar ou se a velocidade horizontal chegar muito perto de zero
	if _timer >= slide_duration or abs(fighter.velocity.x) < 50.0:
		# Verifica se o jogador ainda está segurando para baixo
		var input = get_component("Input")
		if input and input.get_movement_direction().y > 0:
			transition_requested.emit("CrouchState") # Termina e continua agachado
		else:
			transition_requested.emit("IdleState")   # Termina e levanta

# ==========================================
# SEGURANÇA MÁXIMA
# ==========================================
func exit() -> void:
	# 1. Restaura o tamanho da Hurtbox
	if hurtbox and hurtbox.has_method("set_low_profile"):
		hurtbox.set_low_profile(false)
		
	# 2. Desliga a Hitbox de ataque caso o inimigo te acerte no meio do carrinho
	if _attack_service and _attack_service.has_method("clear_hitboxes"):
		_attack_service.clear_hitboxes()
	
# Tags: O jogo reconhece que você está no chão, com perfil baixo e atacando!	
func get_tags() -> Array[String]:
	return ["Crouching", "Grounded" , "Attacking"]
