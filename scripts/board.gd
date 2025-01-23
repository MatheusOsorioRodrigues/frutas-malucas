extends Area2D

#OBS: Precisa generalizar para funcionar em tabuleiros 3x3, 4x4, 5x5
var grid_size: int = 4
var tile_count: int = grid_size * grid_size
const BOARD_OFFSET_X: int = 3 #Espaço da borda da tela
const BOARD_OFFSET_Y: int = 42

var scale_tile: float = 0.035
var tile_size: float = 600 * scale_tile
var tiles: Array = []
var solved: Array = []
var expected_rows: Array = []
var restrictions: Array = [] 
var fences: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var tile: Sprite2D = $Frutas/Tile0
	var sprite: Sprite2D = $Background

	var texture_size: Vector2 = sprite.texture.get_size()

	# Calcular escala
	var scale_x: float = screen_size.x / texture_size.x
	var scale_y: float = screen_size.y / texture_size.y

	var scale_factor: float = max(scale_x, scale_y)

	# Ajustar o sprite com o fator de escala
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Ajustar a posição do sprite para manter o fundo centralizado
	var offset_x: float = (screen_size.x - texture_size.x * scale_factor) / 2
	var offset_y: float = (screen_size.y - texture_size.y * scale_factor) / 2
	sprite.position = Vector2(offset_x + 42, offset_y + 58)
	
	start_game()

func start_game() -> void:
	#Referencia para os sprites
	tiles = [
		$Frutas/Tile1, $Frutas/Tile2, $Frutas/Tile3, $Frutas/Tile4,
		$Frutas/Tile5, $Frutas/Tile6, $Frutas/Tile7, $Frutas/Tile8,
		$Frutas/Tile9, $Frutas/Tile10, $Frutas/Tile11, $Frutas/Tile12,
		$Frutas/Tile13, $Frutas/Tile14, $Frutas/Tile15, $Frutas/Tile0
	]
	restrictions = [
		"free", "free", "locked", "horizontal_locked",
		"free", "free", "free", "free",
		"free", "vertical_locked", "free", "free",
		"free", "free", "free", "free",
	]

	var aux: Array = []
	for i in range(0, tile_count):
		aux.append(tiles[i].name)
		if (i + 1) % grid_size == 0:
			expected_rows.append(aux)
			aux = []

	instantiate_fences(restrictions)
	shuffle_tiles()

func instantiate_fences(restrictions: Array) -> void:
	#Dependendo do tipo de restrição instancia a cena da cerca
	var scene: PackedScene
	for i in range(len(restrictions)):
		if restrictions[i] == "free":
			fences.append(null)
			continue
		elif restrictions[i] == "locked":
			scene = load("res://actors/fullFence.tscn") 
			
		elif restrictions[i] == "horizontal_locked":
			scene = load("res://actors/verticalFence.tscn")

		elif restrictions[i] == "vertical_locked":
			scene = load("res://actors/horizontalFence.tscn")

		var instance: Node2D = scene.instantiate()			
		#Calcula a posição da cerca na tela de acordo com a posição da restrição
		instance.position.x += (i % grid_size) * tile_size
		instance.position.y += (i / grid_size) * tile_size
		add_child(instance)
		fences.append(instance)

#Procura pelo espaço vazio
func find_empty() -> int:
	var count: int = 0
	for t in tiles:
		if t == $Frutas/Tile0:
			break
		count += 1

	return count

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
	
	#print(fences)
	#print(temp_restriction)
	#		instance.position.x += (i % grid_size) * tile_size
	#	instance.position.y += (i / grid_size) * tile_size
	print(tile_src)
	print(tile_dst)
	print("\n")
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
		aux.append(tiles[i].name)
		if (i + 1) % grid_size == 0:
			actual_rows.append(aux)
			aux = []
	
	"""Diferente do 15tile padrão que a ordem é numérica de 1a16, aqui precisa
	estar apenas com cada elemento na sua linha correta sem importar a coluna"""
	for i in range(0, actual_rows.size()):
		actual_rows[i].sort()
		expected_rows[i].sort()
		
		#Caso um elemento esteja fora da sua linha esperada retorna falso
		if actual_rows[i] != expected_rows[i]:
			return false

	return true

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_mouse_click(event.position)
