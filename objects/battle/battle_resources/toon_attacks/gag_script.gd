# An original “gag” track inspired by Operation: Dessert Storm’s Techbots. Minimal in flashiness, excelling in utility.

extends ToonAttack
class_name GagScript



func action() -> void:
    # This function defines the behavior of the Gag track when it is played.
    var player = util.get_player() 
    # get the target cog selected 
    var target = targets[0]
    match attack_name:
        "loop('swim')":
            # Swim animation: +10% Evasiveness for this round
            manager.add_status_effect(create_buff(player))
            play_animation("swim")

        "play('confused')":
            # Shuffle all gag points into random tracks
            shuffle_gag_points(player)
            play_animation("confused")

        "play_resistanceSalute":
            # Reduce damage of the next attack by 2 (stacks)
            reduce_damage(2)
            play_animation("resistanceSalute")

        "~evaluatePerformance":
            # Reveal or fire a Cog based on HP threshold
            evaluate_performance(target)

        "~schadenfreude":
            # Hack a Cog to damage itself and an adjacent Cog
            schadenfreude_attack(target)

        "play('think')":
            # Give all other gag tracks +2 points at the end of the round
            boost_other_gag_tracks(player)
            play_animation("think")

        "denialOfService":
            # Stun all Cogs for 1 round and disable this track for 4 rounds
            stun_all_cogs()
# TODO change this to StatBoostAdditive (new subclass that will allow adding to the stats instead of multiplying)
func create_buff(player: Player) -> StatBoost:
    var effect = STAT_BOOST.duplicate()
    effect.quality = StatusEffect.EffectQuality.POSITIVE
    effect.boost = 0.1
    effect.stat = 'evasiveness'
    effect.target = player
    return effect

func shuffle_gag_points(player: Player) -> void:
    # This function redistributes a player's gag balance points across their gag loadout tracks.
    var tracks = player.stats.gag_balance.keys()
    var points = player.stats.gag_balance.values()
    var new_points = {}
    for track in tracks:
        new_points[track] = 0
    for track in points:
        randomize()
        var new_track = tracks[randi_range(0, tracks.size() - 1)]
        new_points[new_track] += points[track]
    player.stats.gag_balance = new_points

func reduce_damage(amount: int) -> void:
    # This function subtracts the damage of the next cog attack by the specified amount. (Stacks)
    var player = util.get_player()
   # first cog thats in the battlemgr
    var cog = manager.cogs[0]
    var orig_dmg = cog.stats.damage
    cog.stats.damage -= amount
    
    

func evaluate_performance(target: Cog) -> void:
    # Use once on a Cog to reveal a health threshold between 10%-60% max HP that lasts for 3 rounds. 
    # Use again while they are below the threshold to instantly fire the Cog. 
    # HP Threshold is halved on Boss Cogs.
    if target.stats.hp < target.stats.hp_threshold and target.stats.hp_threshold_active and target.stats.hp_threshold_turns > 0:
        # fire the cog 
        # TODO figure out how to fire the cog from here

    if target.stats.hp_threshold_turns == 0 and not target.stats.hp_threshold_active:
        var threshold = randi_range(0.1 * target.stats.get("max_hp"), 0.6 * target.stats.get("max_hp"))
        if target.dna.suit == CogDNA.SuitType.BOSS:
            threshold /= 2
        target.stats.hp_threshold = threshold
        target.stats.hp_threshold_active = true
        target.stats.hp_threshold_turns = 3
    if target.stats.hp_threshold_active and target.stats.hp_threshold_turns > 0:
        target.stats.hp_threshold_turns -= 1
    
func schadenfreude_attack(target: Cog) -> void:
    # Hack into a Cog under 60% HP to make them laugh at a random adjacent Cog, 
    # damaging both them and itself for 16% of their max HPs. 
    # (8% for Boss Cogs)
    var adjacent_cogs = get_adjacent_cogs(target)
    var target_hp = target.stats.hp
    var target_max_hp = target.stats.get("max_hp")
    var damage = 0.16 * target_max_hp
    if target.dna.suit == CogDNA.SuitType.BOSS:
        damage /= 2
    target.stats.hp -= damage
    for cog in adjacent_cogs:
        var cog_hp = cog.stats.hp
        var cog_max_hp = cog.stats.get("max_hp")
        var damage = 0.16 * cog_max_hp
        if cog.dna.suit == CogDNA.SuitType.BOSS:
            damage /= 2
        cog.stats.hp -= damage

func get_adjacent_cogs(target: Cog) -> Array:
    # This function returns an array of Cogs adjacent to the target Cog.
    var adjacent_cogs = []
    # check for cogs -1 and +1 from the target cog via index
    var cogsInBattle = manager.cogs
    var targetIndex = cogsInBattle.index(target)
    if targetIndex > 0:
        adjacent_cogs.append(cogsInBattle[targetIndex - 1])
    if targetIndex < cogsInBattle.size() - 1:
        adjacent_cogs.append(cogsInBattle[targetIndex + 1]
    return adjacent_cogs

func boost_other_gag_tracks(player: Player) -> void:
    # This function adds 2 points to all other gag tracks at the end of the round.
    var tracks = player.stats.gag_balance.keys()
    for track in tracks:
        if track != "Script":
            player.stats.gag_balance[track] += 2

func stun_all_cogs() -> void:
    # This function stuns all Cogs for 1 round.
    return
    # for cog in manager.cogs:
        
        # TODO create a new status effect for stun similar to lured but doesn't bring the cog forward and doesn't activate traps 
    # TODO create a new status effect similar to budget cuts but for the Scripts track
    # we can disable the gag by temporarily changing gags_unlocked["Script"] to 0 and then back to player's gag_unlocked["Script"] after 4 rounds
    
func play_animation(animation: String) -> void:
    # This function plays the specified animation.
    return
    # TODO implement animation playback for the Gag track