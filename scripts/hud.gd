extends CanvasLayer
## Minimal HUD: builds its own bars in code. Add as a CanvasLayer node in your level.

var _hp_bar: ProgressBar
var _stamina_bar: ProgressBar
var _infection_bar: ProgressBar


func _ready() -> void:
	_hp_bar = _make_bar(Vector2(6, 6), Color("c0392b"))
	_stamina_bar = _make_bar(Vector2(6, 14), Color("f1c40f"))
	_infection_bar = _make_bar(Vector2(6, 22), Color("7dcea0"))

	# Wait one frame so the Player has finished its own _ready()
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("HUD: no node in group 'player' found.")
		return

	player.hp_changed.connect(_on_hp_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.infection_changed.connect(_on_infection_changed)

	# Show initial values
	_on_hp_changed(player.hp, player.balance.player_max_hp)
	_on_stamina_changed(player.stamina, player.balance.player_max_stamina)
	_on_infection_changed(player.infection_pct)


func _on_hp_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current


func _on_infection_changed(current: float) -> void:
	_infection_bar.max_value = 100.0
	_infection_bar.value = current
	_infection_bar.visible = current > 0.0  # only show once bitten


func _make_bar(pos: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(60, 5)
	bar.custom_minimum_size = Vector2(60, 5)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	add_child(bar)
	return bar
