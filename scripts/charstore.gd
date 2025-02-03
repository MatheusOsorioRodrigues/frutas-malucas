extends Control

func _process(_delta: null):
	$RichTextLabel/control.position.x = -$HScrollBar.value
