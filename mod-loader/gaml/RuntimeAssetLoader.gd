extends Reference

var _asset_cache = {}

func _load_asset(path: String) -> Resource:
	var extension = path.get_extension()
	if extension in ["png", "jpg", "jpeg"]: return _load_texture(path)
	if extension in ["mp3", "ogg", "wav"]: return _load_audio(path)
	return load(path)
func _load_texture(path: String, flags: int = 7) -> ImageTexture:
	var image = Image.new()
	image.load(path)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture
func _load_audio(path: String) -> AudioStream:
	var file = File.new()
	file.open(path, File.READ)
	var stream = AudioStream.new()
	var extension = path.get_extension()
	if extension == "mp3":
		stream = AudioStreamMP3.new()
		stream.data = file.get_buffer(file.get_len())
	elif extension == "ogg":
		stream = AudioStreamOGGVorbis.new()
		stream.data = file.get_buffer(file.get_len())
	elif extension == "wav":
		stream = AudioStreamSample.new()
		stream.data = file.get_buffer(file.get_len())
	return stream

func load_asset(path: String, ignore_cache: bool = false):
	if !ignore_cache:
		var cached_asset = _asset_cache.get(path, null)
		if cached_asset != null: return cached_asset
	var resource = _load_asset(path)
	_asset_cache[path] = resource
	return resource
