extends CharacterBody2D
## Player: movement (Step 1) + stats (Step 2) + wrench attack (Step 3).

signal hp_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal infection_changed(current: float)
signal hit_landed(body: Node2D)
signal died

enum AttackState { NONE, WINDUP, ACTIVE, RECOVERY }

const PX_PER_METER := 16.0
const STAND_HEIGHT := 24.0
const CROUCH_HEIGHT := 14.0

@export var balance: Balance

# --- Jump feel ---
@export var jump_height_px := 40.0
@export var jump_time_to_apex := 0.38
@export var fall_gravity_multiplier := 1.5
@export var jump_cut_multiplier := 0.5
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.10
@export var acceleration := 600.0
@export var friction := 900.0

# --- Public state ---
var hp := 100.0
var stamina := 100.0
var infection_pct := 0.0
var is_dead := false
var is_crouching := false
var is_sprinting := false
var facing := 1  # 1 = right, -1 = left

var _gravity := 0.0
var _jump_velocity := 0.0
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _recharge_timer := 0.0
var _sprint_locked := false

# --- Attack state ---
var _attack_state := AttackState.NONE
var _attack_timer := 0.0
var _attack_buffer := 0.0
var _swing_exhausted := false
var _hit_this_swing: Array[Node] = []

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = get_node_or_null("Visual")
@onready var _hitbox: Area2D = $AttackHitbox
@onready var _flash: CanvasItem = get_node_or_null("AttackHitbox/Flash")
@onready var _hit_sound: AudioStreamPlayer = get_node_or_null("HitSound") as AudioStreamPlayer


func _ready() -> void:
	add_to_group("player")
	if balance == null:
		balance = Balance.new()
	_register_inputs()

	_gravity = 2.0 * jump_height_px / pow(jump_time_to_apex, 2.0)
	_jump_velocity = -2.0 * jump_height_px / jump_time_to_apex

	hp = balance.player_max_hp
	stamina = balance.player_max_stamina
	infection_pct = 0.0

	_shape.shape = _shape.shape.duplicate()
	_apply_height(STAND_HEIGHT)

	_hitbox.monitoring = false
	if _flash:
		_flash.visible = false


# ---------------------------------------------------------------- Stats API
func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp = clampf(hp - amount, 0.0, balance.player_max_hp)
	hp_changed.emit(hp, balance.player_max_hp)
	if hp <= 0.0:
		_die()


func heal(amount: float) -> void:
	if is_dead:
		return
	hp = clampf(hp + amount, 0.0, balance.player_max_hp)
	hp_changed.emit(hp, balance.player_max_hp)


func add_infection(amount: float) -> void:
	if is_dead:
		return
	infection_pct = clampf(infection_pct + amount, 0.0, 100.0)
	infection_changed.emit(infection_pct)
	if infection_pct >= 100.0:
		_die()


func cure_infection(amount: float = 100.0) -> void:
	infection_pct = clampf(infection_pct - amount, 0.0, 100.0)
	infection_changed.emit(infection_pct)


func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		return false
	_set_stamina(stamina - cost)
	_recharge_timer = balance.stamina_recharge_delay
	return true


func drain_all_stamina() -> void:
	_set_stamina(0.0)
	_recharge_timer = balance.stamina_recharge_delay


func _set_stamina(value: float) -> void:
	var v := clampf(value, 0.0, balance.player_max_stamina)
	if is_equal_approx(v, stamina):
		return
	stamina = v
	stamina_changed.emit(stamina, balance.player_max_stamina)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	_end_attack()
	died.emit()
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- Input helpers
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_damage"):
		take_damage(20.0)
	elif event.is_action_pressed("debug_heal"):
		heal(30.0)
	elif event.is_action_pressed("debug_infect"):
		add_infection(balance.infection_per_bite)


func _notification(what: int) -> void:
	# GDD edge case: pausing during a swing clears the input buffer (no accidental double swing)
	if what == NOTIFICATION_PAUSED:
		_attack_buffer = 0.0


# ---------------------------------------------------------------- Main loop
func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	_update_crouch(on_floor)
	var dir := Input.get_axis("move_left", "move_right")

	# Facing is locked while swinging so the hit lands where you started it
	if dir != 0.0 and _attack_state == AttackState.NONE:
		facing = 1 if dir > 0.0 else -1
		_hitbox.scale.x = facing

	_update_attack(delta)
	_update_sprint(dir, delta)

	var speed_m := balance.walk_speed_m
	if is_crouching:
		speed_m = balance.crouch_speed_m
	elif is_sprinting:
		speed_m = balance.player_run_speed
	var target_speed := speed_m * PX_PER_METER
	if _attack_state != AttackState.NONE:
		target_speed *= balance.attack_move_multiplier

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not on_floor:
		var g := _gravity
		if velocity.y > 0.0:
			g *= fall_gravity_multiplier
		velocity.y += g * delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and not is_crouching:
		velocity.y = _jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	move_and_slide()


