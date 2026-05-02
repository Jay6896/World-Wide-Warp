extends PortalEntity

const SPEED = 400.0
const JUMP_VELOCITY = -700.0
var ACCELERATION = 20.0
#var enter:bool = true
var blue_enter:bool = true
var orange_enter:bool = true
var GRAVITY = 2000
var EXIT_BUFFER = 100
var portal_entrances:int = 0
#var current_speed:float = 0
@onready var portal_enter = $"../DoublePEnter"
@onready var portal_exit = $"../DoublePExit"
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const GRAPPLE_BEAM = preload("res://Scenes/Objects/grapple_beam.tscn")


var air:bool = false
var air_time = 0.0

var run_time = 0.0

var is_swinging: bool = false
var active_grapple: Node2D = null
var saved_collision_mask: int = 1

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("swing") and not is_swinging:
		_use_grappling_hook()

	_set_ray_cast_direction()

	if is_swinging:
			# Allow portals to open while swinging by holding jump
			if Input.is_action_pressed("jump"):
				air_time += delta
				if air_time > 0.15:
					air = true
			else:
				air = false
				air_time = 0
				
			# Handle portal visibility while swinging
			if air == true:
				portal_enter.visible = true
				portal_exit.visible = true
			else:
				portal_enter.visible = false
				portal_exit.visible = false
				
			return

	portal_enter.visible = false
	portal_exit.visible = false
	portal_enter.collision_mask = 2
	portal_exit.collision_mask = 2
	# Add the gravity.
	velocity.y += GRAVITY * delta
	GRAVITY = 2980
	#print("current pos", position)
	#print("Jump height ", velocity.y)
		# Handle jump.
	if Input.is_action_just_pressed("jump") and is_grounded:
		air = false
		velocity.y = 0
		velocity.y = JUMP_VELOCITY
		
	
		#air = false
	if not is_grounded:
		#velocity += get_gravity() * delta
		#if Input.is_action_just_pressed("jump"): 
		if Input.is_action_pressed("jump"):
			air_time += delta
			if air_time > 0.15:
				GRAVITY = 2480
				air = true
				
		else:
			air = false
			air_time = 0

	if is_grounded:
		air_time = 0
		air = false
		portal_entrances = 0
		
	if air == true:
		portal_enter.collision_mask = 1
		portal_enter.visible = true
		portal_exit.collision_mask = 1
		portal_exit.visible = true
	#print("airtime val", air_time)





	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	#print("Current acceleration is {}", position)

	if direction:
		run_time += delta
		if abs(velocity.x) < SPEED or sign(velocity.x) != sign(direction):
			velocity.x = direction * SPEED
		# acceleration
		if run_time > 1.0:
			GRAVITY = 1980
			#velocity.y += GRAVITY * delta
			ACCELERATION = velocity.x / delta
			velocity.x = move_toward(velocity.x, direction * 600, direction * ACCELERATION * delta)
		if run_time > 3.0:
			GRAVITY = 1480
			#velocity.y += GRAVITY * delta
			ACCELERATION = velocity.x / delta
			velocity.x = move_toward(velocity.x, direction * 800, direction * ACCELERATION * delta)
		#GRAVITY = 2000
	else:
		run_time = 0
		velocity.x = move_toward(velocity.x, 0, SPEED * 2 * delta)

	#print("direction", direction)
	#print("velocity ", velocity.x)
	custom_move_and_slide(delta)

# old single portal
#func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("Collision Detected")
	#velocity += get_gravity() * get_physics_process_delta_time() 
	#position.y = 0
	##velocity.y += MASS
	##print(typeof(gravity))
	#

# grappler
func _set_ray_cast_direction():
	var direction := Input.get_axis("left", "right")	
	
	var aim_dir = Vector2(direction, -1).normalized()	
	ray_cast_2d.target_position = aim_dir * 400.0 
	ray_cast_2d.rotation = 0
	
func _use_grappling_hook():
	if not ray_cast_2d.is_colliding(): return
	
	var hook_point = ray_cast_2d.get_collision_point()
	
	if global_position.distance_to(hook_point) < 60.0:
		return
	
	is_swinging = true
	
	saved_collision_mask = collision_mask
	collision_mask = 0
	active_grapple = GRAPPLE_BEAM.instantiate()
	get_tree().current_scene.add_child(active_grapple)
	
	active_grapple.start_hook(hook_point, self)
# blue portal
func _on_double_p_enter_body_entered(body: Node2D) -> void:
	if body != self or not blue_enter: return
	#var current_speed = velocity.y
	
	if is_swinging and is_instance_valid(active_grapple):
		active_grapple._leave_rope()
	
	orange_enter = false
	air_time = 2
	portal_entrances += 1
	
	var boost = 0
	if portal_entrances > 1:
		boost = 100
	#current_speed += min(20000, velocity.y * 1.1)
	var portal_acceleration = boost * sign(velocity.y)
	velocity.y = clamp(velocity.y + portal_acceleration, -1000, 1000)
	print("body velocity: ", velocity.y)
	#print("current speed: ", current_speed)
	position.x = portal_exit.position.x
	position.y = portal_exit.position.y - (EXIT_BUFFER - 150)
	#velocity.y = current_speed
	#velocity.y += 700
	blue_enter = true
	var clearance_distance = 80.0
	var dynamic_cooldown = clamp(clearance_distance / max(abs(velocity.y), 1.0), 0.05, 0.5)
	
	await get_tree().create_timer(dynamic_cooldown).timeout
	#await get_tree().create_timer(0.09).timeout
	orange_enter = true
	
	if portal_enter.get_overlapping_bodies().has(self):
		_on_double_p_enter_body_entered(self)
# orange portal
func _on_double_p_exit_body_entered(body: Node2D) -> void:
	if body != self or not orange_enter: return
	
	blue_enter = false
	#if (enter == true):
		##velocity += get_gravity() * get_physics_process_delta_time() 
		#enter = false 
		##await get_tree().create_timer(1.2).timeout
		##_on_double_p_exit_body_entered(body)
	if is_swinging and is_instance_valid(active_grapple):
		active_grapple._leave_rope()
		
	#else:
		#var current_speed = velocity.y
	air_time = 2
	portal_enter.collision_mask = 2
	portal_enter.collision_layer = 2
	position.x = portal_enter.position.x
	position.y = portal_enter.position.y - 80
		#current_speed += min(20000, velocity.y * -1.1)
	var reverse = velocity.y * -1
	var portal_acceleration = 100 * sign(reverse)
	velocity.y = min(clamp(reverse, -1000, 1000), JUMP_VELOCITY)
	var clearance_distance = 80.0 
	var dynamic_cooldown = clamp((abs(velocity.y) - sqrt(abs(velocity.y) * abs(velocity.y) - 2 * GRAVITY * clearance_distance)) / GRAVITY, 0.05, 0.5)	
	await get_tree().create_timer(dynamic_cooldown).timeout
	#await get_tree().create_timer(1.2).timeout
		#velocity.y = clamp(reverse + portal_acceleration, -1000, 1000)
		#velocity.y = current_speed
	portal_enter.collision_mask = 1
	portal_enter.collision_layer = 1
	blue_enter = true
	if portal_exit.get_overlapping_bodies().has(self):
		_on_double_p_exit_body_entered(self)
