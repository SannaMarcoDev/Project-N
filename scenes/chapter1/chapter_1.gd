extends Node2D

@export var balloon_tscn: PackedScene
@export var initial_dialogue: Resource

func _ready():
	await get_tree().create_timer(1.0).timeout
	var baloon = balloon_tscn.instantiate()
	get_tree().current_scene.add_child(baloon)
	if GameState.pressed_start == true:
		var resource = load(GameState.story_beginning)
		baloon.start(resource, "start")
		GameState.pressed_start = false
	elif GameState.continued_from_night == true:
		var resource = load(GameState.story_continue)
		baloon.start(resource, "start")
	else:
		var resource = load(GameState.story_anchor)
		baloon.start(resource, "start")
