class_name SpecialAttack
extends StateMachine

# Tags que definem a categoria de golpes especiais
var _category_tags: Array[String] = ["Special"]

func _on_enter(payload: Dictionary = {}) -> void:
	# Chama a lógica do Avô (Attack.gd) para física e segurança
	super._on_enter(payload)
	
	# Diferente do NormalAttack, NÃO zeramos a velocity.x aqui.
	# Isso permite que golpes como o Joudan ou Hadouken herdem o 
	# impulso que o próprio filho definir no seu enter().
	
	# Exemplo: Lógica de gasto de barra de energia (EX Moves) pode ficar aqui
	if payload.get("is_ex", false):
		_category_tags.append("EX_Move")

func get_machine_tags() -> Array[String]:
	return _category_tags
	
func _on_exit() -> void:
	super._on_exit()
	_category_tags = ["Special"] # Reseta para a próxima entrada
