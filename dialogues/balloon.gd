extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.


## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## Enable or disable automatic dialogue advancement
@export var auto_advance_enabled: bool = false

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

@onready var portrait: TextureRect = %Portrait
## Temporary game states
var temporary_game_states: Array = []

## History of dialogue lines (last 20)
var dialogue_history: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## Flag to prevent input processing while skipping
var is_skipping: bool = false

## Flag to prevent re-entrancy when advancing to the next line
var is_advancing: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## A timer for auto-advancing to the next dialogue line after 2 seconds
var auto_advance_timer: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress

## The button to toggle auto-advance
@onready var enable_auto_button: Button = %EnableAutoButton

## The button to open dialogue history
@onready var open_history_button: Button = %OpenHistory

## History popup reference
var history_popup: Node = null


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	GameState.register_baloon(self)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	add_child(auto_advance_timer)

	# Setup history popup
	_setup_history_popup()

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")
	if Input.is_action_pressed("dialogic_skip") and dialogue_label.is_typing and not is_skipping:
		is_skipping = true
		dialogue_label.skip_typing()
		await get_tree().create_timer(0.05).timeout
		next(dialogue_line.next_id)
		is_skipping = false


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	auto_advance_timer.stop()

	# Add current dialogue line to history (max 20 lines)
	_add_to_dialogue_history(dialogue_line)

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")
	var portrait_path = "res://characters/portraits/%s.png" % dialogue_line.character.to_lower()
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
		portrait.show()
	else:
		portrait.hide()

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
		# Avvia il timer di 2 secondi per il passaggio automatico
		auto_advance_timer.start(2.0)


## Go to the next line
func next(next_id: String) -> void:
	if is_advancing:
		return
	is_advancing = true
	auto_advance_timer.stop()
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	is_advancing = false


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_auto_advance_timeout() -> void:
	# Passa automaticamente alla prossima linea dopo 2 secondi
	if auto_advance_enabled and is_waiting_for_input and not is_advancing:
		next(dialogue_line.next_id)


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# Ignora i movimenti del mouse per non bloccare il timer
	if event is InputEventMouseMotion:
		return
	
	if is_skipping:
		return
	
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	# Annulla il timer di auto-advance se l'utente clicca
	auto_advance_timer.stop()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion


func _on_enable_auto_pressed() -> void:
	auto_advance_enabled = not auto_advance_enabled
	if auto_advance_enabled:
		enable_auto_button.self_modulate = Color.RED
	else:
		enable_auto_button.self_modulate = Color.WHITE


## Add a dialogue line to history, keeping only the last 20
func _add_to_dialogue_history(line: DialogueLine) -> void:
	if line == null:
		return
	
	# Create a dictionary to store dialogue info
	var dialogue_entry = {
		"character": line.character,
		"text": line.text,
		"id": line.id,
		"timestamp": Time.get_ticks_msec()
	}
	
	dialogue_history.append(dialogue_entry)
	
	# Keep only the last 20 lines
	if dialogue_history.size() > 20:
		dialogue_history.pop_front()
	
	# Update GameState with the current history
	GameState.update_dialogue_history(dialogue_history.duplicate())


## Get the dialogue history
func get_dialogue_history() -> Array:
	return dialogue_history.duplicate()


## Clear the dialogue history
func clear_dialogue_history() -> void:
	dialogue_history.clear()
	GameState.update_dialogue_history(dialogue_history.duplicate())


## Setup the history popup
func _setup_history_popup() -> void:
	var history_scene = load("res://dialogues/dialogue_history_popup.tscn")
	if history_scene:
		history_popup = history_scene.instantiate()
		get_tree().root.add_child(history_popup)
		open_history_button.pressed.connect(_on_open_history_pressed)


## Open the history popup
func _on_open_history_pressed() -> void:
	if history_popup:
		history_popup.show_history()
