extends Area2D

func _ready():
	$"1".input_event.connect(_on_character_clicked.bind(1))
	$"2".input_event.connect(_on_character_clicked.bind(2))

func _on_character_clicked(viewport, event, shape_idx, character_id):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Selected character ", character_id)

			#Não consegui pegar pelo character_id, retorna nill :/
			if character_id == 1:
				var personagem_escolhido = $"1/Character".duplicate()
				personagem_escolhido.position = Vector2(0, 0)
				get_tree().change_scene_to_file("res://scenes/main.tscn")
				Global.personagem_selecionado = personagem_escolhido
			else:
				var personagem_escolhido = $"2/Character".duplicate()
				personagem_escolhido.position = Vector2(0, 0)
				get_tree().change_scene_to_file("res://scenes/main.tscn")
				Global.personagem_selecionado = personagem_escolhido
