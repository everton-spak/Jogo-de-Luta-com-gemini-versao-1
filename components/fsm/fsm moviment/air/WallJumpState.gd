class_name WallJumpState
extends State

const STATE_TAGS: Array[String] = ["Airborne", "Cancellable"]

@export var jump_force: Vector2 = Vector2(500, -800)

func enter(payload: Dictionary = {}) -> void:
	# O normal da parede aponta PARA FORA dela.
	var wall_normal = payload.get("wall_normal", 0.0)
	
	# Se não recebemos o normal, tentamos descobrir agora
	if wall_normal == 0:
		wall_normal = fighter.get_wall_normal().x
	
	# 1. Aplica o impulso (wall_normal já é a direção para longe da parede)
	fighter.velocity = Vector2.ZERO
	var impulse = Vector2(jump_force.x * wall_normal, jump_force.y)
	movement.apply_impulse(impulse)
	
	# 2. Vira o personagem para olhar para o centro da tela (longe da parede)
	if facing:
		facing.current_facing = wall_normal
		
	anim.play("wall_jump")

func physics_update(_delta: float) -> void:
	# O WallJump é um impulso instantâneo. 
	# Assim que a velocidade vertical começa a cair ou o tempo de animação passa, 
	# o AirState nos levará naturalmente para o FallState através do commit_movement.
	
	movement.commit_movement()
	
	# Se já estamos subindo/descendo e o chute acabou, podemos liberar para o FallState
	# ou deixar o AirState gerenciar o fim do estado.
	if fighter.velocity.y > -200:
		transition_requested.emit("FallState", {})
