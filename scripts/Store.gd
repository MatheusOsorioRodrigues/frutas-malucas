extends TabBar


func _process(_delta):
	#faz a scrollbar da loja funcionar
	$RichTextLabel/storecontrol.x = -$HScrollBar.value
