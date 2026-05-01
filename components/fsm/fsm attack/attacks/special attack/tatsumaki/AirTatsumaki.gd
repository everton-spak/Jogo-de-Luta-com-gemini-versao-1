class_name AirTatsumaki
extends StateAttack

@export var base_travel_speed_x: float = 350.0
@export var hover_fall_speed: float = 50.0 
@export var base_damage: float = 8.0
@export var pulse_rate: float = 0.15 

var _pulse_timer: float = 0.0
var current_travel_x: float = 0.0
var current_fall_speed: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	_pulse_timer = 0.0
	
	if btn_strength == "light":
		# Chute Fraco: Cai mais rápido, ótimo para iniciar combos ao aterrar
		active_time = 0.4
		current_travel_x = base_travel_speed_x * 0.6
		current_fall_speed = hover_fall_speed * 3.0
	else:
		# Chute Forte: Flutua por muito tempo e cruza o espaço aéreo
		active_time = 0.7 
		current_travel_x = base_travel_speed_x
		current_fall_speed = hover_fall_speed
		
	startup_time = 0.1
	recovery_time = 0.25
	
	hitbox_pos = Vector2(0, -10) 
	hitbox_size = Vector2(100, 40)
	
	if hitbox:
		hitbox.damage = base_damage * multiplier
		if charge_level == "super":
			animation_name = "tatsumaki_air_super"
			hitbox.knockdown = true
		else:
			animation_name = "tatsumaki_air"
			hitbox.knockdown = false
			
	attack_tags = ["Attacking", "Special", "Airborne"]
	
	fighter.velocity.y = -100 
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if _phase == 1:
		var f_dir = facing.current_facing if facing else 1.0
		fighter.velocity.x = current_travel_x * f_dir
		fighter.velocity.y = current_fall_speed 
		
		_pulse_timer += delta
		if _pulse_timer >= pulse_rate:
			_pulse_timer = 0.0
			if hitbox:
				hitbox.disable_box()
				hitbox.enable_box()
				
	# Se tocar no chão enquanto roda, aborta e vai para o recovery no chão
	if fighter.is_on_floor() and _phase == 1:
		_phase = 2
		if hitbox: hitbox.disable_box()
		fighter.velocity = Vector2.ZERO
		_timer = startup_time + active_time
