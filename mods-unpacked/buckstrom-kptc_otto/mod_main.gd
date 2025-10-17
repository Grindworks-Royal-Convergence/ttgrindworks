extends Node


const KPTC_OTTO_DIR := "buckstrom-kptc_otto"
const KPTC_OTTO_LOG := "buckstrom-kptc_otto:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(KPTC_OTTO_DIR)
	# Add extensions
	install_script_extensions()
	install_script_hook_files()
	_add_global_class()

func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")

func install_script_hook_files() -> void:
	extensions_dir_path = mod_dir_path.path_join("extensions")
	#ModLoaderMod.install_script_hooks("res://objects/globals/item_service.gd", extensions_dir_path.path_join("objects/globals/item_service.hooks.gd"))

func _add_global_class() -> void:
	var global_instance = load("res://mods-unpacked/buckstrom-kptc_otto/kptc_global.gd").new()
	global_instance.name = "KPTCglobal"
	add_child(global_instance)

func _ready() -> void:
	ModLoaderLog.info("Attempting to inject character.", KPTC_OTTO_LOG)
	var character_path: String = ModLoaderMod.get_unpacked_dir().path_join(KPTC_OTTO_DIR).path_join("KPTC_OTTO.tres")
	Globals.ADDITIONAL_TOON_PATHS.append(character_path)
