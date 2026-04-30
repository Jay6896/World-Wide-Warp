extends Area2D

@onready var character_pos = $"../CharacterBody2D"

# Called when the node enters the scene tree for the first time.
func follow(body: Node2D):
	position.x = character_pos.position.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x = character_pos.position.x
