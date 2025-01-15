extends Area2D

#OBS: Precisa generalizar para funcionar em tabuleiros 3x3, 4x4, 5x5

const GRID_SIZE = 4
const TILE_COUNT = GRID_SIZE * GRID_SIZE
const TILE_SIZE = 20 #Tamanho em pixel
const BOARD_OFFSET_X = 5 #Espaço da borda da tela
const BOARD_OFFSET_Y = 40

var tiles = []
var solved = []
var expected_rows = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_game()

func start_game():
	#Referencia para os sprites
	tiles = [
		$Tile1, $Tile2, $Tile3, $Tile4,
		$Tile5, $Tile6, $Tile7, $Tile8,
		$Tile9, $Tile10, $Tile11, $Tile12,
		$Tile13, $Tile14, $Tile15, $Tile16
	]
	solved = tiles.duplicate() #Cópia ordenada para verificar se o nivel foi completado


	var aux = []
	for i in range(0, 16):
		aux.append(tiles[i].name)
		if (i + 1) % 4 == 0:
			expected_rows.append(aux)
			aux = []

	shuffle_tiles()

#Procura pelo espaço vazio
func find_empty():
	var count = 0
	for t in tiles:
		if t == $Tile16:
			break
		count += 1

	return count

#Verifica quais são os vizinhos ortoganais do espaço vazinho
func empty_neighbours(empty):
	var directions = [
		-GRID_SIZE,   # baixo
		GRID_SIZE,  # cima
		1,   # direita
		-1   # esquerda
	]

	var neighbours = []
	for direction in directions:
		var neighbour = empty + direction

		if neighbour < 0 or neighbour >= 16:
			continue

		#Não é necessario? Impediria que as peças da primeira coluna fossem
		#Movida para a esquerda e da ultima para a direita
		"""
		if direction == 1 and empty % GRID_SIZE == GRID_SIZE - 1:
			continue
		if direction == -1 and empty % GRID_SIZE == 0:
			continue
		"""

		neighbours.push_back(neighbour)

	return neighbours

#Escolhe um dos vizinho do espaço vazio a ser movido (Provavelmente sera retirado
#E usado nivel criado manualmente
func choose_neighbour(neighbours):
	randomize()
	var random_index = randi() % neighbours.size()
	return neighbours[random_index]

func shuffle_tiles():
	#Bem direto, acha o espaço vazio, ve quem são os vizinho e escolhe aleatoriamente um deles
	for t in range(1000):
		var empty = find_empty()
		var neighbours = empty_neighbours(empty)
		var moved_tile = choose_neighbour(neighbours)

		swap_tiles(empty, moved_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func is_valid_position(position: Vector2) -> bool:
	#Restringe o clique apenas a região do tabuleiro
	return position.x >= 5 and position.x < 85 and position.y >= 40 and position.y < 120

func swap_tiles(tile_src, tile_dst):
	#Troca de posição da peça pelo espaço vazio no sprite
	var temp_pos = tiles[tile_src].position
	tiles[tile_src].position = tiles[tile_dst].position
	tiles[tile_dst].position = temp_pos

	#Troca a posição da peça pelo espaço vazio no vetor
	var temp_tile = tiles[tile_src]
	tiles[tile_src] = tiles[tile_dst]
	tiles[tile_dst] = temp_tile

func handle_mouse_click(mouse_position):
	if !is_valid_position(mouse_position):
		return

	var rows = int((mouse_position.y - BOARD_OFFSET_Y) / (TILE_SIZE))
	var cols = int((mouse_position.x - BOARD_OFFSET_X)/ (TILE_SIZE))
	var pos = rows * GRID_SIZE + cols #Posição no vetor unidimensional

	var empty = find_empty()
	var neighbours = empty_neighbours(empty)

	#Verifica se a peça que o jogador clicou é vizinha ao espaço vazio
	if pos in neighbours:
		swap_tiles(empty, pos)

	if is_solved():
		print("Resolvido")
		shuffle_tiles()


func is_solved() -> bool:
	var aux = []
	var actual_rows = []

	#Verifica se o espaço vazio está na ultima posição(canto inferior direito) (verificação mais rapida)
	if find_empty() != 15:
		return false

	#Meio repetitivo provalmente tem uma solução melhor
	for i in range(0, 16):
		aux.append(tiles[i].name)
		if (i + 1) % 4 == 0:
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
