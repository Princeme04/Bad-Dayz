class_name Balance
extends Resource
## All tuning numbers live here (GDD Tables 3.1-3.5).
## Save an instance as res://resources/balance.tres and edit values in the Inspector.

@export_group("Player")
@export var player_max_hp := 100.0
@export var player_max_stamina := 100.0
@export var crouch_speed_m := 1.2
@export var walk_speed_m := 2.8
@export var player_run_speed := 4.8      # m/s (sprint)
@export var inventory_capacity := 12

@export_group("Stamina")
@export var sprint_stamina_cost := 10.0   # per second
@export var stamina_recharge_rate := 20.0 # per second
@export var stamina_recharge_delay := 1.0 # seconds of no activity first
@export var sprint_unlock_threshold := 15.0

@export_group("Infection")
# NOTE: the GDD gives no number for this, so 25 (4 bites = infected) is a placeholder.
@export var infection_per_bite := 25.0

@export_group("Wrench (Table 3.1)")
@export var wrench_base_damage := 25.0
@export var stamina_cost_swing := 30.0
@export var stagger_duration_seconds := 1.2
@export var wrench_windup := 0.25
@export var wrench_active := 0.15
@export var wrench_recovery := 0.4
@export_subgroup("Exhausted swing")
@export var exhausted_speed_scale := 0.5       # 50% speed -> every phase takes 2x as long
@export var exhausted_swing_damage := 10.0
@export var exhausted_stagger_duration := 0.4
@export_subgroup("Feel")
@export var attack_move_multiplier := 0.3      # walking speed while swinging (my placeholder)
@export var attack_buffer_time := 0.15         # press slightly early during recovery = queued swing
@export var screen_shake_intensity := 2.0
@export var screen_shake_duration := 0.1

@export_group("Enemies (Step 4)")
@export var zombie_base_hp := 60.0
@export var urban_zombie_hp := 120.0
@export var zombie_hit_damage := 20.0
