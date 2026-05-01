class_name ShoryukenState
extends State

# Começa invencível e atacando
var _current_tags: Array[String] = ["Attacking", "Grounded", "Invincible"]

@export var jump_impulse: Vector2 = Vector2(200, -900)
@export var active_duration: float = 0.4 # Tempo que a hitbox fica ligada

var _timer: float = 0.0

func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_current_tags = ["Attacking", "Grounded", "Invincible"]
	
	# 1. Aplica o impulso diagonal baseado para onde o personagem olha
	var dir = facing.current_facing if facing else 1.0
	var impulse = Vector2(jump_impulse.x * dir, jump_impulse.y)
	movement.apply_impulse(impulse)
	
	# 2. Ativa Animação e Hitbox
	if anim:
		anim.play("shoryuken")
	if hitbox:
		hitbox.enable_box()
		# Opcional: Ajustar tamanho da hitbox para o soco alto
		hitbox.area_2d.position = Vector2(30 * dir, -60)
		hitbox.collision_shape.shape.size = Vector2(40, 80)

func physics_update(delta: float) -> void:
	_timer += delta
	
	# O Shoryuken ignora o atrito para manter a parábola do pulo
	movement.apply_gravity(delta)
	movement.commit_movement()
	
	# Fase de Transição: Perda de invencibilidade no topo
	if _timer >= active_duration * 0.5 and "Invincible" in _current_tags:
		_current_tags.erase("Invincible")
		_current_tags.append("Recovery")
	
	# Desliga a hitbox no ápice
	if _timer >= active_duration:
		if hitbox: hitbox.disable_box()

	# REGRA HIERÁRQUICA: Se o personagem já subiu e está no ar, 
	# o GroundState pai detectará que is_on_floor() é falso e mudará para AirState.
	# Mas como o Shoryuken é um golpe, ele trava a FSM até terminar ou cair.
	if _timer >= active_duration and fighter.velocity.y > 0:
		transition_requested.emit("FallState", {})

func get_tags() -> Array[String]:
	return _current_tags

func exit() -> void:
	if hitbox: hitbox.disable_box()
