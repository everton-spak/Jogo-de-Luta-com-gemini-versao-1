class_name KnockdownState
extends State

# Tags: No chão, caído e TOTALMENTE INVENCÍVEL para não apanhar no chão
const STATE_TAGS: Array[String] = ["Grounded", "Knockdown", "Invincible"]

@export_group("Knockdown Settings")
@export var slide_friction: float = 1500.0   # Atrito para ele não escorregar muito ao cair
@export var down_duration: float = 0.8       # Quanto tempo fica deitado estatelado (Hard Knockdown)
@export var wakeup_duration: float = 0.4     # Quanto tempo demora a animação de levantar

var _timer: float = 0.0
var _is_waking_up: bool = false

func enter(payload: Dictionary = {}) -> void:
	_timer = 0.0
	_is_waking_up = false
	
	# 1. IMPACTO NO CHÃO
	if movement:
		# Zera a inércia de queda (Y) para o corpo não afundar no chão
		fighter.velocity.y = 0
		
		# Opcional: Se quiser dar um "quique" no chão (Ground Bounce), 
		# você pode ler um valor do payload e aplicar um apply_impulse aqui!
		
	# 2. TOCA A ANIMAÇÃO DO IMPACTO
	if anim:
		anim.play("knockdown_hit")

func physics_update(delta: float) -> void:
	_timer += delta
	
	# ==========================================
	# 1. FÍSICA DO DESLIZE
	# ==========================================
	if movement:
		# Se ele chegou aqui voando do AirHitState, ele vai derrapar um pouco no chão
		movement.apply_friction(slide_friction, delta)
		movement.apply_gravity(delta)
		movement.commit_movement()

	# ==========================================
	# 2. GESTÃO DE TEMPO (FASES DO KNOCKDOWN)
	# ==========================================
	if not _is_waking_up:
		# FASE 1: Deitado no chão
		if _timer >= down_duration:
			_start_wakeup()
	else:
		# FASE 2: Levantando (Wakeup)
		if _timer >= (down_duration + wakeup_duration):
			_finish_wakeup()


func _start_wakeup() -> void:
	_is_waking_up = true
	
	# Trava completamente o movimento para ele levantar no mesmo lugar
	fighter.velocity.x = 0
	
	# Toca a animação de levantar
	if anim:
		anim.play("knockdown_wakeup")

func _finish_wakeup() -> void:
	# Quando termina de levantar, verifica se o jogador já está segurando para baixo.
	# Isso permite que ele já acorde defendendo agachado!
	if input and input.get_movement_direction().y > 0:
		transition_requested.emit("CrouchState")
	else:
		transition_requested.emit("IdleState")

func exit() -> void:
	# Como a invencibilidade é controlada pelas STATE_TAGS na sua Hurtbox,
	# não precisamos forçar o desligamento de nada aqui. A FSM troca de estado 
	# e a tag "Invincible" some naturalmente. Código perfeitamente limpo!
	pass
