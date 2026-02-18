extends CanvasLayer
## Popup per visualizzare la cronologia dei dialoghi


var balloon: Node

@onready var panel: PanelContainer = %HistoryPanel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var history_vbox: VBoxContainer = %HistoryVBox
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	# Inizialmente nascosto
	hide()
	close_button.pressed.connect(_on_close_pressed)


## Mostra il popup con la storia dei dialoghi
func show_history() -> void:
	# Pulisci i vecchi elementi
	for child in history_vbox.get_children():
		child.queue_free()
	
	# Ottieni la storia da GameState
	var history = GameState.get_dialogue_history()
	
	if history.is_empty():
		var empty_label = Label.new()
		empty_label.text = "[Nessun dialogo ancora]"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		history_vbox.add_child(empty_label)
		show()
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
		return
	
	# Aggiungi ogni linea di dialogo alla lista
	for entry in history:
		var line_container = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		
		var vbox = VBoxContainer.new()
		
		# Character name
		if not entry.character.is_empty():
			var character_label = RichTextLabel.new()
			character_label.custom_minimum_size = Vector2(600, 0)
			character_label.bbcode_enabled = true
			character_label.text = "[b][color=yellow]%s[/color][/b]" % entry.character
			character_label.fit_content = true
			character_label.scroll_active = false
			vbox.add_child(character_label)
		
		# Dialogue text
		var text_label = RichTextLabel.new()
		text_label.custom_minimum_size = Vector2(600, 0)
		text_label.bbcode_enabled = true
		text_label.text = entry.text
		text_label.fit_content = true
		text_label.scroll_active = false
		vbox.add_child(text_label)
		
		margin.add_child(vbox)
		line_container.add_child(margin)
		history_vbox.add_child(line_container)
	
	# Mostra il popup e scorri in basso
	show()
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)


func _on_close_pressed() -> void:
	hide()
