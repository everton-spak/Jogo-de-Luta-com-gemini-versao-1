class_name CrouchTatsumaki
extends StateAttack

@export var base_travel_speed: float = 200.0 
@export var base_damage: float = 7.0
@export var pulse_rate: float = 0.15 

var _pulse_timer: float = 0.0
var current_travel_speed: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var btn_strength = payload.get("button_strength", "heavy")
	var charge_level = payload.get("charge_level", "normal")
	var multiplier = payload.get("multiplier", 1.0)
	
	_pulse_timer = 0.0
	
	if btn_strength == "light":
		active_time = 0.4
		current_travel_speed = base_travel_speed * 0.5
	else:
		active_time = 0.8  
		current_travel_speed = base_travel_speed
		
	startup_time = 0.15
	recovery_time = 0.3
	
	hitbox_pos = Vector2(0, 15) 
	hitbox_size = Vector2(110, 25) 
	
	if hitbox:
		hitbox.damage = base_damage * multiplier
		if charge_level == "super":
			animation_name = "tatsumaki_crouch_super"
			# Super Tatsumaki rasteiro levanta o inimigo para um combo!
			hitbox.hit_type = "launcher" 
		else:
			animation_name = "tatsumaki_crouch"
			hitbox.hit_type = "low" 
			
	attack_tags = ["Attacking", "Special", "Grounded", "Low", "Low_Profile"]
	super.enter(payload)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if _phase == 1:
		var f_dir = facing.current_facing if facing else 1.0
		fighter.velocity.x = current_travel_speed * f_dir
		
		_pulse_timer += delta
		if _pulse_timer >= pulse_rate:
			_pulse_timer = 0.0
			if hitbox:
				hitbox.disable_box()
				hitbox.enable_box()
	elif _phase == 2:
		fighter.velocity.x = 0
