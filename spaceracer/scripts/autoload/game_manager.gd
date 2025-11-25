extends Node
## GameManager - Singleton for managing race state and global game data

signal race_started
signal race_finished
signal lap_completed(car_id: int, lap: int)
signal position_changed(car_id: int, position: int)

enum RaceState { WAITING, COUNTDOWN, RACING, FINISHED }

var race_state: RaceState = RaceState.WAITING
var race_time: float = 0.0
var total_laps: int = 3

# Track all cars (player + AI)
var cars: Array = []
var car_positions: Dictionary = {}  # car_id -> track_position (0.0 to 1.0 per lap)
var car_laps: Dictionary = {}       # car_id -> current lap
var car_rankings: Array = []        # Sorted list of car_ids by position

# Track data
var current_track: Track = null

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if race_state == RaceState.RACING:
		race_time += delta
		_update_rankings()

func register_car(car_id: int, is_player: bool = false) -> void:
	cars.append({"id": car_id, "is_player": is_player})
	car_positions[car_id] = 0.0
	car_laps[car_id] = 1
	car_rankings.append(car_id)

func update_car_position(car_id: int, track_position: float) -> void:
	var old_pos = car_positions.get(car_id, 0.0)
	car_positions[car_id] = track_position
	
	# Check for lap completion (crossed from end to start)
	if old_pos > 0.9 and track_position < 0.1:
		car_laps[car_id] = car_laps.get(car_id, 1) + 1
		lap_completed.emit(car_id, car_laps[car_id])
		
		# Check for race finish
		if car_laps[car_id] > total_laps:
			var car_data = cars.filter(func(c): return c.id == car_id)
			if car_data.size() > 0 and car_data[0].is_player:
				finish_race()

func _update_rankings() -> void:
	# Sort cars by lap and position within lap
	car_rankings.sort_custom(func(a, b):
		var lap_a = car_laps.get(a, 1)
		var lap_b = car_laps.get(b, 1)
		if lap_a != lap_b:
			return lap_a > lap_b
		return car_positions.get(a, 0.0) > car_positions.get(b, 0.0)
	)
	
	# Emit position changes
	for i in range(car_rankings.size()):
		position_changed.emit(car_rankings[i], i + 1)

func get_car_ranking(car_id: int) -> int:
	var idx = car_rankings.find(car_id)
	return idx + 1 if idx >= 0 else 0

func get_car_lap(car_id: int) -> int:
	return car_laps.get(car_id, 1)

func start_race() -> void:
	race_state = RaceState.RACING
	race_time = 0.0
	race_started.emit()

func finish_race() -> void:
	race_state = RaceState.FINISHED
	race_finished.emit()

func reset_race() -> void:
	race_state = RaceState.WAITING
	race_time = 0.0
	for car_id in car_positions.keys():
		car_positions[car_id] = 0.0
		car_laps[car_id] = 1

func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var ms = int((time_seconds - int(time_seconds)) * 100)
	return "%d:%02d.%02d" % [minutes, seconds, ms]
