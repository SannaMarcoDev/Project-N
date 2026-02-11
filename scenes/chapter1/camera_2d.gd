extends Camera2D

# Configurazione
@export var forza_movimento: float = 30.0 # Quanti pixel si sposta la camera al massimo
@export var fluidita: float = 5.0 # Più è alto, più il movimento è veloce/reattivo

# Variabili interne
var target_offset = Vector2.ZERO

func _process(delta):
    # 1. Trova la posizione del mouse nella finestra (0,0 è in alto a sx)
    var mouse_pos = get_viewport().get_mouse_position()
    
    # 2. Ottieni la dimensione della finestra
    var screen_size = get_viewport().get_visible_rect().size
    
    # 3. Calcola il centro dello schermo
    var center = screen_size / 2.0
    
    # 4. Calcola la distanza del mouse dal centro (in percentuale da -1 a 1)
    # Esempio: Se il mouse è tutto a destra, 'dist_x' sarà 1.0. Al centro è 0.0.
    var dist_x = (mouse_pos.x - center.x) / center.x
    var dist_y = (mouse_pos.y - center.y) / center.y
    
    # 5. Definisci l'offset target
    # Nota: Moltiplichiamo per 'forza_movimento'. 
    target_offset = Vector2(dist_x, dist_y) * forza_movimento
    
    # 6. Applica il movimento fluido (Interpolazione Lineare - Lerp)
    # Usiamo 'offset' invece di 'position' per non rompere l'ancoraggio se ne usi uno
    offset = offset.lerp(target_offset, fluidita * delta)
    
    # 7. (Opzionale ma consigliato) Limiti rigidi
    # Se per qualche motivo lo sfondo è piccolo, questo evita di uscire.
    # Calcola il margine massimo consentito dallo zoom
    var max_limit_x = (screen_size.x / zoom.x - screen_size.x) / 2 # Esempio di logica limiti
    # Nota: Con lo script sopra basato su 'forza_movimento', se imposti la forza
    # inferiore al margine creato dallo zoom 1.1, non uscirai mai dai bordi.
    # Con Zoom 1.1 su 1920x1080, hai circa 90px di margine per lato.
    # Quindi se 'forza_movimento' è < 90, sei al sicuro senza calcoli complessi!
