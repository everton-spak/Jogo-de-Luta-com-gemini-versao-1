class_name HitstunState
extends State

var animation_player: AnimationPlayer

# Um timer simples para gerenciar a duração do atordoamento
@onready var stun_timer: Timer = $StunTimer

func _on_initialized() -> void:
	animation_player = fighter.get_node("AnimationPlayer")
	stun_timer.timeout.connect(_on_stun_timeout)

func enter(payload: Dictionary = {}) -> void:
	# Recebe a duração e a força do recuo do golpe (payload = {duration: float, knockback: Vector2})
	var duration = payload.get("duration", 0.3)
	var knockback = payload.get("knockback", Vector2.ZERO)
	
	# Aplica a força de recuo diretamente à velocidade do lutador
	fighter.velocity = knockback
	
	# Toca a animação de dor
	animation_player.play("hitstun")
	
	# Inicia o timer com a duração do atordoamento
	stun_timer.wait_time = duration
	stun_timer.start()

func exit() -> void:
	# Garante que o timer pare caso o estado seja interrompido
	stun_timer.stop()

func physics_update(_delta: float) -> void:
	# No Hitstun, o personagem apenas processa a física do recuo.
	# Podemos aplicar uma pequena fricção para ele não deslizar para sempre.
	fighter.velocity.x = move_toward(fighter.velocity.x, 0, 10)
	
	# Se estiver no ar, aplica gravidade
	if not fighter.is_on_floor():
		fighter.velocity.y += 980 * _delta

func _on_stun_timeout() -> void:
	# O timer acabou! O lutador volta a ter controle.
	# O Padrão Composite + HSM resolve para onde voltar organicamente:
	transition_requested.emit("IdleState")
