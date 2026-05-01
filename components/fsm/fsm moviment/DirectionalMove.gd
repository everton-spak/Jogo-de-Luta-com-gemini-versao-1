class_name DirectionalMove
extends MoveComponent

# =========================================================
# CONFIGURAÇÃO DOS COMANDOS (Ajustável no Inspector)
# =========================================================
@export_group("Sequências de Comando")
# "F" = Forward (Frente), "B" = Backward (Trás), "U" = Up (Cima)
@export var sequence_dash_forward: Array[String] = ["F", "F",]
@export var sequence_dash_backward: Array[String] = ["B", "B",]
 
@export_group("Estados Alvo")
# Os nomes exatos dos nós na tua Máquina de Estados para onde estes comandos vão apontar
@export var state_dash_forward: String = "DashState"
@export var state_dash_backward:String = "DashState"


# Variáveis que o InputBuffer vai ler para saber para onde ir
var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

# =========================================================
# EXECUÇÃO PRINCIPAL
# =========================================================
func check_execution(buffer: InputBuffer) -> bool:
	
	# 1. Tenta a Corrida/Dash (Frente, Frente)
	if not sequence_dash_forward.is_empty() and buffer.is_sequence_buffered(sequence_dash_forward):
		buffer.consume_sequence()
		_prepare_transition(state_dash_forward)
		payload_to_inject = {"is_backdash": false}
		print("💨 DASH PARA FRENTE DETECTADO!")
		return true
		
	# 1. Tenta a Corrida/BackDash (Trás, Trás)
	if not sequence_dash_backward.is_empty() and buffer.is_sequence_buffered(sequence_dash_backward):
		buffer.consume_sequence()
		_prepare_transition(state_dash_backward)
		payload_to_inject = {"is_backdash": true}
		print("💨 DASH PARA TRÁS DETECTADO!")
		return true
	

	return false

# =========================================================
# AUXILIARES
# =========================================================
func _prepare_transition(target_node_name: String) -> void:
	
	dynamic_target_state = target_node_name
