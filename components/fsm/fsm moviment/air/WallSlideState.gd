class_name WallSlideState
extends State

const STATE_TAGS: Array[String] = ["WallSliding", "Airborne"]

@export var slide_speed: float = 150.0 # Velocidade máxima de descida na parede

func enter(_payload: Dictionary = {}) -> void:
	anim.play("wall_slide")
	# Zera a velocidade vertical para dar aquele "grude" inicial
	fighter.velocity.y = 0

func physics_update(_delta: float) -> void:
	# O AirState já aplica gravidade! 
	# Aqui apenas limitamos a velocidade para o efeito de deslize.
	fighter.velocity.y = min(fighter.velocity.y, slide_speed)
	
	# O AirState também checa se saímos da parede ou tocamos o chão.
	# Aqui checamos apenas o comando de pulo.
	if input.is_action_just_pressed("jump"):
		# Descobrimos para que lado a parede está para pular no sentido oposto
		var wall_normal = fighter.get_wall_normal().x
		transition_requested.emit("WallJumpState", {"wall_normal": wall_normal})
		return
		
	# Se o jogador parar de empurrar o direcional contra a parede, 
	# o AirState detectará isso e nos jogará de volta para o FallState (ou similar).
	
	movement.commit_movement()
