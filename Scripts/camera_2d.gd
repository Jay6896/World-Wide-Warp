extends Camera2D

@onready var character_pos = $"../CharacterBody2D"
@onready var camera_pos = $Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x = character_pos.position.x
	position.y = 340.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x = character_pos.position.x
	position.y = 340.0
