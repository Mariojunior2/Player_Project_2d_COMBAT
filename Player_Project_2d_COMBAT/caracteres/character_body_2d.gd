extends CharacterBody2D

@export var attack_cooldown := 0.5
@export var max_attack_duration := 1.2  # máximo segurando ataque (s)
@export var dash_speed := 800.0
@export var dash_duration := 0.3

const CHARGED_ATTACK_THRESHOLD := 1.4  # tempo mínimo para ataque carregado

var can_attack := true
var is_charging := false
var is_dashing := false
var attack_timer := 0.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var gravity := 0.0

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

enum WeaponState { SWORD, GUN }
var current_weapon: WeaponState = WeaponState.SWORD
var can_switch_weapon := true
const SWITCH_DELAY := 0.5

func _ready():
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	_update_weapon_state()
	$AttackHitbox.monitoring = false
	$AttackHitbox.get_node("CollisionShape2D").disabled = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_weapon"):
		_attempt_switch()

	if current_weapon == WeaponState.SWORD:
		if not is_dashing:
			if Input.is_action_just_pressed("attack") and can_attack and not is_charging:
				start_charge()

			if is_charging and Input.is_action_pressed("attack"):
				attack_timer += delta
				attack_timer = min(attack_timer, max_attack_duration)
				$AnimatedSprite2D.play("charge") # aqui irei trocar animacao para animacao de carregar 

			if is_charging and not Input.is_action_pressed("attack"):
				if attack_timer >= CHARGED_ATTACK_THRESHOLD:
					start_charged_attack()
				else:
					start_simple_attack()

	if not is_charging and not is_dashing:
		update_idle_run_animation()

func start_charge() -> void:
	can_attack = false
	is_charging = true
	attack_timer = 0.0
	$AnimatedSprite2D.play("attack")
	$AttackHitbox.monitoring = false
	$AttackHitbox.get_node("CollisionShape2D").disabled = true

func start_simple_attack() -> void:
	is_charging = false
	is_dashing = true
	dash_timer = dash_duration
	dash_direction = (get_global_mouse_position() - global_position).normalized()
	$AttackHitbox.monitoring = true
	$AttackHitbox.get_node("CollisionShape2D").disabled = false
	$AnimatedSprite2D.play("attack")

	await get_tree().create_timer(dash_duration).timeout
	end_dash()

func start_charged_attack() -> void:
	is_charging = false
	is_dashing = true
	dash_timer = dash_duration * 1.5
	dash_direction = (get_global_mouse_position() - global_position).normalized()
	$AttackHitbox.monitoring = true
	$AttackHitbox.get_node("CollisionShape2D").disabled = false
	$AnimatedSprite2D.play("charged_attack")

	await get_tree().create_timer(dash_duration * 1.5).timeout
	end_dash()

func end_dash() -> void:
	is_dashing = false
	$AttackHitbox.monitoring = false
	$AttackHitbox.get_node("CollisionShape2D").disabled = true
	$AnimatedSprite2D.play("idle")

	can_attack = false
	attack_timer = 0.0
	_start_attack_cooldown()

func _start_attack_cooldown() -> void:
	var timer = get_tree().create_timer(attack_cooldown)
	timer.connect("timeout", Callable(self, "_on_attack_cooldown_timeout"))

func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func update_idle_run_animation() -> void:
	if is_on_floor():
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			$AnimatedSprite2D.play("run") # aqui colocarei uma animacao de corrida
			$AnimatedSprite2D.flip_h = direction < 0
		else:
			$AnimatedSprite2D.play("idle")

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if is_dashing and current_weapon == WeaponState.SWORD:
		var current_dash_speed = dash_speed
		if $AnimatedSprite2D.animation == "charged_attack":
			current_dash_speed *= 1.5

		velocity = dash_direction * current_dash_speed

		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	else:
		if not is_charging:
			var direction := Input.get_axis("ui_left", "ui_right")
			if direction != 0:
				velocity.x = direction * SPEED
				$AnimatedSprite2D.flip_h = direction < 0
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			velocity.x = 0

	move_and_slide()

func _attempt_switch() -> void:
	if not can_switch_weapon:
		return
	can_switch_weapon = false

	if current_weapon == WeaponState.SWORD:
		current_weapon = WeaponState.GUN
	else:
		current_weapon = WeaponState.SWORD

	_update_weapon_state()

	await get_tree().create_timer(SWITCH_DELAY).timeout
	can_switch_weapon = true

func _update_weapon_state() -> void:
	if current_weapon == WeaponState.SWORD:
		$Arma.hide()
		$AttackHitbox.monitoring = false
		$AttackHitbox.get_node("CollisionShape2D").disabled = true
	elif current_weapon == WeaponState.GUN:
		$Arma.show()
		$AttackHitbox.monitoring = false
		$AttackHitbox.get_node("CollisionShape2D").disabled = true
