extends PortalEntity

const SPEED = 400.0
const JUMP_VELOCITY = -700.0
var ACCELERATION = 20.0
var enter:bool = false
var GRAVITY = 2000
var EXIT_BUFFER = 100
var current_speed = velocity.y
@onready var portal_enter = $"../DoublePEnter"
@onready var portal_exit = $"../DoublePExit"

var air:bool = false
var air_time = 0.0

var run_time = 0.0


func _physics_process(delta: float) -> void:
	portal_enter.visible = false
	portal_exit.visible = false
	portal_enter.collision_mask = 2
	portal_exit.collision_mask = 2
	# Add the gravity.
	velocity.y += GRAVITY * delta
	GRAVITY = 2000
	#print("current pos", position)
	#print("Jump height ", velocity.y)
		# Handle jump.
	if Input.is_action_just_pressed("jump") and is_grounded:
		air = false
		velocity.y = 0
		velocity.y = JUMP_VELOCITY
		
	
		#air = false
	if not is_grounded:
		velocity += get_gravity() * delta
		#if Input.is_action_just_pressed("jump"): 
		if Input.is_action_pressed("jump"):
			air_time += delta
			if air_time > 0.15:
				GRAVITY = 1500
				air = true
				
		else:
			air = false
			air_time = 0

	if is_grounded:
		air_time = 0
		air = false
		
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
		velocity.x = direction * SPEED
		# acceleration
		if run_time > 1.0:
			GRAVITY = 1000
			#velocity.y += GRAVITY * delta
			ACCELERATION = velocity.x / delta
			velocity.x = move_toward(velocity.x,600, ACCELERATION * delta)
		if run_time > 4.0:
			GRAVITY = 500
			#velocity.y += GRAVITY * delta
			ACCELERATION = velocity.x / delta
			velocity.x = move_toward(velocity.x,800, ACCELERATION * delta)
		#GRAVITY = 2000
	else:
		run_time = 0
		velocity.x = 0
		velocity.x = move_toward(velocity.x, 0, SPEED)

	#print("velocity ", velocity.x)
	custom_move_and_slide(delta)

# old single portal
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collision Detected")
	velocity += get_gravity() * get_physics_process_delta_time() 
	position.y = 0
	#velocity.y += MASS
	#print(typeof(gravity))
	
# blue portal
func _on_double_p_enter_body_entered(body: CharacterBody2D) -> void:
	air_time = 2
	current_speed += min(200000, body.velocity.y * 1.1)
	print("body val: ", body.velocity.y)
	print("current speed: ", current_speed)
	position.x = portal_exit.position.x
	position.y = portal_exit.position.y
	velocity.y += current_speed
	#velocity.y += 700
	enter = true
# orange portal
func _on_double_p_exit_body_entered(body: CharacterBody2D) -> void:
	if (enter == true):
		#velocity += get_gravity() * get_physics_process_delta_time() 
		enter = false 
		#await get_tree().create_timer(1.2).timeout
		#_on_double_p_exit_body_entered(body)

	else:
		air_time = 2
		portal_enter.collision_mask = 2
		portal_enter.collision_layer = 2
		var current_speed = min(100, body.velocity.length() * 1.1)
		print("body val: ", body.velocity.length())
		position.x = portal_enter.position.x
		position.y = portal_enter.position.y - EXIT_BUFFER - 50
		body.velocity.y = position.y + current_speed
		velocity.y += -700
		#await get_tree().create_timer(1.2).timeout
		portal_enter.collision_mask = 1
		portal_enter.collision_layer = 1
