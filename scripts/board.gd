extends Area2D

#OBS: Precisa generalizar para funcionar em tabuleiros 3x3, 4x4, 5x5

const BOARD_OFFSET_X: int = 3 #Espaço da borda da tela
const BOARD_OFFSET_Y: int = 42
const BOARD_SIZE: int = 84
const TILES_COLORS = [Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 1.0), Color(1.0, 1.0, 0.0),
 Color(0.0, 1.0, 0.0), Color(1.0, 0.67, 0.11)]
# Carrega as frutas e os fundos
const FRUIT_SCENE:PackedScene = preload("res://actors/fruit.tscn") 
const EMPTY_SCENE:PackedScene = preload("res://actors/empty.tscn")
const BACKGROUND_SCENE:PackedScene = preload("res://actors/tile_background.tscn")

var grid_size: int
var tile_count: int
var scale_tile: float
var tile_size: float
var tiles: Array = []
var solved_rows: Array = []
var restrictions: Array = [] 
var fences: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	adjust_background()
	start_game()

func start_game() -> void:
	#Le informações do nivel do level{i}.json
	var file:FileAccess = FileAccess.open("res://levels/level5.json", FileAccess.READ)
	var text:String = file.get_as_text()
	var data:Dictionary = JSON.parse_string(text)

	#Define valores para a construção do tabuleiro
	var map:Array = data["map"] #O mapa com a ordem que as peças estarão
	grid_size = (data["size"]) #Tamanho do map
	tile_count  = grid_size * grid_size #Quantidade de peças
	restrictions = data["restrictions"] #Lugares onde há restrições(cercas)
	tile_size = BOARD_SIZE / grid_size #Define o tamanho da peça em pixels
	scale_tile = 0.14 / grid_size #Escala para transformar o sprite original no tamanho do tile_size
	
	# Referências para os nós pais ondes as frutas e o fundo serão instanciados
	var fruits_parent:Node2D = get_node("Frutas")
	var backgrounds_parent:Node2D = get_node("FundosPeca")

	#Ajusta local da peças, já que a escala aumenta o tamanho da peças em todos sentidos
	var tile_offset:float = 42 / grid_size 
	
	#Instacia cada fundo
	for i in range(grid_size):
		for j in range(grid_size):
			var background_instance: Sprite2D
			background_instance = BACKGROUND_SCENE.instantiate()
			background_instance.scale = Vector2(scale_tile, scale_tile)
			
			#Muda a cor do fundo de acordo com  a linha atual
			background_instance.modulate = TILES_COLORS[i] 
			background_instance.position = Vector2((tile_size * j + tile_offset), tile_size * i + tile_offset)
			backgrounds_parent.add_child(background_instance)
	
	#Instacia os sprites da fruta
	for i in range(tile_count):
		var fruit_instance:Sprite2D = FRUIT_SCENE.instantiate()
		var fruit_texture:Texture
		
		if map[i].contains("Apple"):
			fruit_texture = load("res://sprites/Fruits/AppleNL_HL.png") 
		elif map[i].contains("Grape"):
			fruit_texture = load("res://sprites/Fruits/PurplegrapeNL_HL.png") 
		elif map[i].contains("Banana"):
			fruit_texture = load("res://sprites/Fruits/BananaNL_HL.png")
		elif map[i].contains("Pear"):
			fruit_texture = load("res://sprites/Fruits/PearNL_HL.png")
		elif map[i].contains("Orange"):
			fruit_texture = load("res://sprites/Fruits/OrangeNL_HL.png")
		elif map[i].contains("Empty"):
			fruit_instance = EMPTY_SCENE.instantiate()
			
		fruit_instance.name = map[i] 
		fruit_instance.texture = fruit_texture
		
		tiles.append(fruit_instance) #Adiciona a instacia no array do estado atual do board
		fruits_parent.add_child(fruit_instance)
		
	var scale_fruit:float = 2.0 / grid_size 
	for i in range(grid_size):
		for j in range(grid_size):
			tiles[grid_size * i + j].position = Vector2(tile_size * j \
				+ tile_offset, tile_size * i + tile_offset)
			tiles[grid_size * i + j].scale = Vector2(scale_fruit, scale_fruit)
	
	solved_rows = data["solved"]
	instantiate_fences(restrictions)

