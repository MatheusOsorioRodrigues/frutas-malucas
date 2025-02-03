extends  Node
func _ready() -> void:
	MusicGame.play_music_level()
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	$Label.text = $UsernameInput.text.strip_edges()
	Global.username = $Label.duplicate()
	get_tree().change_scene_to_file("res://scenes/selection.tscn")
	
