class_name Truck
extends CharacterBody2D

signal collided(strength: int)

const MAX_SPEED := 700.0
const ACCEL := MAX_SPEED / 0.7
const DECEL := MAX_SPEED / 2.0
const DRAG := MAX_SPEED / 0.3
const STEERING_SPEED := 3.5 * PI
const JUMP_DURATION := 0.5

@onready var _water_particles := $BodySprite/CPUParticles2D2 as CPUParticles2D
@onready var _drift_particles := $CPUParticles2D as CPUParticles2D
@onready var _body_sprite := $BodySprite as Sprite2D
@onready var _default_z_index := _body_sprite.z_index
@onready var _low_area := %LowScanArea2D as Area2D
const _jump_z_index := 6

var dir := Vector2.RIGHT
var z := 0.0
var vz := 0.0

func _process(_delta: float) -> void:
	var shadow := %ShadowSprite as Sprite2D
	var body := $BodySprite as Sprite2D
	var k := 1 - (1 - z) **2
	shadow.modulate.a = 0.3
	shadow.scale = Vector2.ONE * lerpf(1.0, 1.3, k)
	shadow.global_position = global_position + Vector2(3, 2) * lerpf(1, 10, k)
	body.scale = Vector2.ONE * lerpf(1.0, 1.4, k)

func _unhandled_input(event: InputEvent) -> void:
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
	collision_mask = 0x2
	collision_layer = 0x2
	_body_sprite.z_index = _jump_z_index

func _end_jump() -> bool:
	if _low_area.get_overlapping_bodies().size() > 0:
		return false
	z = 0.0
	vz = 0.0
	collision_mask = 0x1
	collision_layer = 0x1
	_body_sprite.z_index = _default_z_index
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
			collided.emit(1)

func _physics_process(delta: float) -> void:
	_update_z(delta)
	var dir_command := dir + 0*Vector2(
		Input.get_action_strength("ui_right")
		- Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")
		- Input.get_action_strength("ui_up")
	)
	if dir_command.is_zero_approx():
		_water_particles.emitting = false
	else:
		dir_command = dir_command.normalized()
		var angle_diff := angle_difference(rotation, dir_command.angle())
		var angle_delta := clampf(angle_diff, -STEERING_SPEED * delta, STEERING_SPEED * delta)
		rotate(angle_delta)
		_water_particles.emitting = true
	
	var lon_vel := velocity.dot(transform.x)
	var lat_vel := velocity.dot(transform.y)
	var lon_acc := ACCEL #* maxf(0.0, dir_command.dot(transform.x)) if not dir_command.is_zero_approx() else -DECEL
	var lat_drag := DRAG
	if signf(lon_acc) * signf(lon_vel) < 0:
		# reverse -> brake to accelerate more in opposite direction
		lon_acc += DRAG
	if _jumping():
		lon_acc *= 0.0
		lat_drag *= 0.0
		
	_drift_particles.emitting = abs(lat_vel) > MAX_SPEED * 0.01
	lon_vel = clampf(lon_vel + lon_acc * delta, lon_vel, MAX_SPEED)
	lat_vel -= clampf(lat_vel, -lat_drag * delta, lat_drag * delta)
	var init_velocity := velocity
	velocity = transform.x * lon_vel + transform.y * lat_vel
	var expected_accel := velocity - init_velocity
	
	init_velocity = velocity
	
	# Collisions
	var motion := velocity * delta
	var max_col := 10
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
		collided.emit(clampi(collision_strength, 1, 2))
