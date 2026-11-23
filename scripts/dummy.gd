extends CharacterBody2D
## Training dummy for testing the wrench. Replaced by real zombies in Step 4.

@export var max_hp := 60.0
@export var knockback_speed := 90.0
@export var gravity := 600.0

var hp := 60.0
var stagger_left := 0.0

@onready var _visual: ColorRect = get_node_or_null("Visual")


func _ready() -> void:
	hp = max_hp
	_update_color()


## The player's wrench calls this. Any enemy you build later should have it too.
func take_hit(damage: float, stagger_seconds: float, from_position: Vector2) -> void:
	hp -= damage
	stagger_left = stagger_seconds
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * knockback_speed
	print("Dummy hit: -%d HP (left: %d), stagger %.1fs" % [damage, maxf(hp, 0.0), stagger_seconds])
	if hp <= 0.0:
		queue_free()
	_update_color()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	if stagger_left > 0.0:
		stagger_left -= delta
		if stagger_left <= 0.0:
			_update_color()
	move_and_slide()


func _update_color() -> void:
	if _visual == null:
		return
	# Orange = staggered (can't attack), grey = normal
	_visual.color = Color("e67e22") if stagger_left > 0.0 else Color("95a5a6")