func adjust_background() -> void:
	#Pega o tamanho da tela do dispositivo
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var background: Sprite2D = $Background

	var texture_size: Vector2 = background.texture.get_size()

	# Calcular escala
	var scale_x: float = screen_size.x / texture_size.x
	var scale_y: float = screen_size.y / texture_size.y

	var scale_factor: float = max(scale_x, scale_y)

	# Ajustar o sprite com o fator de escala
	background.scale = Vector2(scale_factor, scale_factor)
	
	# Ajustar a posição do sprite para manter o fundo centralizado
	var offset_x: float = (screen_size.x - texture_size.x * scale_factor) / 2
	var offset_y: float = (screen_size.y - texture_size.y * scale_factor) / 2
	background.position = Vector2(offset_x + 42, offset_y + 58)

func instantiate_fences(restrictions: Array) -> void:
	#Dependendo do tipo de restrição instancia a cena da cerca
	var scene: PackedScene
	for i in range(len(restrictions)):
		match restrictions[i]:
			"free":
				fences.append(null)
				continue
			"locked":
				scene = load("res://actors/fullFence.tscn")
			"horizontal_locked":
				scene = load("res://actors/verticalFence.tscn")
			"vertical_locked":
				scene = load("res://actors/horizontalFence.tscn")

		var instance: Node2D = scene.instantiate()
		#Calcula a posição da cerca na tela de acordo com a posição da restrição
		instance.position.x += (i % grid_size) * tile_size
		instance.position.y += (i / grid_size) * tile_size
		instance.scale = Vector2(4.0 / grid_size, 4.0 / grid_size)
		
		add_child(instance)
		fences.append(instance)

#Procura pelo espaço vazio
func find_empty() -> int:
	for count in range(tile_count):
		if tiles[count] == $Frutas/Empty:
			return count
	return -1

#Verifica quais são os vizinhos ortoganais do espaço vazinho
func empty_neighbours(empty: int, restrictions: Array) -> Array:
	var directions: Array = [
		-grid_size,   # baixo
		grid_size,  # cima
		1,   # direita
		-1   # esquerda
	]

	var neighbours: Array = []
	for direction in directions:
		var neighbour: int = empty + direction

		#Ignora vizinhos que estrapolam os limites do tabuleiro
		if neighbour < 0 or neighbour >= tile_count:
			continue
		
		#Impede que a peça mova da ultima coluna para a primeira da próxima linha e vice-versa
		#Att: é necessaria :)
		if direction == 1 and empty % grid_size == grid_size - 1:
			continue  
		if direction == -1 and empty % grid_size == 0:
			continue  
		
		#Caso haja uma restrição horizontal, ignora as movimentação para esquerda e direita
		if direction in [1, -1] and restrictions[neighbour] == "horizontal_locked":
			continue
			
		#Caso haja uma restrição vertical, ignora as movimentação para cima e baixo
		if direction in [grid_size, -grid_size] and restrictions[neighbour] == "vertical_locked":
			continue
			
		neighbours.push_back(neighbour)

	return neighbours

#Escolhe um dos vizinho do espaço vazio a ser movido (Provavelmente sera retirado
#E usado nivel criado manualmente
func choose_neighbour(neighbours: Array) -> int:
	randomize()
	var random_index: int = randi() % neighbours.size()
	return neighbours[random_index]

