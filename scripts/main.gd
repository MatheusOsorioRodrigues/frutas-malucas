extends Area2D

@onready var spawn_point = $Character
@onready var username_space = $Username

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if Global.personagem_selecionado != null:
	#	var spawn_point = $Character

	# Adiciona o personagem como filho do spawn point
	spawn_point.add_child(Global.personagem_selecionado)
	username_space.add_child(Global.username)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


