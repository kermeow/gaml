# Godot Advanced Mod Loader
>[!WARNING]
>This tool is still deep in development and breaking changes will come with every new version. For simpler mods that only involve skinning/asset replacement, consider [GUMM](https://github.com/KoBeWi/Godot-Universal-Mod-Manager).

**GAML** takes advantage of Godot's built-in features to inject itself and other mods into any[^1] Godot game.
[^1]: Not all builds of the engine are confirmed to be working.

## Why GAML?
GAML gives mod developers more freedom compared to existing mod loaders, allowing mods to run code both before and after the game is loaded.

## To-do
- [ ] Installation flow
	- [ ] Create required files
	- [ ] Generate configurations
		- [ ] Replace autoloads
- [ ] Mod loading flow
	- [ ] "Inject" mod loader (via bootstrapper?)
	- [ ] Load & verify mods
	- [ ] Initialise mods
	- [ ] Load game
- [ ] Harmony-esque hooking
	- [ ] Prefixes
	- [ ] Postfixes
	- [ ] Result replacement
- [ ] Mono support