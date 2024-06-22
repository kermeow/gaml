extends Resource
class_name Semver

const REGEX = "^(?P<major>0|[1-9]\\d*)\\.(?P<minor>0|[1-9]\\d*)\\.(?P<patch>0|[1-9]\\d*)(?:-(?P<prerelease>(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+(?P<build>[0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"

var major: int = 0
var minor: int = 0
var patch: int = 0
var prerelease: String
var build: String

static func is_valid(string: String) -> bool:
	var regex = RegEx.create_from_string(REGEX)
	if !regex.is_valid(): return false

	var data = regex.search(string)
	if data == null: return false

	return true

static func parse(string: String) -> Semver:
	var semver = new()

	var regex = RegEx.create_from_string(REGEX)
	if !regex.is_valid(): return semver

	var data = regex.search(string)
	if data == null: return semver

	semver.major = int(data.get_string("major"))
	semver.minor = int(data.get_string("minor"))
	semver.patch = int(data.get_string("patch"))
	semver.prerelease = data.get_string("prerelease")
	semver.build = data.get_string("build")

	return semver

func _to_string():
	var string = "%s.%s.%s" % [major, minor, patch]
	if !prerelease.is_empty(): string += "-%s" % prerelease
	if !build.is_empty(): string += "+%s" % build
	return string

func compare(b: Semver) -> int:
	if self.major != b.major: return 1 if self.major > b.major else -1
	if self.minor != b.minor: return 1 if self.minor > b.minor else -1
	if self.patch != b.patch: return 1 if self.patch > b.patch else -1

	if self.prerelease.is_empty() and b.prerelease.is_empty(): return 0
	if self.prerelease.is_empty() or b.prerelease.is_empty(): return 1 if self.prerelease.is_empty() else -1
	if self.prerelease != b.prerelease:
		var a_fields = self.prerelease.split(".", false)
		var b_fields = b.prerelease.split(".", false)
		var min_fields = min(a_fields.size(), b_fields.size())
		for i in min_fields:
			var a_field = a_fields[i]
			var b_field = b_fields[i]
			if a_field == b_field: continue
			var a_num = int(a_field)
			var a_is_num = a_field.is_valid_int()
			var b_num = int(b_field)
			var b_is_num = b_field.is_valid_int()
			if a_is_num and b_is_num: return 1 if a_num > b_num else -1
			if a_is_num or b_is_num: return 1 if b_is_num else -1
			return 1 if a_field > b_field else -1
		if a_fields.size() != b_fields.size():
			return 1 if a_fields.size() > b_fields.size() else -1

	return 0
