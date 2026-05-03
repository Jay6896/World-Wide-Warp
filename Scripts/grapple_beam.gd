extends Node2D

@onready var anchor: StaticBody2D = %Anchor
@onready var spring_joint: DampedSpringJoint2D = %PinJoint2D
@onready var player_anchor: RigidBody2D = %PlayerAnchor
@onready var line_2d: Line2D = %Line2D

@export var swing_force = 1500.0 # Applied continuously for smooth swinging
var player_node: CharacterBody2D
var rope_length: float = 0.0

func start_hook(hookPosition, player):
	
	spring_joint.node_a = NodePath("")
	spring_joint.node_b = NodePath("")
	
	anchor.global_position = hookPosition
	player_node = player
	
	player_anchor.add_collision_exception_with(player_node)
	
	for child in player_anchor.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	
	# Spawn the rigid body exactly where the player is. The PinJoint2D will 
	# naturally lock this exact distance as your physics-based rope length!
	player_anchor.global_position = player.global_position
	
	var rope_distance = player_anchor.global_position.distance_to(anchor.global_position)
	rope_length = rope_distance
	
	spring_joint.length = rope_distance
	spring_joint.rest_length = rope_distance
	spring_joint.stiffness = 400.0 # handles stiffness/bounciness
	spring_joint.damping = 40.0
	
	player_anchor.linear_damp = 0.4 # handles floatiness / air resistance
	
	player_anchor.lock_rotation = true
	
	var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	player_anchor.gravity_scale = 2980.0 / default_gravity
	
	# Transfer the player's current falling speed INTO the rope so you don't jolt to a stop
	player_anchor.linear_velocity = player.velocity
	
	spring_joint.node_a = NodePath("")
	spring_joint.node_b = NodePath("")
	
	_enable_collision_delayed()
	
	#player.position = Vector2.ZERO

func _enable_collision_delayed():
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(player_anchor):
		for child in player_anchor.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	var current_dist = player_anchor.global_position.distance_to(anchor.global_position)
	if current_dist > rope_length:
		var dir_to_anchor = player_anchor.global_position.direction_to(anchor.global_position)
		
		# 1. Kill outward velocity to force a perfect circular arc (stops diagonal spazzing)
		var outward_vel = player_anchor.linear_velocity.dot(-dir_to_anchor)
		if outward_vel > 0:
			player_anchor.linear_velocity += dir_to_anchor * outward_vel
			
		# 2. Hard clamp position so it physically cannot stretch to the floor
		player_anchor.global_position = anchor.global_position + (-dir_to_anchor * rope_length)
	
	var direction := Input.get_axis("left", "right")
	
	if direction != 0:
		var to_player = anchor.global_position.direction_to(player_anchor.global_position)
		var tangent = Vector2(-to_player.y, to_player.x) # Perpendicular to the rope
		
		# Align the push direction with the player's Left/Right input
		if (tangent.x > 0 and direction < 0) or (tangent.x < 0 and direction > 0):
			tangent = -tangent
		# Use force instead of impulse for a smooth, natural pendulum push
		player_anchor.apply_central_force(tangent * swing_force)
	
	if is_instance_valid(player_node):
		player_node.global_position = player_anchor.global_position
		
		# tilt
		var angle_to_anchor = player_node.global_position.direction_to(anchor.global_position).angle()
		player_node.rotation = angle_to_anchor + (PI / 2.0)
	
	# Pressing jump OR swing detaches the rope and launches the player
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("swing"):
		_leave_rope()

func _leave_rope():
	if not is_instance_valid(player_node): return
	
	player_anchor.remove_collision_exception_with(player_node)
	
	# Pass the physical momentum of the swing BACK to the player!
	player_node.velocity = player_anchor.linear_velocity
	
	player_node.collision_mask = player_node.saved_collision_mask	
	
	# Instantly detach and reactivate normal physics
	#player_node.reparent(player_node.get_tree().current_scene)
	player_node.rotation = 0
	player_node.is_swinging = false
	
	queue_free()

func _process(_delta: float) -> void:
	line_2d.points[0] = player_anchor.global_position - global_position
	line_2d.points[1] = anchor.global_position - global_position
