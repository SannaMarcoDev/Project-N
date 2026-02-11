extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String
@export var balloon_tscn: PackedScene

@onready var sprite = $Sprite2D

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.3, 1.3, 1.3)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited():
	sprite.modulate = Color(1.0, 1.0, 1.0)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_dialogue()

func start_dialogue():
	var baloon = balloon_tscn.instantiate()
	get_tree().current_scene.add_child(baloon)

	if dialogue_resource:
			baloon.start(dialogue_resource, dialogue_start)
