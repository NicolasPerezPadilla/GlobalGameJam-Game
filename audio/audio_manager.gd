extends Node

# ─── MÚSICA (solo una canción a la vez) ─────────────────────────
var music_player: AudioStreamPlayer

# ─── SFX (pool de reproductores para no pisar sonidos) ──────────
const SFX_POOL_SIZE = 8
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_index = 0

# ─── Estado interno ─────────────────────────────────────────────
var _paused_by_game = false  # true cuando el juego pausó la música

func _ready():
	# Crear el reproductor de música
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	# Crear pool de SFX
	for i in range(SFX_POOL_SIZE):
		var sfx = AudioStreamPlayer.new()
		sfx.name = "SFX_" + str(i)
		sfx.bus = "SFX"
		add_child(sfx)
		sfx_pool.append(sfx)

# ═══════════════════════════════════════════════════════════════════
#  MÚSICA
# ═══════════════════════════════════════════════════════════════════

## Reproduce una canción. Si ya suena otra, la reemplaza.
## stream_path: ruta tipo "res://audio/menu_music.wav"
## loop: si debe repetirse
func play_music(stream_path: String, loop: bool = true) -> void:
	if stream_path.is_empty():
		push_warning("AudioManager: stream_path vacío en play_music()")
		return
	
	var stream = load(stream_path)
	if not stream:
		push_error("AudioManager: no se pudo cargar " + stream_path)
		return
	
	# Configurar loop según el tipo de recurso antes de asignar
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamMP3:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop = loop
	
	music_player.stream = stream
	
	music_player.play()
	_paused_by_game = false
	print("🎵 Música iniciada: ", stream_path)

## Detiene la música completamente
func stop_music() -> void:
	music_player.stop()
	_paused_by_game = false
	print("🔇 Música detenida")

## Pausa la música (se usa al pausar el juego)
func pause_music() -> void:
	if music_player.playing:
		music_player.stream_paused = true
		_paused_by_game = true
		print("⏸️  Música pausada")

## Retoma la música desde donde la dejaste
func resume_music() -> void:
	if _paused_by_game:
		music_player.stream_paused = false
		_paused_by_game = false
		print("▶️  Música retomada")

## Devuelve si la música está sonando actualmente
func is_music_playing() -> bool:
	return music_player.playing and not music_player.stream_paused

# ═══════════════════════════════════════════════════════════════════
#  SFX (efectos de sonido)
# ═══════════════════════════════════════════════════════════════════

## Reproduce un SFX sin interrumpir otros.
## stream_path: ruta tipo "res://audio/hit_sfx.wav"
## volume_db: ajuste de volumen en dB (0 = normal)
func play_sfx(stream_path: String, volume_db: float = 0.0) -> void:
	if stream_path.is_empty():
		push_warning("AudioManager: stream_path vacío en play_sfx()")
		return
	
	var stream = load(stream_path)
	if not stream:
		push_error("AudioManager: no se pudo cargar " + stream_path)
		return
	
	# Buscar reproductor libre en el pool
	var player_found: AudioStreamPlayer = null
	for i in range(SFX_POOL_SIZE):
		var idx = (sfx_pool_index + i) % SFX_POOL_SIZE
		if not sfx_pool[idx].playing:
			player_found = sfx_pool[idx]
			sfx_pool_index = (idx + 1) % SFX_POOL_SIZE
			break
	
	# Si todos están ocupados, reutilizar el más antiguo
	if not player_found:
		player_found = sfx_pool[sfx_pool_index]
		sfx_pool_index = (sfx_pool_index + 1) % SFX_POOL_SIZE
	
	player_found.stream = stream
	player_found.volume_db = volume_db
	player_found.play()