func shuffle_tiles() -> void:
	#Bem direto, acha o espaço vazio, ve quem são os vizinho e escolhe aleatoriamente um deles
	for t in range(1000):
		var empty: int = find_empty()
		var neighbours: Array = empty_neighbours(empty, restrictions)
		var moved_tile: int = choose_neighbour(neighbours)

		swap_tiles(empty, moved_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func is_valid_position(position: Vector2) -> bool:
	#Restringe o clique apenas a região do tabuleiro
	#84x84 é o tamanho do tabuleiro
	return position.x >= BOARD_OFFSET_X and position.x < BOARD_OFFSET_X + 84  \
	and position.y >= BOARD_OFFSET_Y and position.y < BOARD_OFFSET_Y + 84

func swap_tiles(tile_src: int, tile_dst: int) -> void:
	#Troca a posição da peça pelo espaço vazio no sprite
	var temp_pos: Vector2 = tiles[tile_src].position
	tiles[tile_src].position = tiles[tile_dst].position
	tiles[tile_dst].position = temp_pos

	#Troca de posição da peça pelo espaço vazio no vetor
	var temp_tile: Sprite2D = tiles[tile_src]
	tiles[tile_src] = tiles[tile_dst]
	tiles[tile_dst] = temp_tile
	
	#Troca as posições das restrições
	var temp_restriction: String = restrictions[tile_src]
	restrictions[tile_src] = restrictions[tile_dst]
	restrictions[tile_dst] = temp_restriction

	var temp_fence: Node2D = fences[tile_src]
	fences[tile_src] = fences[tile_dst]
	fences[tile_dst] = temp_fence

	# Atualize a posição dos sprites de fences
	if fences[tile_src] != null and fences[tile_src].name != "free":
		fences[tile_src].position.x = (tile_src % grid_size) * tile_size
		fences[tile_src].position.y = (tile_src / grid_size) * tile_size

	if fences[tile_dst] != null and fences[tile_dst].name != "free":
		fences[tile_dst].position.x = (tile_dst % grid_size) * tile_size
		fences[tile_dst].position.y = (tile_dst / grid_size) * tile_size

func handle_mouse_click(mouse_position: Vector2) -> void:
	if !is_valid_position(mouse_position):
		return

	var rows: int = int((mouse_position.y - BOARD_OFFSET_Y) / (tile_size))
	var cols: int = int((mouse_position.x - BOARD_OFFSET_X) / (tile_size))
	var pos: int = rows * grid_size + cols #Posição no vetor unidimensional

	#Se a peça clicacada for toltamente cercada é ignorada
	if restrictions[pos] == "locked":
		return
		
	var empty: int = find_empty()
	var neighbours: Array = empty_neighbours(empty, restrictions)

	#Verifica se a peça que o jogador clicou é vizinha ao espaço vazio
	if pos in neighbours:
		swap_tiles(empty, pos)

	if is_solved():
		print("Resolvido")
		shuffle_tiles()

func is_solved() -> bool:
	var aux: Array = []
	var actual_rows: Array = []

	#Verifica se o espaço vazio está na ultima posição(canto inferior direito) (verificação mais rapida)
	if find_empty() != tile_count - 1:
		return false

	#Meio repetitivo provalmente tem uma solução melhor
	#Transforma o vetor unidimension do estado atual do tabuleiro em um vetor MxN
	for i in range(0, tile_count):
		aux.append(str(tiles[i].name))
		if (i + 1) % grid_size == 0:
			actual_rows.append(aux)
			aux = []
	
	print(actual_rows)
	#print(solved_rows)
	"""Diferente do 15tile padrão que a ordem é numérica de 1a16, aqui precisa
	estar apenas com cada elemento na sua linha correta sem importar a coluna"""
	for i in range(0, actual_rows.size()):
		actual_rows[i].sort()
		solved_rows[i].sort()
		
		#Caso um elemento esteja fora da sua linha esperada retorna falso
		if actual_rows[i] != solved_rows[i]:
			return false

	return true

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_mouse_click(event.position)
