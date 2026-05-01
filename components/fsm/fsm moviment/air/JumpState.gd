class_name JumpState
extends State

const STATE_TAGS: Array[String] = ["Airborne", "Cancellable"]

@export_group("Jump Settings")
@export var jump_force: float = 500.0
@export var horizontal_speed: float = 300.0
@export var short_hop_multiplier: float = 0.5 

var _jump_cut: bool = false
var _lenient_frames: int = 0
var _locked_dir: float = 0.0

func enter(_payload: Dictionary = {}) -> void:
	_jump_cut = false 
	# Damos 4 frames de "perdão" para o jogador apertar a direção atrasado
	_lenient_frames = 4 
	
	_locked_dir = 0.0
	if input:
		_locked_dir = input.get_movement_direction().x
		
	if movement:
		movement.apply_jump_force(jump_force)
		fighter.velocity.x = _locked_dir * horizontal_speed

	_play_jump_animation(_locked_dir)

func physics_update(delta: float) -> void:
	if not movement: return
	
	# ==========================================
	# 💡 A MÁGICA DA TOLERÂNCIA (GRACE PERIOD)
	# ==========================================
	if _lenient_frames > 0:
		_lenient_frames -= 1
		# Se ele pulou neutro (0.0), mas de repente o jogador apertou para o lado...
		if _locked_dir == 0.0 and input:
			var late_dir = input.get_movement_direction().x
			if late_dir != 0.0:
				_locked_dir = late_dir # Aceita a correção!
				fighter.velocity.x = _locked_dir * horizontal_speed
				_play_jump_animation(_locked_dir) # Troca a animação na hora
	
	movement.apply_gravity(delta)
	
	# PULO CURTO (Short Hop)
	if not _jump_cut and fighter.velocity.y < 0:
		if input.get_movement_direction().y > -0.5:
			fighter.velocity.y *= short_hop_multiplier
			_jump_cut = true 

	movement.commit_movement()
	
	# Ataques aéreos
	var special_cmd = input_buffer.check_special_moves(get_tags())
	if special_cmd.has("state"):
		transition_requested.emit(special_cmd["state"], special_cmd["payload"])
		return
			
	# Queda
	if fighter.velocity.y >= 0:
		transition_requested.emit("FallState")

# Função auxiliar para não repetirmos código de animação
func _play_jump_animation(dir: float) -> void:
	var facing_dir = 1.0
	var facing_comp = get_component("FacingComponent")
	if facing_comp:
		facing_dir = facing_comp.current_facing

	if dir == 0.0:
		if anim: anim.play("jump_neutral")
	elif sign(dir) == sign(facing_dir):
		if anim: anim.play("jump_forward")
	else:
		if anim: anim.play("jump_backward")

func get_tags() -> Array[String]:
	return ["Jumping", "Cancellable"]
