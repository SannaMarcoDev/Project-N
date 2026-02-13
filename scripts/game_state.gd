extends Node2D

#Story global variables
var petr_alive: bool = true
var stole_food: bool = true
var story_anchor: String = ""
var story_continue: String = ""
var story_beginning: String = "res://dialogues/storyboard/prologue/prologue.dialogue"
var pressed_start: bool = false

#Chapter1
#Day Freeroam
var day1_night_kitchen_talk: bool = false
var day1_night_nele_talk: bool = false
var day1_night_generator_checked = false
var day1_bench_checked = false
var continued_from_night: bool = false
#Day2 Freeroam
var day2_ivan_talk: bool = false
var day2_bocia_talk: bool = false
var day2_nele_talk: bool = false
var day2_train_found: bool = false
var day2_bocia_quest_done: bool = false

var _current_baloon: Node
var _looping_audio_player: AudioStreamPlayer = null

func _input(_event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func register_baloon(baloon: Node) -> void:
	_current_baloon = baloon

func change_background(image_path: String) -> void:
	var current_scene = get_tree().current_scene
	var background_node = current_scene.find_child("Background", true, false)

	if background_node and background_node is TextureRect:
		var new_texture = load(image_path)
		
		if new_texture:
			_transition_background(background_node, new_texture)
		else:
			push_error("Immagine non trovata: " + image_path)
	else:
		push_error("Nodo Background non trovato nella scena corrente.")

func _transition_background(node: TextureRect, new_texture: Texture2D) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.5)     
	tween.tween_callback(func(): node.texture = new_texture)
	tween.tween_property(node, "modulate:a", 1.0, 0.5)

func remove_child_by_name(child_name: String) -> void:
	var current_scene = get_tree().current_scene
	var child_node = current_scene.find_child(child_name, true, false)
	
	if child_node:
		child_node.queue_free()
	else:
		push_error("Nodo " + child_name + " non trovato nella scena corrente.")

func hide_node(node_names: PackedStringArray) -> void:
	var current_scene = get_tree().current_scene
	
	for node_name in node_names:
		var node = current_scene.find_child(node_name, true, false)
		
		if node:
			var tween = create_tween()
			tween.tween_property(node, "modulate:a", 0.0, 0.5)
			tween.tween_callback(func(): node.visible = false)
		else:
			push_error("Nodo " + node_name + " non trovato nella scena corrente.")

func show_node(node_names: PackedStringArray) -> void:
	var current_scene = get_tree().current_scene
	
	for node_name in node_names:
		var node = current_scene.find_child(node_name, true, false)
		
		if node:
			node.visible = true
			node.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(node, "modulate:a", 1.0, 0.5)
		else:
			push_error("Nodo " + node_name + " non trovato nella scena corrente.")

func wait(seconds: float = 3.0) -> void:
	await get_tree().create_timer(seconds).timeout

func play_sfx(sfx_path: String) -> void:
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	var audio_stream = load(sfx_path)
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
	else:
		push_error("File audio non trovato: " + sfx_path)
		audio_player.queue_free()

func play_sfx_loop(sfx_path: String) -> void:
	# Ferma il loop precedente se esiste
	if _looping_audio_player != null:
		stop_sfx_loop()
	
	_looping_audio_player = AudioStreamPlayer.new()
	add_child(_looping_audio_player)
	
	var audio_stream = load(sfx_path)
	if audio_stream:
		_looping_audio_player.stream = audio_stream
		_looping_audio_player.finished.connect(_on_loop_audio_finished)
		_looping_audio_player.play()
	else:
		push_error("File audio non trovato: " + sfx_path)
		_looping_audio_player.queue_free()
		_looping_audio_player = null

func _on_loop_audio_finished() -> void:
	if _looping_audio_player != null:
		_looping_audio_player.play()

func stop_sfx_loop() -> void:
	if _looping_audio_player != null:
		_looping_audio_player.stop()
		_looping_audio_player.queue_free()
		_looping_audio_player = null

func change_scene(scene_path: String) -> void:
	_current_baloon = null
	get_tree().change_scene_to_file.call_deferred(scene_path)
