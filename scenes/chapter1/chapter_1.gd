extends Node2D

@export var balloon_tscn: PackedScene
@export var initial_dialogue: Resource
@onready var sfondo_rect: TextureRect = $Sfondo

func _ready():
	# Facciamo partire il dialogo dopo 1 secondo
	await get_tree().create_timer(1.0).timeout
	start_my_dialogue("start")

func start_my_dialogue(title: String):
	var balloon = balloon_tscn.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(initial_dialogue, title, [self])

func cambia_sfondo(image_path: String):
	var new_texture = load(image_path)
	
	if new_texture:
		var tween = create_tween()
		tween.tween_property(sfondo_rect, "modulate:a", 0.0, 0.5) # 0.5 secondi fade out        
		tween.tween_callback(func(): sfondo_rect.texture = new_texture)
		tween.tween_property(sfondo_rect, "modulate:a", 1.0, 0.5) # 0.5 secondi fade in
	else:
		push_error("Immagine non trovata: " + image_path)
