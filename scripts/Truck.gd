class_name Truck
extends CharacterBody2D

signal collided(strong: bool)
signal catapulted()

enum State {LOADING, DRIVING, CATAPULTING, EMERGENCY_STOP}

const MAX_SPEED := 700.0
const ACCEL := MAX_SPEED / 0.7
const DECEL := MAX_SPEED / 2.0
const DRAG := MAX_SPEED / 0.3
const STEERING_SPEED := 3.5 * PI
const JUMP_DURATION := 0.5

@onready var _water_particles := $BodySprite/SplashParticles as CPUParticles2D
@onready var _drift_particles := $DriftParticles as CPUParticles2D
@onready var _water_burst_particles := %SplashParticlesBurst as CPUParticles2D
@onready var _body_sprite := $BodySprite as Sprite2D
@onready var _catapult_sprite := %Catapult as Sprite2D
@onready var _default_z_index := _body_sprite.z_index
@onready var _low_area := %LowScanArea2D as Area2D
const _jump_z_index := 6
var dir := Vector2.RIGHT
var z := 0.0
var vz := 0.0
var _water_supply := 0
var _state := State.LOADING
var _target_node: Node2D

func _ready() -> void:
	_catapult_sprite.visible = false

func has_water_supply() -> bool:
	return _water_supply > 0
	
func get_water_supply() -> int:
	return _water_supply

func add_water_supply(ws: int) -> int:
	set_water_supply(clampi(_water_supply + ws, 0, 100))
	return _water_supply

func set_water_supply(ws: int) -> void:
	_water_supply = ws
	_update_water_supply_visual()

func _update_water_supply_visual() -> void:
	_catapult_sprite.visible = _state == State.CATAPULTING
	(%WaterSupply1 as Node2D).visible = _water_supply > 0 and _state != State.CATAPULTING
	(%WaterSupply2 as Node2D).visible = _water_supply > 50 and _state != State.CATAPULTING

func shake() -> void:
	if has_water_supply():
		_water_burst_particles.emitting = true

func start_loading(pose: Transform2D, target_node: Node2D) -> void:
	_state = State.LOADING
	global_transform = pose
	dir = pose.x
	_target_node = target_node
	_update_water_supply_visual()

func start_driving() -> void:
	_state = State.DRIVING
	(%CollisionTimer as Timer).stop()
	_update_water_supply_visual()

func try_take_damage() -> bool:
	var t := (%CollisionTimer as Timer)
	var allowed := t.is_stopped()
	if allowed:
		t.start()
	return allowed

func emergency_stop() -> void:
	_state = State.EMERGENCY_STOP

func catapult_water(target_pos: Vector2) -> void:
	_state = State.CATAPULTING
	_update_water_supply_visual()
	_catapult_sprite.global_rotation = _catapult_sprite.global_position.angle_to_point(target_pos) - PI / 2

	printerr("TODO implement catapulting FX")
	await get_tree().create_timer(1.0).timeout
	catapulted.emit()

func _process(_delta: float) -> void:
	var shadow := %ShadowSprite as Sprite2D
	var body := $BodySprite as Sprite2D
	var k := 1 - (1 - z) **2
	shadow.modulate.a = 0.3
	shadow.scale = Vector2.ONE * lerpf(1.0, 1.3, k)
	shadow.global_position = global_position + Vector2(3, 2) * lerpf(1, 10, k)
	body.scale = Vector2.ONE * lerpf(1.0, 1.4, k)
	
	var show_arrow := (_target_node != null and _state != State.CATAPULTING)
	var arrow := %Arrow as Node2D
	arrow.visible = show_arrow
	if show_arrow:
		arrow.global_rotation = global_position.angle_to_point(_target_node.global_position)

func _unhandled_input(event: InputEvent) -> void:
	if _state != State.DRIVING:
		return
	
	if event.is_action_pressed("ui_right"):
		dir = Vector2(-dir.y, dir.x)
	elif event.is_action_pressed("ui_left"):
		dir = Vector2(dir.y, -dir.x)
	elif event.is_action_pressed("ui_accept"):
		if not _jumping():
			_start_jump()

func _start_jump() -> void:
	z = 0.01
	vz = 1.0 / JUMP_DURATION * 2
	collision_mask = 0b110
	collision_layer = 0x110
	_body_sprite.z_index = _jump_z_index

func _end_jump() -> bool:
	if _low_area.get_overlapping_bodies().size() > 0:
		return false
	z = 0.0
	vz = 0.0
	collision_mask = 0b101
	collision_layer = 0b101
	_body_sprite.z_index = _default_z_index
	shake()
	return true

func _jumping() -> bool:
	return z > 0

func _update_z(delta: float) -> void:
	if not _jumping():
		return
	z += vz * delta
	if z >= 1.0:
		z = 1.0
		vz *= -1
	elif z <= 0:
		var ended := _end_jump()
		if not ended:
			z = 0.1
			collided.emit(false)

func _physics_process(delta: float) -> void:
	# Jump update
	_update_z(delta)
	
	# Orientation
	if not dir.is_zero_approx():
		var angle_diff := angle_difference(rotation, dir.angle())
		var angle_delta := clampf(angle_diff, -STEERING_SPEED * delta, STEERING_SPEED * delta)
		rotate(angle_delta)
	
	var lon_vel := velocity.dot(transform.x)
	var lat_vel := velocity.dot(transform.y)
	
	var handbrake := _state != State.DRIVING
	var brake := handbrake or lon_vel < 0
	var thrust := not brake
	
	var lon_acc := ACCEL if thrust else 0.0
	var lon_drag := (DRAG * 3 if handbrake else DRAG) if brake else 0.0
	var lat_drag := DRAG

	if _jumping():
		lon_acc = 0.0
		lon_drag = 0.0
		lat_drag = 0.0
		# prevent from being stuck while jumping
		if velocity.length() < MAX_SPEED * 0.3:
			lon_acc += ACCEL * 0.45

	lon_vel = clampf(lon_vel + lon_acc * delta, lon_vel, MAX_SPEED)
	lon_vel -= clampf(lon_vel, -lon_drag * delta, lon_drag * delta)
	lat_vel -= clampf(lat_vel, -lat_drag * delta, lat_drag * delta)
	
	var init_velocity := velocity
	velocity = transform.x * lon_vel + transform.y * lat_vel
	var expected_accel := velocity - init_velocity
	
	# Paeticles
	var moving := not velocity.is_zero_approx()
	_drift_particles.emitting = (abs(lat_vel) > MAX_SPEED * 0.01 or (brake and moving)) and not _jumping()
	_water_particles.emitting = (velocity.length() > MAX_SPEED / 2) and has_water_supply()

	# Collisions
	var motion := velocity * delta
	var max_col := 10
	init_velocity = velocity
	while true:
		var kin_col := move_and_collide(motion)
		max_col -= 1
		if kin_col == null or max_col == 0:
			break
		var N := kin_col.get_normal()
		velocity = velocity.reflect(N) - velocity.dot(N) * N * 0.7
		motion = motion.reflect(N) - motion.dot(N) * N * 0.7
	
	var delta_velocity := (velocity - init_velocity).length()
	var collision_strength := int(remap(delta_velocity, expected_accel.length(), MAX_SPEED, 0, 2.99))
	if collision_strength > 0:
		collided.emit(collision_strength >= 2)
