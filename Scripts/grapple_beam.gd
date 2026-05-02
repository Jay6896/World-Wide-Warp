# CHANGED grapple_beam.gd
extends Node2D

@onready var anchor: StaticBody2D = %Anchor
@onready var spring_joint: DampedSpringJoint2D = %PinJoint2D
@onready var player_anchor: RigidBody2D = %PlayerAnchor
@onready var line_2d: Line2D = %Line2D

var swing_force = 2000.0 # Applied continuously for smooth swinging
var player_node: CharacterBody2D

func start_hook(hookPosition, player):
	anchor.global_position = hookPosition
	player_node = player
	
	for child in player_anchor.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	
	# Spawn the rigid body exactly where the player is. The PinJoint2D will 
	# naturally lock this exact distance as your physics-based rope length!
	player_anchor.global_position = player.global_position
	
	var rope_distance = player_anchor.global_position.distance_to(anchor.global_position)
	
	spring_joint.length = rope_distance
	spring_joint.rest_length = rope_distance
	spring_joint.stiffness = 64.0
	
	# Transfer the player's current falling speed INTO the rope so you don't jolt to a stop
	player_anchor.linear_velocity = player.velocity
	
	#player.position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	
	if direction != 0:
		# Use force instead of impulse for a smooth, natural pendulum push
		player_anchor.apply_central_force(Vector2(direction * swing_force, 0))
	
	if is_instance_valid(player_node):
		player_node.global_position = player_anchor.global_position
	
	# Pressing jump OR swing detaches the rope and launches the player
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("swing"):
		_leave_rope()

func _leave_rope():
	if not is_instance_valid(player_node): return
	
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
