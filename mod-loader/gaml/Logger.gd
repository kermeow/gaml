extends Reference

var mod_id: String
var output_to_console: bool = false

var file: File = File.new()

func _init(_mod_id: String):
	mod_id = _mod_id
	var file_path = GAML.paths.logs.plus_file(mod_id + ".log")
	file.open(file_path, File.WRITE)
	output("Logger initialised for %s" % mod_id)

func _notification(what):
	if what == NOTIFICATION_PREDELETE: file.close()

func _out(text: String, force_print: bool = false):
	file.store_line(text)
	file.flush()
	if output_to_console or force_print:
		print("%s: %s" % [mod_id, text])

func output(message: String, force_print: bool = false):
	var timestamp = Time.get_time_string_from_unix_time(Time.get_ticks_msec() / 1000)
	_out("[%s] %s" % [timestamp, message], force_print)