# ---------------------------------------------------------------- Attack
func _update_attack(delta: float) -> void:
	# Remember a press so a swing queued slightly early still happens
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = balance.attack_buffer_time
	else:
		_attack_buffer -= delta

	match _attack_state:
		AttackState.NONE:
			if _attack_buffer > 0.0:
				_start_attack()

		AttackState.WINDUP:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_state = AttackState.ACTIVE
				_attack_timer = _phase_time(balance.wrench_active)
				_hit_this_swing.clear()
				_hitbox.monitoring = true
				if _flash:
					_flash.visible = true

		AttackState.ACTIVE:
			_process_hits()
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_hitbox.monitoring = false
				if _flash:
					_flash.visible = false
				_attack_state = AttackState.RECOVERY
				_attack_timer = _phase_time(balance.wrench_recovery)

		AttackState.RECOVERY:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_state = AttackState.NONE


func _start_attack() -> void:
	_attack_buffer = 0.0
	# Not enough stamina -> weak "exhausted swing": drains the rest, slower, weaker
	_swing_exhausted = stamina < balance.stamina_cost_swing
	if _swing_exhausted:
		drain_all_stamina()
	else:
		spend_stamina(balance.stamina_cost_swing)
	_attack_state = AttackState.WINDUP
	_attack_timer = _phase_time(balance.wrench_windup)


## Exhausted swings run at 50% speed, so every phase lasts longer.
func _phase_time(base: float) -> float:
	return base / balance.exhausted_speed_scale if _swing_exhausted else base


func _process_hits() -> void:
	var damage := balance.exhausted_swing_damage if _swing_exhausted else balance.wrench_base_damage
	var stagger := balance.exhausted_stagger_duration if _swing_exhausted else balance.stagger_duration_seconds
	for body in _hitbox.get_overlapping_bodies():
		if body == self or body in _hit_this_swing:
			continue
		if body.has_method("take_hit"):
			_hit_this_swing.append(body)
			body.take_hit(damage, stagger, global_position)
			hit_landed.emit(body)
			if _hit_sound:
				_hit_sound.play()


func _end_attack() -> void:
	_attack_state = AttackState.NONE
	_hitbox.monitoring = false
	if _flash:
		_flash.visible = false


# ---------------------------------------------------------------- Crouch / sprint
func _update_crouch(on_floor: bool) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch and on_floor and not is_crouching:
		is_crouching = true
		_apply_height(CROUCH_HEIGHT)
	elif is_crouching and not wants_crouch and _can_stand():
		is_crouching = false
		_apply_height(STAND_HEIGHT)


func _can_stand() -> bool:
	var diff := STAND_HEIGHT - CROUCH_HEIGHT
	return not test_move(global_transform, Vector2(0.0, -diff))


func _update_sprint(dir: float, delta: float) -> void:
	var wants_sprint := Input.is_action_pressed("sprint") and dir != 0.0 \
			and not is_crouching and _attack_state == AttackState.NONE

	if _sprint_locked and stamina >= balance.sprint_unlock_threshold:
		_sprint_locked = false

	is_sprinting = wants_sprint and not _sprint_locked and stamina > 0.0

	if is_sprinting:
		_set_stamina(stamina - balance.sprint_stamina_cost * delta)
		_recharge_timer = balance.stamina_recharge_delay
		if stamina <= 0.0:
			_sprint_locked = true
			is_sprinting = false
	else:
		_recharge_timer -= delta
		if _recharge_timer <= 0.0:
			_set_stamina(stamina + balance.stamina_recharge_rate * delta)


func _apply_height(h: float) -> void:
	(_shape.shape as RectangleShape2D).size.y = h
	_shape.position.y = (STAND_HEIGHT - h) / 2.0
	if _visual:
		_visual.size.y = h
		_visual.position.y = STAND_HEIGHT / 2.0 - h


# ---------------------------------------------------------------- Input setup
func _register_inputs() -> void:
	_add_key("move_left", [KEY_A, KEY_LEFT])
	_add_key("move_right", [KEY_D, KEY_RIGHT])
	_add_key("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key("crouch", [KEY_CTRL, KEY_C])
	_add_key("sprint", [KEY_SHIFT])
	_add_key("attack", [KEY_X])
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_joy("attack", JOY_BUTTON_X)
	_add_key("debug_damage", [KEY_K])
	_add_key("debug_heal", [KEY_J])
	_add_key("debug_infect", [KEY_L])


func _add_key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_joy(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
