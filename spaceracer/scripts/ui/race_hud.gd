class_name RaceHUD
extends CanvasLayer
## RaceHUD - Displays speed, position, lap, and time information

# UI References (will be set up in code)
var speed_label: Label
var position_label: Label
var lap_label: Label
var time_label: Label
var countdown_label: Label

# Display values
var current_speed: float = 0.0
var max_speed: float = 300.0
var current_position: int = 1
var total_cars: int = 4
var current_lap: int = 1
var total_laps: int = 3

# Speedometer
var speedo_center: Vector2
var speedo_radius: float = 80.0

# Countdown
var countdown_active: bool = false
var countdown_value: int = 3

# Colors
var hud_bg_color: Color = Color(0, 0, 0, 0.5)
var text_color: Color = Color(1, 1, 1)
var speed_color: Color = Color(0.2, 1.0, 0.2)
var warning_color: Color = Color(1.0, 0.3, 0.3)

func _ready() -> void:
	layer = 10  # Ensure HUD is on top
	_create_ui()
	_connect_signals()

func _create_ui() -> void:
	# Create a Control node to hold all UI
	var ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)
	
	# Speed panel (bottom left)
	var speed_panel = Panel.new()
	speed_panel.position = Vector2(20, 420)
	speed_panel.size = Vector2(180, 100)
	var style = StyleBoxFlat.new()
	style.bg_color = hud_bg_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	speed_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(speed_panel)
	
	speed_label = Label.new()
	speed_label.position = Vector2(10, 10)
	speed_label.size = Vector2(160, 80)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speed_label.add_theme_font_size_override("font_size", 40)
	speed_label.add_theme_color_override("font_color", speed_color)
	speed_label.text = "0 MPH"
	speed_panel.add_child(speed_label)
	
	# Position panel (top right)
	var pos_panel = Panel.new()
	pos_panel.position = Vector2(760, 20)
	pos_panel.size = Vector2(180, 60)
	pos_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(pos_panel)
	
	position_label = Label.new()
	position_label.position = Vector2(10, 5)
	position_label.size = Vector2(160, 50)
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 32)
	position_label.add_theme_color_override("font_color", text_color)
	position_label.text = "1st / 4"
	pos_panel.add_child(position_label)
	
	# Lap panel (top center)
	var lap_panel = Panel.new()
	lap_panel.position = Vector2(390, 20)
	lap_panel.size = Vector2(180, 60)
	lap_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(lap_panel)
	
	lap_label = Label.new()
	lap_label.position = Vector2(10, 5)
	lap_label.size = Vector2(160, 50)
	lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lap_label.add_theme_font_size_override("font_size", 32)
	lap_label.add_theme_color_override("font_color", text_color)
	lap_label.text = "LAP 1/3"
	lap_panel.add_child(lap_label)
	
	# Time panel (top left)
	var time_panel = Panel.new()
	time_panel.position = Vector2(20, 20)
	time_panel.size = Vector2(180, 60)
	time_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(time_panel)
	
	time_label = Label.new()
	time_label.position = Vector2(10, 5)
	time_label.size = Vector2(160, 50)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 32)
	time_label.add_theme_color_override("font_color", text_color)
	time_label.text = "0:00.00"
	time_panel.add_child(time_label)
	
	# Countdown label (center screen)
	countdown_label = Label.new()
	countdown_label.position = Vector2(0, 200)
	countdown_label.size = Vector2(960, 150)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 120)
	countdown_label.add_theme_color_override("font_color", Color(1, 1, 0))
	countdown_label.text = ""
	countdown_label.visible = false
	ui_root.add_child(countdown_label)

func _connect_signals() -> void:
	GameManager.race_started.connect(_on_race_started)
	GameManager.race_finished.connect(_on_race_finished)
	GameManager.lap_completed.connect(_on_lap_completed)
	GameManager.position_changed.connect(_on_position_changed)

func _process(_delta: float) -> void:
	if GameManager.race_state == GameManager.RaceState.RACING:
		time_label.text = GameManager.format_time(GameManager.race_time)

func update_speed(speed: float, max_spd: float) -> void:
	current_speed = speed
	max_speed = max_spd
	var mph = int(speed * 0.6)  # Convert to MPH
	speed_label.text = "%d MPH" % mph
	
	# Color based on speed
	var speed_percent = speed / max_speed
	if speed_percent > 0.9:
		speed_label.add_theme_color_override("font_color", warning_color)
	else:
		speed_label.add_theme_color_override("font_color", speed_color)

func update_position(pos: int, total: int) -> void:
	current_position = pos
	total_cars = total
	var suffix = _get_ordinal_suffix(pos)
	position_label.text = "%d%s / %d" % [pos, suffix, total]

func update_lap(lap: int, total: int) -> void:
	current_lap = min(lap, total)
	total_laps = total
	lap_label.text = "LAP %d/%d" % [current_lap, total]

func _get_ordinal_suffix(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "th"
	match n % 10:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"

func start_countdown() -> void:
	countdown_active = true
	countdown_value = 3
	countdown_label.visible = true
	_do_countdown()

func _do_countdown() -> void:
	if countdown_value > 0:
		countdown_label.text = str(countdown_value)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 0))
		
		# Animate scale
		var tween = create_tween()
		countdown_label.scale = Vector2(1.5, 1.5)
		countdown_label.pivot_offset = countdown_label.size / 2
		tween.tween_property(countdown_label, "scale", Vector2(1, 1), 0.8)
		
		countdown_value -= 1
		await get_tree().create_timer(1.0).timeout
		_do_countdown()
	else:
		countdown_label.text = "GO!"
		countdown_label.add_theme_color_override("font_color", Color(0, 1, 0))
		
		GameManager.start_race()
		
		await get_tree().create_timer(1.0).timeout
		countdown_label.visible = false
		countdown_active = false

func _on_race_started() -> void:
	pass

func _on_race_finished() -> void:
	countdown_label.visible = true
	countdown_label.text = "FINISH!"
	countdown_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	
	var final_time = GameManager.format_time(GameManager.race_time)
	await get_tree().create_timer(2.0).timeout
	countdown_label.text = "TIME: %s" % final_time
	
	await get_tree().create_timer(3.0).timeout
	countdown_label.visible = false

func _on_lap_completed(car_id: int, lap: int) -> void:
	# Check if it's the player
	var player_data = GameManager.cars.filter(func(c): return c.id == car_id and c.is_player)
	if player_data.size() > 0:
		update_lap(lap, total_laps)
		
		# Flash lap indicator
		var original_color = text_color
		lap_label.add_theme_color_override("font_color", Color(0, 1, 0))
		await get_tree().create_timer(0.5).timeout
		lap_label.add_theme_color_override("font_color", original_color)

func _on_position_changed(car_id: int, pos: int) -> void:
	# Check if it's the player
	var player_data = GameManager.cars.filter(func(c): return c.id == car_id and c.is_player)
	if player_data.size() > 0:
		update_position(pos, total_cars)
