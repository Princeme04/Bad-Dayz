extends Camera2D
## Attach to the Player's Camera2D. Shakes when the player lands a hit.

var _time := 0.0
var _duration := 0.1
var _intensity := 0.0


func _ready() -> void:
	# Wait a frame: children are ready before the Player adds itself to the group.
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("hit_landed"):
		player.hit_landed.connect(_on_hit_landed.bind(player))


func _on_hit_landed(_body: Node, player: Node) -> void:
	shake(player.balance.screen_shake_intensity, player.balance.screen_shake_duration)


func shake(intensity: float, duration: float) -> void:
	_intensity = intensity
	_duration = maxf(duration, 0.01)
	_time = _duration


func _process(delta: float) -> void:
	if _time > 0.0:
		_time -= delta
		var falloff := clampf(_time / _duration, 0.0, 1.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _intensity * falloff
	else:
		offset = Vector2.ZERO
