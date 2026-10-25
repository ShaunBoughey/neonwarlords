extends Node
## Sound effects and music (autoload). Streams are synthesised by tools/audio/make_sfx.py and
## make_music.py into assets/audio. Music crossfades between tracks and loops seamlessly.

const NAMES := ["click", "confirm", "back", "slide", "latch", "open", "reveal", "legendary", "hit", "crit", "heal",
	"buff", "debuff", "death", "skill", "victory", "defeat", "reward", "levelup"]
const VOLUME_DB := {"click": -10.0, "hit": -6.0, "slide": -4.0, "buff": -8.0, "debuff": -8.0}

const MUSIC_DB := -9.0
var _streams := {}
var _music: Array = []     # two players for crossfading
var _music_idx := 0
var _track := ""
var _pool: Array = []
var _next := 0
var _last := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMES:
		var p := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(p):
			_streams[n] = load(p)
	for i in 10:
		var a := AudioStreamPlayer.new()
		add_child(a)
		_pool.append(a)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = -60.0
		add_child(m)
		_music.append(m)

func music_enabled() -> bool:
	return Game.S.is_empty() or bool(Game.S.settings.get("music", true))

## Crossfade to a music track ("city", "battle") or fade out with "".
func music(name: String, fade := 1.2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not music_enabled():
		name = ""
	if name == _track:
		return
	_track = name
	var old: AudioStreamPlayer = _music[_music_idx]
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.stop)
	if name == "":
		return
	var p := "res://assets/audio/music_%s.wav" % name
	if not ResourceLoader.exists(p):
		return
	var st: AudioStreamWAV = load(p)
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = int(st.get_length() * st.mix_rate)
	_music_idx = 1 - _music_idx
	var nw: AudioStreamPlayer = _music[_music_idx]
	nw.stream = st
	nw.pitch_scale = 1.0          # music tempo never follows battle speed
	nw.volume_db = -40.0
	nw.play()
	create_tween().tween_property(nw, "volume_db", MUSIC_DB, fade)

## Re-evaluate after the music setting changes.
func refresh_music(name: String) -> void:
	var want := name
	_track = "-"
	music(want if music_enabled() else "")

## Battle sounds space out more at x2 / x3 battle speed so fast fights sound busy, not frantic.
func min_gap_ms(name: String) -> int:
	if not name in ["hit", "crit", "heal", "buff", "debuff", "skill", "death"]:
		return 40
	var spd := 1
	if not Game.S.is_empty():
		spd = int(Game.S.settings.get("speed", 1))
	return [90, 160, 240][clampi(spd - 1, 0, 2)]

func enabled() -> bool:
	return Game.S.is_empty() or bool(Game.S.settings.get("sfx", true))

func play(name: String, pitch := 1.0) -> void:
	if not enabled() or not _streams.has(name) or DisplayServer.get_name() == "headless":
		return
	# avoid machine-gun stacking of the same sound within a frame or two
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < min_gap_ms(name):
		return
	_last[name] = now
	var a: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	a.stream = _streams[name]
	a.volume_db = VOLUME_DB.get(name, -3.0)
	a.pitch_scale = pitch * randf_range(0.97, 1.03)
	a.play()
