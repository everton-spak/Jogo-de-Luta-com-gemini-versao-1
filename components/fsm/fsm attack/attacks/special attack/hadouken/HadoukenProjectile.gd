class_name HadoukenProjectile
extends Node2D

# =========================================================
# VARIÁVEIS EXPORTADAS (Ajustáveis no Inspector)
# =========================================================
@export var base_speed: float = 600.0
@export var base_damage: float = 10.0 
@export var lifetime: float = 3.0
@export var pulse_rate: float = 0.15 # Tempo entre hits para magias perfurantes

# =========================================================
# VARIÁVEIS INTERNAS DE ESTADO E FÍSICA
# =========================================================
var max_hits: int = 1
var current_hits: int = 0
var _pulse_timer: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var current_speed: float = 600.0
var _timer: float = 0.0

# O componente de colisão que herdámos da nossa arquitetura
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var anim_fireball = $AnimatedSprite2D

func _ready() -> void:
	# Conecta o sinal de impacto da hitbox à nossa função de gestão de hits
	if hitbox:
		hitbox.area_entered.connect(_on_impact)

# =========================================================
# O SETUP INTELIGENTE (Chamado pelo Executor do Ataque)
# =========================================================
func setup(_fighter: Node, level: String, multiplier: float, dir: Vector2, button_strength: String = "heavy") -> void:
	# 1. DIREÇÃO E ROTAÇÃO (Garante que a magia se inclina perfeitamente no ar)
	direction = dir.normalized() 
	rotation = direction.angle()
	
	# Reseta os contadores para garantir uma execução limpa
	current_hits = 0
	_pulse_timer = 0.0
	
	# 2. INJEÇÃO TÉCNICA (Ativação e Multiplicador de Dano)
	if hitbox:
		hitbox.damage = base_damage * multiplier 
		hitbox.enable_box()
		
	# 3. CÁLCULO DE VELOCIDADE PELO BOTÃO (A fundação do Game Design tático)
	var speed_from_button = base_speed
	if button_strength == "light":
		# Magia lenta: excelente para correr atrás dela e encurralar o inimigo
		speed_from_button = base_speed * 0.6 
	elif button_strength == "heavy":
		# Magia rápida: excelente para punir o inimigo à distância
		speed_from_button = base_speed * 1.2 

	# 4. CÁLCULO DE NÍVEL DE CARGA E MUTAÇÃO VISUAL ⭐
	match level:
		"super":
			# --- TÉCNICO (Super Hadouken) ---
			current_speed = speed_from_button * 1.5 
			max_hits = 3 # Torna-se num projétil multi-hit perfurante
			
			# --- VISUAL ---
			# Triplica o tamanho do nó inteiro (o Sprite e a Hitbox aumentam juntos)
			scale = Vector2(3.0, 3.0) 
			
		"strong":
			# --- TÉCNICO ---
			current_speed = speed_from_button * 1.25 
			max_hits = 2 
			
			# --- VISUAL ---
			scale = Vector2(1.3, 1.3) # 30% maior
			
		_:
			# --- TÉCNICO (Hadouken Normal) ---
			current_speed = speed_from_button 
			max_hits = 1 
			
			# --- VISUAL ---
			scale = Vector2(1.0, 1.0) # Tamanho padrão
			
	if anim_fireball:
		anim_fireball.play("fireball") # Inicia a animação da magia a voar/girar

# =========================================================
# CICLO DE VIDA E FÍSICA
# =========================================================
func _physics_process(delta: float) -> void:
	# 1. Movimento linear usando a velocidade final calculada no setup
	global_position += direction * current_speed * delta
	
	# 2. Autodestruição por tempo (Prevenção de Memory Leaks)
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		
	# 3. O Pulso de Dano (Para magias que perfuram e dão múltiplos hits)
	if max_hits > 1 and current_hits < max_hits:
		_pulse_timer += delta
		if _pulse_timer >= pulse_rate:
			_pulse_timer = 0.0
			# Desliga e liga a hitbox no mesmo frame para registar novo dano no inimigo
			if hitbox:
				hitbox.disable_box()
				hitbox.enable_box()

# =========================================================
# GESTÃO DE IMPACTO
# =========================================================
func _on_impact(_area: Area2D) -> void:
	current_hits += 1
	
	# Se já esgotou todos os hits a que tinha direito...
	if current_hits >= max_hits:
		
		# 1. TRAVÃO DE MÃO: Pára a magia no ar para ela não atravessar o inimigo enquanto explode
		current_speed = 0.0 
		
		# 2. SEGURANÇA: Desliga a hitbox para a explosão não dar dano extra por acidente
		if hitbox:
			hitbox.disable_box()
			
		# 3. A ANIMAÇÃO DE EXPLOSÃO
		if anim_fireball:
			anim_fireball.play("fireball_impact")
			
			# A PALAVRA MÁGICA (await): Diz ao código para "pausar" aqui 
			# e só avançar quando a animação de explosão terminar!
			await anim_fireball.animation_finished 
			
		# 4. Só depois de tudo terminar, apagamos a magia da memória
		queue_free()
