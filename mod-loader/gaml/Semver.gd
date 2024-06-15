extends Reference

var major:int = 0
var minor:int = -1
var patch:int = -1

func _to_string():
	if minor < 0: return "%s" % major
	if patch < 0: return "%s.%s" % [major, minor]
	return "%s.%s.%s" % [major, minor, patch]

func parse(version:String):
	var split = version.split(".", false)
	if split.empty(): return
	if split.size() >= 3:
		patch = int(split[2])
	if split.size() >= 2:
		minor = int(split[1])
	major = int(split[0])

func eq(b): # Equal to
	var _major = major == b.major
	if minor < 0 or b.minor < 0: return _major
	var _minor = minor == b.minor
	if patch < 0 or b.patch < 0: return _major and _minor
	var _patch = patch == b.patch
	return _major and _minor and _patch

func gt(b): # Greater than
	var _major = major > b.major
	if minor < 0 or b.minor < 0: return _major
	var _minor = minor > b.minor
	if patch < 0 or b.patch < 0: return _major and _minor
	var _patch = patch > b.patch
	return _major and _minor and _patch
func ge(b): # Greater than or equal to
	return eq(b) or gt(b)

func lt(b): # Less than
	var _major = major < b.major
	if minor < 0 or b.minor < 0: return _major
	var _minor = minor < b.minor
	if patch < 0 or b.patch < 0: return _major and _minor
	var _patch = patch < b.patch
	return _major and _minor and _patch
func le(b): # Less than or equal to
	return eq(b) or lt(b)
