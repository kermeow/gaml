extends GutTest

var Semver = load("res://gaml/Semver.gd")

class TestParse:
	extends GutTest

	var _semver = null

	func before_all():
		_semver = Semver.parse("1.2.3-4.5.6+789")

	func test_major(): assert_eq(_semver.major, 1)
	func test_minor(): assert_eq(_semver.minor, 2)
	func test_patch(): assert_eq(_semver.patch, 3)

	func test_prerelease(): assert_eq(_semver.prerelease, "4.5.6")
	func test_build(): assert_eq(_semver.build, "789")

class TestToString:
	extends GutTest

	func test_release():
		var text = "1.2.3"
		assert_eq(Semver.parse(text).to_string(), text)

	func test_prerelease():
		var text = "1.2.3-alpha"
		assert_eq(Semver.parse(text).to_string(), text)

	func test_build():
		var text = "1.2.3+build"
		assert_eq(Semver.parse(text).to_string(), text)

	func test_prerelease_build():
		var text = "1.2.3-alpha+build"
		assert_eq(Semver.parse(text).to_string(), text)

class TestCompare:
	extends GutTest

	func test_major():
		var a = Semver.parse("1.2.3")
		var b = Semver.parse("2.2.3")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)
		assert_eq(a.compare(a), 0)
		assert_eq(b.compare(b), 0)
	func test_minor():
		var a = Semver.parse("1.2.3")
		var b = Semver.parse("1.3.3")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)
		assert_eq(a.compare(a), 0)
		assert_eq(b.compare(b), 0)
	func test_patch():
		var a = Semver.parse("1.2.3")
		var b = Semver.parse("1.2.4")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)
		assert_eq(a.compare(a), 0)
		assert_eq(b.compare(b), 0)

	func test_release_prerelease():
		var a = Semver.parse("1.2.3-alpha")
		var b = Semver.parse("1.2.3")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)
	func test_prereleases():
		var a = Semver.parse("1.2.3-alpha")
		var b = Semver.parse("1.2.3-beta")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)
	func test_release_candidates():
		var a = Semver.parse("1.2.3-rc1")
		var b = Semver.parse("1.2.3-rc2")
		assert_eq(a.compare(b), -1)
		assert_eq(b.compare(a), 1)

class TestValid:
	extends GutTest

	func test_valid(): assert_eq(Semver.is_valid("1.2.3-alpha+build"), true)
	func test_invalid(): assert_eq(Semver.is_valid("Invalid Version"), false)
