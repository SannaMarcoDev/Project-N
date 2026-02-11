extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_load_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/chapter1/chapter1.tscn")

func _on_start_pressed() -> void:
	GameState.pressed_start = true
	get_tree().change_scene_to_file("res://scenes/chapter1/chapter1.tscn")
