extends Node


const THE_LOST_DIR := "itsevan-thelost"
const THE_LOST_LOG := "itsevan-thelost:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(THE_LOST_DIR)
	# Add extensions
	install_script_extensions()
	install_script_hook_files()

func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")

func install_script_hook_files() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	ModLoaderMod.install_script_hooks("res://objects/globals/item_service.gd", extensions_dir_path.path_join("objects/globals/item_service.hooks.gd"))

func _ready() -> void:
	ModLoaderLog.info("Attempting to inject character.", THE_LOST_LOG)
	var character_path: String = ModLoaderMod.get_unpacked_dir().path_join(THE_LOST_DIR).path_join("the_lost.tres")
	Globals.ADDITIONAL_TOON_PATHS.append(character_path)
