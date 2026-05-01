class_name HadoukenState
extends State

# Tags que definem que o personagem está em animação de ataque
const STATE_TAGS: Array[String] = ["Attacking", "Grounded"]

@export var projectile_scene: PackedScene # Arraste sua cena de Hadouken aqui
@export var fire_delay: float = 0.15      # O "ponto doce" onde a magia sai da mão
@export var total_duration: float = 0.5   # Tempo total que o boneco fica travado

var _timer: float = 0.0
var _has_fired: bool = false

func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_has_fired = false
	
	# Trava o movimento horizontal para disparar
	fighter.velocity.x = 0
	
	if anim:
		anim.play("hadouken")

func physics_update(delta: float) -> void:
	_timer += delta
	
	# O GroundState pai já aplica gravidade, então apenas mantemos o corpo no lugar [cite: 5, 6]
	movement.apply_friction(3000.0, delta)
	movement.commit_movement()
	
	# Lógica de Disparo (Fase Active)
	if _timer >= fire_delay and not _has_fired:
		_spawn_projectile()
		_has_fired = true
	
	# Lógica de Saída (Fase Recovery)
	if _timer >= total_duration:
		_evaluate_exit()

func _spawn_projectile() -> void:
	if not projectile_scene: 
		push_warning("HadoukenState: projectile_scene não configurada!")
		return
		
	var p = projectile_scene.instantiate()
	# Usa o FacingComponent para definir a direção do tiro
	var dir = facing.current_facing if facing else 1.0
	
	# Configura posição inicial (ajuste o Vector2 de acordo com seu Sprite)
	p.global_position = fighter.global_position + Vector2(50 * dir, -30)
	
	# Define a direção no script do projétil (assumindo que ele tem uma var 'direction')
	if "direction" in p:
		p.direction = Vector2(dir, 0)
		
	get_tree().root.add_child(p)

func _evaluate_exit() -> void:
	# Após o recovery, voltamos para o estado neutro do GroundState 
	transition_requested.emit("IdleState", {})

func exit() -> void:
	_has_fired = false
