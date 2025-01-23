extends Area2D

@onready var spawn_point = $Character
@onready var username_space = $Username
#@onready var 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	"""
	var background = $Background as Sprite2D
	
	var window_size = get_window().size
	var texture_size = background.texture.get_size()
	
	window_size.x = 720
	window_size.y = 1600
	#0.083 90
	#print(texture_size.x * 0.2) #10x17 90x153 (1080, 1836) 
	print(texture_size.x)
	print(texture_size.y)
	background.scale.x=  (texture_size.x / window_size.x) * 0.1
	background.scale.y = (texture_size.y / window_size.y) * 0.1
	print(background.scale.x)
	print(background.scale.y) """

	#if Global.personagem_selecionado != null:
	#	var spawn_point = $Character
	# Adiciona o personagem como filho do spawn point
	spawn_point.add_child(Global.personagem_selecionado)
	username_space.add_child(Global.username)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
