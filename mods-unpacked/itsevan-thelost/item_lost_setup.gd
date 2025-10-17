extends ItemCharSetup


## Items related only to increasing laff / health recovery
const EXLUDE_ITEMS: Array[String] = [
	"res://objects/items/resources/passive/toonups/pixie.tres",
	"res://objects/items/resources/passive/toonups/feather.tres",
	"res://objects/items/resources/passive/flower_treasure.tres",
	"res://objects/items/resources/passive/ice_cream_treasure.tres",
	"res://objects/items/resources/passive/music_treasure.tres",
	"res://objects/items/resources/passive/snowflake_treasure.tres",
	"res://objects/items/resources/passive/starfish_treasure.tres",
	"res://objects/items/resources/passive/zzz_treasure.tres",
	"res://objects/items/resources/accessories/hats/top_hat.tres",
	"res://objects/items/resources/passive/laff_boost.tres",
]


func first_time_setup(player: Player) -> void:
	for track in player.stats.gags_unlocked.keys():
		player.stats.gags_unlocked[track] = 7
	player.stats.luck = 1.05
	
	for path in EXLUDE_ITEMS:
		ItemService.seen_item(load(path))
