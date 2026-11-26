--[[
    WrenchHub.lua  (Roblox Bedwars, client script)
    Panels : COMBAT (Kill Aura, Projectile Aimbot, Spin Bot)
             RENDER (Player ESP, Tracers, Target Info, Fullbright, FPS Boost, Projectile Tracers)
             HUD    (Stats, Keystrokes, Mod Overlay)
             MOVEMENT (Scaffold, Velocity / Speed)
             MISC   (Notifications, Config, Unload)
    Menu   : RightShift. Left click = toggle. Right click = settings.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")

local env = (getgenv and getgenv()) or _G
if env.__WrenchHub then pcall(env.__WrenchHub.Unload) end

local LP = Players.LocalPlayer
local function cam() return workspace.CurrentCamera end

--------------------------------------------------------------------------------
-- STATIC ASSET DATA (from ItemList.lua & bedwars-data.json, no item-meta require)
--------------------------------------------------------------------------------
local AssetData = {
    Items = {
        ["adetunde_crown"] = "rbxassetid://86937563742464",
        ["aery_crown"] = "rbxassetid://89182458179318",
        ["alchemist_flask"] = "rbxassetid://84285189264686",
        ["altar_block_one"] = "rbxassetid://105645779003606",
        ["altar_block_three"] = "rbxassetid://105645779003606",
        ["altar_block_two"] = "rbxassetid://105645779003606",
        ["amber_leaves"] = "rbxassetid://101544303522103",
        ["andesite"] = "rbxassetid://9072552631",
        ["angel_wings"] = "rbxassetid://106770315650906",
        ["glitch_apple"] = "rbxassetid://85613757413443",
        ["aqua_47"] = "rbxassetid://113246928862585",
        ["aquamarine_lantern"] = "rbxassetid://12948863284",
        ["arrow"] = "rbxassetid://89605203077600",
        ["attack_helicopter_deploy"] = "rbxassetid://102641180486789",
        ["auto_cannon"] = "rbxassetid://132685096244917",
        ["classic_auto_turret"] = "rbxassetid://77843550094090",
        ["baby_penguin"] = "rbxassetid://136614442924007",
        ["bacon_blade"] = "rbxassetid://104614170504702",
        ["ballista"] = "rbxassetid://121512938658751",
        ["anniversary_balloon"] = "rbxassetid://78097557556371",
        ["balloon"] = "rbxassetid://99045155978473",
        ["banana_peel"] = "rbxassetid://83454769312759",
        ["bananarang"] = "rbxassetid://74445454836367",
        ["lobby_boomerang"] = "rbxassetid://74445454836367",
        ["barbarian_helmet"] = "rbxassetid://132809891064276",
        ["barrel"] = "rbxassetid://14968393558",
        ["barrier"] = "rbxassetid://10569969807",
        ["battle_axe"] = "rbxassetid://93828418345575",
        ["beachball"] = "rbxassetid://140175105438118",
        ["bear_claws"] = "rbxassetid://95594113599824",
        ["bed_gadget"] = "rbxassetid://86437182247013",
        ["bedrock"] = "rbxassetid://9207283973",
        ["bee"] = "rbxassetid://88746323274718",
        ["bee_net"] = "rbxassetid://121669119829404",
        ["beehive"] = "rbxassetid://96425673732216",
        ["beehive_grenade"] = "rbxassetid://115536240808342",
        ["fishing_rod_1"] = "rbxassetid://76640442270774",
        ["big_head_potion"] = "rbxassetid://88303142424806",
        ["big_shield"] = "rbxassetid://113931665593265",
        ["glitch_big_shield"] = "rbxassetid://113931665593265",
        ["big_wood_sword"] = "rbxassetid://77272345986931",
        ["birch_log"] = "rbxassetid://7884365859",
        ["wood_plank_birch"] = "rbxassetid://7884372418",
        ["clay_black"] = "rbxassetid://7884367004",
        ["black_market_upgrade_1"] = "rbxassetid://79239695472649",
        ["black_market_upgrade_2"] = "rbxassetid://79239695472649",
        ["black_market_upgrade_3"] = "rbxassetid://79239695472649",
        ["wool_black"] = "rbxassetid://7923576966",
        ["blackhole_bomb"] = "rbxassetid://130869037713941",
        ["ceramic"] = "rbxassetid://7884366622",
        ["healing_slime"] = "rbxassetid://81225688778590",
        ["gashapon"] = "rbxassetid://70687709005712",
        ["block_kicker_block"] = "rbxassetid://89605203077600",
        ["block_radar"] = "rbxassetid://76601005190878",
        ["clay_blue"] = "rbxassetid://7884367119",
        ["cotton_candy_block_blue"] = "rbxassetid://119678865521899",
        ["wool_blue"] = "rbxassetid://7923577182",
        ["blunderbuss"] = "rbxassetid://82304680965169",
        ["boba_blaster"] = "rbxassetid://89898521694688",
        ["boba_pearl"] = "rbxassetid://126679144965117",
        ["bomb_controller"] = "rbxassetid://110655698737039",
        ["bookshelf"] = "rbxassetid://10866360547",
        ["block_kicker_boot"] = "rbxassetid://106266680447247",
        ["wood_bow"] = "rbxassetid://139409570718751",
        ["glitch_wood_bow"] = "rbxassetid://139409570718751",
        ["brb_sign"] = "rbxassetid://120071201294405",
        ["break_speed_axolotl"] = "rbxassetid://123254211342076",
        ["brewing_cauldron"] = "rbxassetid://123764672919825",
        ["brick"] = "rbxassetid://7884366460",
        ["christmas_drawbridge"] = "rbxassetid://122137461128449",
        ["drawbridge"] = "rbxassetid://12210620616",
        ["wool_brown"] = "rbxassetid://15380238075",
        ["camera_turret"] = "rbxassetid://77843550094090",
        ["can_of_beans"] = "rbxassetid://130427790178330",
        ["candy"] = "rbxassetid://105430883276912",
        ["cannon"] = "rbxassetid://135326240029291",
        ["carrot"] = "rbxassetid://111397440769457",
        ["carrot_cannon"] = "rbxassetid://107941587459450",
        ["carrot_rocket"] = "rbxassetid://74867984893347",
        ["carrot_seeds"] = "rbxassetid://104713238051964",
        ["block_hunt_chameleon_fruit"] = "rbxassetid://88815580391661",
        ["charge_shield"] = "rbxassetid://95584579801811",
        ["glue_projectile_charging"] = "rbxassetid://138536701789324",
        ["cherry_foliage"] = "rbxassetid://119991865381459",
        ["chest"] = "rbxassetid://135461435695397",
        ["chicken_deploy"] = "rbxassetid://86455196029706",
        ["christmas_tree_deploy"] = "rbxassetid://79602341293150",
        ["clay"] = "rbxassetid://7884366829",
        ["invisible_cloak"] = "rbxassetid://75655964253309",
        ["cluster_bomb"] = "rbxassetid://100301578336072",
        ["cobblestone"] = "rbxassetid://8296848529",
        ["block_hunt_coin"] = "rbxassetid://107605980212027",
        ["lasso_coin"] = "rbxassetid://107605980212027",
        ["egg_block"] = "rbxassetid://111397440769457",
        ["condiment_gun"] = "rbxassetid://80747114101031",
        ["styx_entrance_portal"] = "rbxassetid://110216934571562",
        ["styx_exit_portal"] = "rbxassetid://110216934571562",
        ["orions_belt_bow"] = "rbxassetid://117813714444662",
        ["pit"] = "rbxassetid://99882043795273",
        ["copper_block"] = "rbxassetid://10859696115",
        ["fisherman_coral"] = "rbxassetid://7884369108",
        ["cosmic_lucky_block"] = "rbxassetid://11773163557",
        ["cotton_candy_block"] = "rbxassetid://137081393212041",
        ["crit_star"] = "rbxassetid://130023071819508",
        ["critical_strike_3_enchant"] = "rbxassetid://119853949957472",
        ["og_wood_crossbow"] = "rbxassetid://97978571652985",
        ["wood_crossbow"] = "rbxassetid://97978571652985",
        ["crystalheart_seed"] = "rbxassetid://96864852014082",
        ["cursed_coffin"] = "rbxassetid://101441576294469",
        ["wool_cyan"] = "rbxassetid://7923577311",
        ["damage_axolotl"] = "rbxassetid://140604472464159",
        ["damage_orb_diamond"] = "rbxassetid://120197087302995",
        ["damage_orb_emerald"] = "rbxassetid://109449888728007",
        ["clay_dark_brown"] = "rbxassetid://7884367299",
        ["clay_dark_green"] = "rbxassetid://7884367424",
        ["mythic_dagger"] = "rbxassetid://127553885878753",
        ["defense_banner"] = "rbxassetid://122580083750401",
        ["defense_scanner"] = "rbxassetid://136491808605509",
        ["diamond"] = "rbxassetid://90279082670934",
        ["diamond_axe"] = "rbxassetid://71269390215752",
        ["diamond_block"] = "rbxassetid://7884368860",
        ["diamond_boots"] = "rbxassetid://139656467450408",
        ["tinker_weapon_3"] = "rbxassetid://83806651911702",
        ["ninja_chakram_3"] = "rbxassetid://120124780552282",
        ["diamond_chestplate"] = "rbxassetid://121914389575985",
        ["chicken_diamond"] = "rbxassetid://110813912339908",
        ["diamond_gun_blade"] = "rbxassetid://111405832299999",
        ["diamond_dagger"] = "rbxassetid://97121835987894",
        ["diamond_dao"] = "rbxassetid://106471517840546",
        ["target_dummy_block_tier_2"] = "rbxassetid://75043926242046",
        ["diamond_gauntlets"] = "rbxassetid://118043571816291",
        ["diamond_great_hammer"] = "rbxassetid://113295560886652",
        ["diamond_helmet"] = "rbxassetid://135699099448203",
        ["tinker_machine_upgrade_2"] = "rbxassetid://127645741574930",
        ["diamond_chicken_nest"] = "rbxassetid://99257937347803",
        ["diamond_ore"] = "rbxassetid://105644572237110",
        ["diamond_pickaxe"] = "rbxassetid://133404109234843",
        ["diamond_scythe"] = "rbxassetid://99736300642057",
        ["diamond_sword"] = "rbxassetid://101367062745506",
        ["og_diamond_sword"] = "rbxassetid://101367062745506",
        ["gather_bot_basic"] = "rbxassetid://95795219989835",
        ["dino_deploy"] = "rbxassetid://126595466805411",
        ["diorite"] = "rbxassetid://9072525407",
        ["dirt"] = "rbxassetid://7884368936",
        ["disco_grenade"] = "rbxassetid://96957464364252",
        ["dizzy_toad"] = "rbxassetid://119064085460149",
        ["double_edge_sword"] = "rbxassetid://86205038598534",
        ["double_rainbow_boots"] = "rbxassetid://106001840473383",
        ["dragon_mortar"] = "rbxassetid://130455836587798",
        ["lobby_dragon_mortar"] = "rbxassetid://130455836587798",
        ["drill"] = "rbxassetid://135487072358151",
        ["drone"] = "rbxassetid://129187182106342",
        ["duck_spawn_egg"] = "rbxassetid://140375762236027",
        ["duct_tape"] = "rbxassetid://121562363741866",
        ["chicken_egg"] = "rbxassetid://75744349771872",
        ["chicken_egg_block"] = "rbxassetid://111397440769457",
        ["chicken_shop_item"] = "rbxassetid://87935013539908",
        ["easter_egg_projectile"] = "rbxassetid://128540987418521",
        ["throwable_egg"] = "rbxassetid://75744349771872",
        ["egg_launcher"] = "rbxassetid://127775096115930",
        ["elektra_crown"] = "rbxassetid://88324446283383",
        ["fire_3_enchant"] = "rbxassetid://131081704940563",
        ["static_3_enchant"] = "rbxassetid://106186066044281",
        ["ember"] = "rbxassetid://93811493297433",
        ["emerald"] = "rbxassetid://123894017644964",
        ["emerald_block"] = "rbxassetid://7884369019",
        ["emerald_boots"] = "rbxassetid://82496949681938",
        ["tinker_weapon_4"] = "rbxassetid://83877672291745",
        ["ninja_chakram_4"] = "rbxassetid://139663549040622",
        ["emerald_chestplate"] = "rbxassetid://119376292287483",
        ["chicken_emerald"] = "rbxassetid://112125500428017",
        ["emerald_gun_blade"] = "rbxassetid://98765959201778",
        ["emerald_dao"] = "rbxassetid://132011444448681",
        ["target_dummy_block_tier_3"] = "rbxassetid://101240038604060",
        ["emerald_helmet"] = "rbxassetid://85842840607138",
        ["tinker_machine_upgrade_3"] = "rbxassetid://138812517230201",
        ["emerald_chicken_nest"] = "rbxassetid://129929772646240",
        ["emerald_ore"] = "rbxassetid://102665467637199",
        ["emerald_sword"] = "rbxassetid://134195843073517",
        ["og_emerald_sword"] = "rbxassetid://134195843073517",
        ["gather_bot_pro"] = "rbxassetid://96983212157323",
        ["empty_balloon"] = "rbxassetid://108461673781145",
        ["enchant_table"] = "rbxassetid://105645779003606",
        ["summer_2025_treasure_map"] = "rbxassetid://123997251018873",
        ["target_dummy_block_tier_4"] = "rbxassetid://138026083286690",
        ["tennis_ball"] = "rbxassetid://75126305150575",
        ["ballista_ammo"] = "rbxassetid://112983246140382",
        ["exploding_tank_block"] = "rbxassetid://91829628931173",
        ["explosive_trap"] = "rbxassetid://129356731343612",
        ["fake_bed"] = "rbxassetid://101947571739657",
        ["whisper_feather"] = "rbxassetid://120916280736873",
        ["feather_bow"] = "rbxassetid://139409570718751",
        ["falconer_bow"] = "rbxassetid://106413498387102",
        ["falconer_crossbow"] = "rbxassetid://72119022499359",
        ["falconer_headhunter"] = "rbxassetid://124384287846514",
        ["fir_log"] = "rbxassetid://127344168815649",
        ["wood_plank_fir"] = "rbxassetid://85263602081760",
        ["damage_banner"] = "rbxassetid://109666297470184",
        ["fire_match"] = "rbxassetid://109880647883132",
        ["fire_sheep_statue"] = "rbxassetid://89571045512925",
        ["fireball"] = "rbxassetid://85052492775619",
        ["firecrackers"] = "rbxassetid://90104662998163",
        ["firework_arrow"] = "rbxassetid://89011091687489",
        ["firework_backpack"] = "rbxassetid://118437817405798",
        ["party_cannon"] = "rbxassetid://139498262337809",
        ["firework_crate"] = "rbxassetid://112153898310296",
        ["firework_rocket_missile"] = "rbxassetid://103732118922226",
        ["firework_rocket_launcher"] = "rbxassetid://130207444098700",
        ["healing_backpack"] = "rbxassetid://103103218060225",
        ["fish_bait"] = "rbxassetid://135712447710706",
        ["fish_coin"] = "rbxassetid://90236075595844",
        ["fishing_rod"] = "rbxassetid://76640442270774",
        ["ice_fishing_rod"] = "rbxassetid://76640442270774",
        ["flamethrower"] = "rbxassetid://73096193408218",
        ["flower_bow"] = "rbxassetid://126819790764368",
        ["flower_crossbow"] = "rbxassetid://77892208520702",
        ["flower_headhunter"] = "rbxassetid://128783592980737",
        ["wild_flower"] = "rbxassetid://117594219966581",
        ["flying_backpack"] = "rbxassetid://95828099019282",
        ["flying_broom_deploy"] = "rbxassetid://135828110019165",
        ["flying_carpet_deploy"] = "rbxassetid://82660136985710",
        ["flying_cloud_deploy"] = "rbxassetid://115827989778868",
        ["flying_lucky_block"] = "rbxassetid://93692444062260",
        ["food_lucky_block"] = "rbxassetid://14192272584",
        ["forcefield_potion"] = "rbxassetid://80237036105456",
        ["forge_lucky_block"] = "rbxassetid://15644713419",
        ["fork_trident"] = "rbxassetid://113333617555822",
        ["lightning_coil"] = "rbxassetid://134824847347667",
        ["frost_crystal"] = "rbxassetid://74677159502025",
        ["frost_staff_1"] = "rbxassetid://116757270353579",
        ["frost_staff_2"] = "rbxassetid://74744544167644",
        ["frost_staff_3"] = "rbxassetid://112502037535553",
        ["frosted_snowball"] = "rbxassetid://129133740394025",
        ["frosty_hammer"] = "rbxassetid://135585138854088",
        ["frosty_slime"] = "rbxassetid://117634994585775",
        ["frozen_foliage"] = "rbxassetid://110464988932383",
        ["frozen_fortress"] = "rbxassetid://127624453538263",
        ["frying_pan"] = "rbxassetid://75132544207665",
        ["fury_potion"] = "rbxassetid://139086377195071",
        ["galactite"] = "rbxassetid://15966082316",
        ["galactite_brick"] = "rbxassetid://9839888714",
        ["big_gargoyle_statue"] = "rbxassetid://135058431639633",
        ["gargoyle_statue"] = "rbxassetid://135058431639633",
        ["cutlass_ghost"] = "rbxassetid://127743620308728",
        ["ghost_orb"] = "rbxassetid://138771827434648",
        ["gargoyle_statue_breaker"] = "rbxassetid://98249072997486",
        ["giant_needle"] = "rbxassetid://81285764047495",
        ["giant_potion"] = "rbxassetid://82960605238497",
        ["lobby_snowboard_special"] = "rbxassetid://135619015313501",
        ["glass"] = "rbxassetid://88312165485888",
        ["glitched_lucky_block"] = "rbxassetid://10866119664",
        ["global_generator_gadget"] = "rbxassetid://86437182247013",
        ["glue_projectile"] = "rbxassetid://87298101362359",
        ["glowstone"] = "rbxassetid://12948863407",
        ["glue_trap"] = "rbxassetid://85052492775619",
        ["glue_trap_charging"] = "rbxassetid://85052492775619",
        ["gold"] = "rbxassetid://83780887210500",
        ["gold_block"] = "rbxassetid://13465465532",
        ["golden_apple"] = "rbxassetid://105548207289958",
        ["golden_bow"] = "rbxassetid://75695501699645",
        ["granite"] = "rbxassetid://9072553261",
        ["grappling_hook"] = "rbxassetid://74687946872039",
        ["grass"] = "rbxassetid://7911370722",
        ["grave_trap"] = "rbxassetid://121548696467641",
        ["gravel"] = "rbxassetid://93260299784521",
        ["clay_gray"] = "rbxassetid://7884367563",
        ["wool_gray"] = "rbxassetid://133598038392600",
        ["clay_green"] = "rbxassetid://7884367698",
        ["concrete_green"] = "rbxassetid://8537949134",
        ["wool_green"] = "rbxassetid://7923577655",
        ["reaper_scythe"] = "rbxassetid://138988433260712",
        ["grimoire"] = "rbxassetid://130793550200698",
        ["knight_shield"] = "rbxassetid://93333609869346",
        ["guided_missile"] = "rbxassetid://93810120252155",
        ["guilded_iron"] = "rbxassetid://10859696266",
        ["guitar"] = "rbxassetid://86422533705333",
        ["super_guitar"] = "rbxassetid://86422533705333",
        ["glitch_guitar"] = "rbxassetid://79666958779944",
        ["gumball_launcher"] = "rbxassetid://113393452967714",
        ["gumdrop_bounce_pad"] = "rbxassetid://86970935775041",
        ["pirate_gunpowder_barrel"] = "rbxassetid://124163528088485",
        ["hair_dryer"] = "rbxassetid://103148802064864",
        ["halloween_lucky_block"] = "rbxassetid://123082675687201",
        ["hammer"] = "rbxassetid://119311556571247",
        ["multi_break_tool"] = "rbxassetid://99547811785332",
        ["hang_glider"] = "rbxassetid://128689759457968",
        ["party_hat_missile"] = "rbxassetid://137111569651054",
        ["haybale"] = "rbxassetid://14968393791",
        ["headhunter"] = "rbxassetid://131191562477991",
        ["heal_banner"] = "rbxassetid://115128771630900",
        ["heal_splash_potion"] = "rbxassetid://81094672227737",
        ["healing_turret"] = "rbxassetid://115128771630900",
        ["apple"] = "rbxassetid://85613757413443",
        ["orange"] = "rbxassetid://76519026223109",
        ["health_regen_axolotl"] = "rbxassetid://80598292067326",
        ["berserker_3_enchant"] = "rbxassetid://82560255878171",
        ["heat_seeking_rock"] = "rbxassetid://130728439164241",
        ["hero_comet_volley"] = "rbxassetid://135641744601183",
        ["hero_magical_girl_rapier"] = "rbxassetid://76793493393235",
        ["hero_magical_girl_scepter"] = "rbxassetid://81032092126347",
        ["hero_protector_wand"] = "rbxassetid://90098157959992",
        ["hero_scissor_sword"] = "rbxassetid://124192295459172",
        ["hickory_log"] = "rbxassetid://7884369330",
        ["wood_plank_hickory"] = "rbxassetid://7884372677",
        ["scarab_spawner"] = "rbxassetid://134971293303883",
        ["hive_upgrade_1"] = "rbxassetid://134971293303883",
        ["hive_upgrade_2"] = "rbxassetid://71541277528457",
        ["hive_upgrade_3"] = "rbxassetid://119008419693345",
        ["hot_air_balloon_deploy"] = "rbxassetid://105018602939174",
        ["hot_chocolate"] = "rbxassetid://133203988180156",
        ["hot_potato"] = "rbxassetid://95150255811129",
        ["hotdog_bat"] = "rbxassetid://118439495051289",
        ["lobby_vip_hoverboard"] = "rbxassetid://113648508119059",
        ["hunters_echo"] = "rbxassetid://83381181872507",
        ["ice"] = "rbxassetid://7884369431",
        ["ice_bricks"] = "rbxassetid://114386325782703",
        ["ice_sword"] = "rbxassetid://126648406613207",
        ["impulse_grenade"] = "rbxassetid://100275726042319",
        ["impulse_gun"] = "rbxassetid://91450376145490",
        ["infernal_saber"] = "rbxassetid://125577105999899",
        ["infernal_shield"] = "rbxassetid://106378954113798",
        ["glitch_infernal_shield"] = "rbxassetid://106378954113798",
        ["invisible_landmine"] = "rbxassetid://125127086299401",
        ["invisibility_potion"] = "rbxassetid://89826029859930",
        ["iron"] = "rbxassetid://85277145435796",
        ["iron_arrow"] = "rbxassetid://74847998276505",
        ["iron_axe"] = "rbxassetid://73341874003559",
        ["iron_block"] = "rbxassetid://7884369517",
        ["iron_boots"] = "rbxassetid://106266680447247",
        ["tinker_weapon_2"] = "rbxassetid://109767200186643",
        ["ninja_chakram_2"] = "rbxassetid://83311033042988",
        ["iron_chestplate"] = "rbxassetid://134111794629739",
        ["chicken_iron"] = "rbxassetid://95545733357923",
        ["iron_gun_blade"] = "rbxassetid://116964739443319",
        ["iron_dagger"] = "rbxassetid://104072473909410",
        ["iron_dao"] = "rbxassetid://113272571588218",
        ["target_dummy_block_tier_1"] = "rbxassetid://95634870785506",
        ["iron_gauntlets"] = "rbxassetid://118180936904347",
        ["iron_great_hammer"] = "rbxassetid://70793408322144",
        ["iron_helmet"] = "rbxassetid://114032128714513",
        ["tinker_machine_upgrade_1"] = "rbxassetid://73329741184038",
        ["iron_chicken_nest"] = "rbxassetid://120588472014631",
        ["iron_ore"] = "rbxassetid://88425197437530",
        ["diamond_pickaxe_sword"] = "rbxassetid://137285418790349",
        ["iron_pickaxe"] = "rbxassetid://137285418790349",
        ["iron_pickaxe_sword"] = "rbxassetid://137285418790349",
        ["iron_scythe"] = "rbxassetid://71112235955694",
        ["iron_sword"] = "rbxassetid://105003818556151",
        ["pumpkin_bomb_1"] = "rbxassetid://94827632882746",
        ["pumpkin_bomb_3"] = "rbxassetid://94827632882746",
        ["pumpkin_bomb_2"] = "rbxassetid://94827632882746",
        ["jade_hammer_1"] = "rbxassetid://82322794810366",
        ["jade_hammer_2"] = "rbxassetid://82322794810366",
        ["jade_hammer_3"] = "rbxassetid://82322794810366",
        ["jellyfish"] = "rbxassetid://104055217446019",
        ["jellyfish_mount_deploy"] = "rbxassetid://75717963450426",
        ["juggernaut_rage_blade"] = "rbxassetid://82979531402833",
        ["juggernaut_boots"] = "rbxassetid://116144140974461",
        ["juggernaut_chestplate"] = "rbxassetid://136795466621219",
        ["juggernaut_helmet"] = "rbxassetid://130050219975860",
        ["jump_boots"] = "rbxassetid://81301685115333",
        ["jump_pad"] = "rbxassetid://97632140604062",
        ["jump_potion"] = "rbxassetid://114711740012001",
        ["lobby_kaida_claw"] = "rbxassetid://72325138714304",
        ["baguette"] = "rbxassetid://138232461103199",
        ["knockback_fish"] = "rbxassetid://109428639130644",
        ["kobblak"] = "rbxassetid://9859002988",
        ["ladder"] = "rbxassetid://139163685599216",
        ["lantern_block"] = "rbxassetid://12948863466",
        ["large_rock"] = "rbxassetid://130728439164241",
        ["laser_pickaxe"] = "rbxassetid://120258214488389",
        ["laser_sword"] = "rbxassetid://107550227106693",
        ["lasso"] = "rbxassetid://99832904513577",
        ["lasso_hook"] = "rbxassetid://110216934571562",
        ["leather_boots"] = "rbxassetid://80015141025247",
        ["leather_chestplate"] = "rbxassetid://138751265673270",
        ["chicken_leather"] = "rbxassetid://81460535828221",
        ["leather_helmet"] = "rbxassetid://129974147461663",
        ["life_bow"] = "rbxassetid://133394230534666",
        ["life_crossbow"] = "rbxassetid://115392845075587",
        ["life_headhunter"] = "rbxassetid://107434411816457",
        ["clay_light_brown"] = "rbxassetid://7884367792",
        ["clay_light_green"] = "rbxassetid://7884367872",
        ["light_sword"] = "rbxassetid://137669329677649",
        ["love_chair_deploy"] = "rbxassetid://131398006618266",
        ["lucky_block"] = "rbxassetid://7884369916",
        ["lucky_block_trap"] = "rbxassetid://7884370012",
        ["lucky_snow_cone"] = "rbxassetid://137663826324414",
        ["mage_spellbook"] = "rbxassetid://139876790422567",
        ["magic_glass"] = "rbxassetid://72863067929207",
        ["wizard_stick"] = "rbxassetid://93053182930152",
        ["magical_hero_lucky_block"] = "rbxassetid://16114559103",
        ["magma_block"] = "rbxassetid://9439108582",
        ["manual_cannon"] = "rbxassetid://124005184244307",
        ["repair_tool"] = "rbxassetid://70589943177754",
        ["maple_log"] = "rbxassetid://86234279548775",
        ["wood_plank_maple"] = "rbxassetid://7884372787",
        ["marble"] = "rbxassetid://81009550642851",
        ["marble_pillar"] = "rbxassetid://7884370206",
        ["mass_hammer"] = "rbxassetid://91891752231057",
        ["fishing_rod_3"] = "rbxassetid://76640442270774",
        ["melon"] = "rbxassetid://113751766818190",
        ["melon_seeds"] = "rbxassetid://130798688328433",
        ["mending_canopy_staff_tier_1"] = "rbxassetid://129080354225778",
        ["mending_canopy_staff_tier_2"] = "rbxassetid://102495840592528",
        ["mending_canopy_staff_tier_3"] = "rbxassetid://93472376920473",
        ["metal_detector"] = "rbxassetid://138658309450780",
        ["meteor_caller"] = "rbxassetid://105860104301448",
        ["meteor_shower"] = "rbxassetid://131419604577210",
        ["mini_shield"] = "rbxassetid://99722688865346",
        ["helicopter_deploy"] = "rbxassetid://112675271517895",
        ["rainbow_staff"] = "rbxassetid://137074746877185",
        ["moss_block"] = "rbxassetid://10866497548",
        ["murderer_dagger"] = "rbxassetid://83443658461823",
        ["mushrooms"] = "rbxassetid://135320969205976",
        ["mysterious_box"] = "rbxassetid://70687709005712",
        ["crystal_ore"] = "rbxassetid://93218737444694",
        ["natures_essence_1"] = "rbxassetid://75126521685623",
        ["natures_essence_2"] = "rbxassetid://75126521685623",
        ["natures_essence_3"] = "rbxassetid://75126521685623",
        ["natures_essence_4"] = "rbxassetid://75126521685623",
        ["necromancer_staff"] = "rbxassetid://117158086070534",
        ["new_years_lucky_block"] = "rbxassetid://11958841642",
        ["new_years_lucky_block_2024"] = "rbxassetid://15800004718",
        ["noctium_blade"] = "rbxassetid://126085102480094",
        ["noctium_blade_2"] = "rbxassetid://79202016848823",
        ["noctium_blade_3"] = "rbxassetid://99769052993799",
        ["noctium_blade_4"] = "rbxassetid://86562741171214",
        ["mythic_scythe"] = "rbxassetid://125171567704192",
        ["fishing_rod_2"] = "rbxassetid://76640442270774",
        ["noxious_sledgehammer"] = "rbxassetid://125735019385752",
        ["oak_log"] = "rbxassetid://7884370279",
        ["wood_plank_oak"] = "rbxassetid://7884372987",
        ["wood_plank_oak_builder"] = "rbxassetid://134102210183901",
        ["oasis_vessel"] = "rbxassetid://108697635309796",
        ["oasis_vessel_2"] = "rbxassetid://125116832498062",
        ["oasis_vessel_3"] = "rbxassetid://82917267720454",
        ["obsidian"] = "rbxassetid://8105569883",
        ["oil_consumable"] = "rbxassetid://133429378271498",
        ["oil_spitter"] = "rbxassetid://133429378271498",
        ["clay_orange"] = "rbxassetid://7884367973",
        ["cotton_candy_block_orange"] = "rbxassetid://92719916547197",
        ["wool_orange"] = "rbxassetid://7923578297",
        ["orbital_satellite_tablet"] = "rbxassetid://80822386776498",
        ["owl_orb"] = "rbxassetid://132143358189103",
        ["owl_shooter"] = "rbxassetid://122559743121181",
        ["paint_shotgun"] = "rbxassetid://105765028274234",
        ["mythic_great_hammer"] = "rbxassetid://124670170678090",
        ["party_hat_launcher"] = "rbxassetid://86444507192468",
        ["party_popper"] = "rbxassetid://125996464909174",
        ["og_personal_chest"] = "rbxassetid://132426219930361",
        ["personal_chest"] = "rbxassetid://132426219930361",
        ["pillow"] = "rbxassetid://134600555509987",
        ["clay_pink"] = "rbxassetid://7884368035",
        ["cotton_candy_block_pink"] = "rbxassetid://118070096462961",
        ["wool_pink"] = "rbxassetid://7923578533",
        ["pirate_flag"] = "rbxassetid://124126848851145",
        ["pirate_shovel"] = "rbxassetid://94601688612411",
        ["pirate_sword_fp"] = "rbxassetid://121398163630795",
        ["pirate_telescope"] = "rbxassetid://136144096012203",
        ["pinata"] = "rbxassetid://118444198364940",
        ["lobby_pogo_stick"] = "rbxassetid://110843250877089",
        ["pogo_stick"] = "rbxassetid://110843250877089",
        ["poison_splash_potion"] = "rbxassetid://86288168798739",
        ["andesite_polished"] = "rbxassetid://9072552793",
        ["diorite_polished"] = "rbxassetid://9072553104",
        ["granite_polished"] = "rbxassetid://9072553350",
        ["popup_cube"] = "rbxassetid://93888254391865",
        ["glitch_popup_cube"] = "rbxassetid://93888254391865",
        ["throwable_bridge"] = "rbxassetid://79161100869381",
        ["glitch_throwable_bridge"] = "rbxassetid://79161100869381",
        ["portable_vending_machine"] = "rbxassetid://84394024042678",
        ["portal_gun"] = "rbxassetid://100334952518351",
        ["rainbow_backpack"] = "rbxassetid://78795288727700",
        ["pumpkin"] = "rbxassetid://94827632882746",
        ["pumpkin_block"] = "rbxassetid://14968393998",
        ["pumpkin_seeds"] = "rbxassetid://76755606247993",
        ["lobby_spring_punch"] = "rbxassetid://113171596613504",
        ["spring_punch"] = "rbxassetid://113171596613504",
        ["clay_purple"] = "rbxassetid://7884368099",
        ["purple_hay_bale"] = "rbxassetid://128316458101834",
        ["purple_lucky_block"] = "rbxassetid://8105570365",
        ["wool_purple"] = "rbxassetid://7923578762",
        ["rainbow_axe"] = "rbxassetid://134598914899742",
        ["radioactive_plant"] = "rbxassetid://130931233324806",
        ["rageblade"] = "rbxassetid://82979531402833",
        ["rainbow_key"] = "rbxassetid://114492425273086",
        ["rainbow_lucky_block"] = "rbxassetid://12813794908",
        ["raven"] = "rbxassetid://131441701795869",
        ["clay_red"] = "rbxassetid://7884368246",
        ["red_sand"] = "rbxassetid://9072732616",
        ["red_sandstone"] = "rbxassetid://7884370687",
        ["red_sandstone_polished"] = "rbxassetid://10859696978",
        ["red_sandstone_smooth"] = "rbxassetid://10859697143",
        ["wool_red"] = "rbxassetid://7923579098",
        ["gargoyle_statue_fighter"] = "rbxassetid://135058431639633",
        ["c4_bomb"] = "rbxassetid://97517871409671",
        ["block_repair_tool"] = "rbxassetid://76368180599768",
        ["black_market_reroll_items"] = "rbxassetid://104231857217312",
        ["robbery_ball"] = "rbxassetid://95801711432119",
        ["glitch_robbery_ball"] = "rbxassetid://95801711432119",
        ["rocket_launcher_missile"] = "rbxassetid://83675955758157",
        ["rocket_belt"] = "rbxassetid://72117343747315",
        ["grenade_launcher"] = "rbxassetid://79316157266077",
        ["rocket_launcher"] = "rbxassetid://113585890490440",
        ["glitch_grenade_launcher"] = "rbxassetid://79316157266077",
        ["ruby_leaves"] = "rbxassetid://118082086238360",
        ["fisherman_scythe"] = "rbxassetid://125171567704192",
        ["sacrophagus"] = "rbxassetid://137178680209992",
        ["sand"] = "rbxassetid://7884370902",
        ["sandstone"] = "rbxassetid://7884371048",
        ["sandstone_polished"] = "rbxassetid://10859697278",
        ["sandstone_smooth"] = "rbxassetid://10859697439",
        ["santa_bomb_siege"] = "rbxassetid://82967593230707",
        ["santa_bomb"] = "rbxassetid://82967593230707",
        ["satellite_dish"] = "rbxassetid://111989409772405",
        ["zenith_satellite_upgrade_2"] = "rbxassetid://129568480506250",
        ["zenith_satellite_upgrade_3"] = "rbxassetid://100499411062026",
        ["christmas_scaffold"] = "rbxassetid://116346363779293",
        ["scaffold"] = "rbxassetid://12210853999",
        ["scarab_upgrade_1"] = "rbxassetid://73724698350224",
        ["scarab_upgrade_2"] = "rbxassetid://116389672049107",
        ["scarab_upgrade_3"] = "rbxassetid://116389672049107",
        ["scepter"] = "rbxassetid://122559743121181",
        ["scythe"] = "rbxassetid://126664078449281",
        ["serpents_touch_potion"] = "rbxassetid://121585940885682",
        ["shadow_coin"] = "rbxassetid://73407257007722",
        ["shears"] = "rbxassetid://136099134489148",
        ["wool_shear"] = "rbxassetid://136099134489148",
        ["sheriff_crossbow"] = "rbxassetid://129494428450048",
        ["shield_axolotl"] = "rbxassetid://82146225138887",
        ["classic_shock_wave_turret"] = "rbxassetid://127125059257916",
        ["lobby_shrink_potion"] = "rbxassetid://115999424942960",
        ["shrink_potion"] = "rbxassetid://115999424942960",
        ["siege_tnt"] = "rbxassetid://14719641593",
        ["sand_spear"] = "rbxassetid://105149131569856",
        ["headhunt_skull"] = "rbxassetid://124040322194445",
        ["sky_scythe"] = "rbxassetid://111046677074896",
        ["slate_brick"] = "rbxassetid://9072553631",
        ["slate_tiles"] = "rbxassetid://10859697544",
        ["sleep_splash_potion"] = "rbxassetid://113088236355285",
        ["sleigh_deploy"] = "rbxassetid://92226606166335",
        ["slime_water_balloon"] = "rbxassetid://128533363545740",
        ["slime_block"] = "rbxassetid://86970935775041",
        ["slime_tamer_flute"] = "rbxassetid://136103636775209",
        ["gargoyle_statue_swift"] = "rbxassetid://103178345965669",
        ["lucky_block_item_smelter"] = "rbxassetid://135461435695397",
        ["smoke_block"] = "rbxassetid://8538034673",
        ["smoke_bomb"] = "rbxassetid://79434155503694",
        ["smoke_grenade"] = "rbxassetid://76855363035896",
        ["snap_trap"] = "rbxassetid://125276025218190",
        ["snow"] = "rbxassetid://107720871596554",
        ["snow_cone"] = "rbxassetid://100924466774690",
        ["snowball"] = "rbxassetid://129133740394025",
        ["snowball_launcher"] = "rbxassetid://118192758065762",
        ["glitch_snowball"] = "rbxassetid://129133740394025",
        ["lobby_snowboard"] = "rbxassetid://81795165774436",
        ["fisherman_warfist"] = "rbxassetid://99870257527995",
        ["fisherman_dagger"] = "rbxassetid://127553885878753",
        ["solar_panel"] = "rbxassetid://84151561047964",
        ["soulvine_flower"] = "rbxassetid://118934142860506",
        ["soulvine_seed"] = "rbxassetid://81471288650573",
        ["sparkler"] = "rbxassetid://88172356461376",
        ["sparkling_apple_juice"] = "rbxassetid://118650467510603",
        ["guards_spear"] = "rbxassetid://120916280736873",
        ["spear"] = "rbxassetid://87158548186264",
        ["rainbow_arrow"] = "rbxassetid://89161259074550",
        ["rainbow_bow"] = "rbxassetid://95533056064815",
        ["speed_boots"] = "rbxassetid://114494926419333",
        ["pie"] = "rbxassetid://91316020153198",
        ["speed_potion"] = "rbxassetid://84756147306261",
        ["spider_queen_web"] = "rbxassetid://93363675113975",
        ["spider_web"] = "rbxassetid://93363675113975",
        ["spike_shell_backpack"] = "rbxassetid://73284804565177",
        ["spike_trap"] = "rbxassetid://138284860812640",
        ["spirit"] = "rbxassetid://119691327416044",
        ["spirit_bridge"] = "rbxassetid://126959387058671",
        ["spirit_dagger"] = "rbxassetid://126307732354499",
        ["spirit_dagger_left"] = "rbxassetid://77272345986931",
        ["spirit_foliage"] = "rbxassetid://133699022252191",
        ["spirit_grass"] = "rbxassetid://102285628641008",
        ["spirit_staff"] = "rbxassetid://84621285877425",
        ["spirit_tier_1"] = "rbxassetid://73187487860598",
        ["spirit_tier_2"] = "rbxassetid://107613423599962",
        ["spirit_tier_3"] = "rbxassetid://74302383792676",
        ["spread_cannon"] = "rbxassetid://112428126201281",
        ["spruce_log"] = "rbxassetid://7884371618",
        ["wood_plank_spruce"] = "rbxassetid://7884373190",
        ["star"] = "rbxassetid://137832186591101",
        ["steel_block"] = "rbxassetid://10859697667",
        ["sticky_firework"] = "rbxassetid://89462122304141",
        ["sticky_slime"] = "rbxassetid://89554143108009",
        ["stone"] = "rbxassetid://7884371892",
        ["stone_axe"] = "rbxassetid://129536952959949",
        ["stone_brick"] = "rbxassetid://7884372079",
        ["ninja_chakram_1"] = "rbxassetid://117395952066054",
        ["stone_gun_blade"] = "rbxassetid://135829148128089",
        ["stone_dagger"] = "rbxassetid://72755018730250",
        ["stone_dao"] = "rbxassetid://107261610502437",
        ["stone_gauntlets"] = "rbxassetid://106745754956909",
        ["stone_great_hammer"] = "rbxassetid://114477558184673",
        ["stone_pickaxe"] = "rbxassetid://101802070114855",
        ["stone_pillar"] = "rbxassetid://10859697750",
        ["stone_scythe"] = "rbxassetid://75821052229672",
        ["stone_slab"] = "rbxassetid://8105570787",
        ["stone_sword"] = "rbxassetid://137384330544130",
        ["stone_tiles"] = "rbxassetid://10859697942",
        ["stone_brick_builder"] = "rbxassetid://113450183729345",
        ["stopwatch"] = "rbxassetid://86470260107837",
        ["stun_grenade"] = "rbxassetid://94925221155986",
        ["glitch_stun_grenade"] = "rbxassetid://94925221155986",
        ["summon_stone"] = "rbxassetid://91299358884753",
        ["summoner_claw_1"] = "rbxassetid://95211068490269",
        ["summoner_claw_2"] = "rbxassetid://122760525561149",
        ["summoner_claw_3"] = "rbxassetid://117934006795669",
        ["summoner_claw_4"] = "rbxassetid://72325138714304",
        ["fisherman_great_hammer"] = "rbxassetid://124670170678090",
        ["surf_board"] = "rbxassetid://106378954113798",
        ["swap_ball"] = "rbxassetid://79991494629692",
        ["drill_controller"] = "rbxassetid://81394833868635",
        ["tablet"] = "rbxassetid://81394833868635",
        ["tactical_crossbow"] = "rbxassetid://129494428450048",
        ["glitch_tactical_crossbow"] = "rbxassetid://129494428450048",
        ["tactical_headhunter"] = "rbxassetid://92274120517569",
        ["clay_tan"] = "rbxassetid://7884368312",
        ["taser"] = "rbxassetid://80046638222315",
        ["glitch_taser"] = "rbxassetid://80046638222315",
        ["team_crate"] = "rbxassetid://78381007895304",
        ["team_door"] = "rbxassetid://124443861907956",
        ["team_generator_gadget"] = "rbxassetid://86437182247013",
        ["spawn_gadget"] = "rbxassetid://86437182247013",
        ["tearbloom_flower"] = "rbxassetid://113059409895300",
        ["tearbloom_seed"] = "rbxassetid://93399441043660",
        ["telepearl"] = "rbxassetid://112488474486174",
        ["teleport_block"] = "rbxassetid://137178680209992",
        ["void_teleport_portal"] = "rbxassetid://108860077266240",
        ["teleport_hat"] = "rbxassetid://138270809840166",
        ["teleporting_hatter"] = "rbxassetid://128316458101834",
        ["tennis_racket"] = "rbxassetid://122691219301146",
        ["tesla_trap"] = "rbxassetid://121548696467641",
        ["big_apple"] = "rbxassetid://131443058285283",
        ["thorns"] = "rbxassetid://93629351637705",
        ["murderer_throwing_knife"] = "rbxassetid://116330993181466",
        ["throwing_knife"] = "rbxassetid://116330993181466",
        ["time_bomb_potion"] = "rbxassetid://81030552230759",
        ["tinkers_wrench"] = "rbxassetid://70589943177754",
        ["tnt"] = "rbxassetid://7884372237",
        ["tornado_launcher"] = "rbxassetid://103148802064864",
        ["toy_hammer"] = "rbxassetid://138879529882561",
        ["treasure_chest"] = "rbxassetid://122650465307414",
        ["harpoon"] = "rbxassetid://103856081545636",
        ["trumpet"] = "rbxassetid://74295721577108",
        ["glitch_trumpet"] = "rbxassetid://74295721577108",
        ["tuff_bricks"] = "rbxassetid://113881385384669",
        ["turtle_backpack"] = "rbxassetid://110232236678920",
        ["turtle_shell"] = "rbxassetid://110232236678920",
        ["twirlblade"] = "rbxassetid://81943492884091",
        ["ufo_deploy"] = "rbxassetid://107012431692414",
        ["unstable_portal"] = "rbxassetid://131396595263559",
        ["player_vacuum"] = "rbxassetid://98920914226737",
        ["vacuum"] = "rbxassetid://105545163878028",
        ["venom_trap"] = "rbxassetid://79217908920130",
        ["villain_comet_volley"] = "rbxassetid://117183227584472",
        ["villain_magical_girl_rapier"] = "rbxassetid://131660740863192",
        ["villain_magical_girl_scepter"] = "rbxassetid://86593246239096",
        ["villain_protector_wand"] = "rbxassetid://119228162357339",
        ["villain_scissor_sword"] = "rbxassetid://124786782952738",
        ["vine_ladder"] = "rbxassetid://87238489934672",
        ["vitality_star"] = "rbxassetid://91237675247449",
        ["void_axe"] = "rbxassetid://112051843235212",
        ["void_boots"] = "rbxassetid://109279353739216",
        ["tinker_weapon_5"] = "rbxassetid://135100621899304",
        ["void_chestplate"] = "rbxassetid://135856544548622",
        ["chicken_void"] = "rbxassetid://70579216807770",
        ["void_crystal"] = "rbxassetid://93218737444694",
        ["void_helmet"] = "rbxassetid://85323601353329",
        ["tinker_machine_upgrade_4"] = "rbxassetid://140138171839571",
        ["void_chicken_incubator"] = "rbxassetid://116072311184406",
        ["void_block"] = "rbxassetid://9871961934",
        ["void_slime"] = "rbxassetid://117919846575561",
        ["void_sword"] = "rbxassetid://104039291998086",
        ["glitch_void_sword"] = "rbxassetid://104039291998086",
        ["void_turret"] = "rbxassetid://79573400706121",
        ["void_turret_tablet"] = "rbxassetid://126453387562530",
        ["volatile_stone"] = "rbxassetid://15380237898",
        ["volley_arrow"] = "rbxassetid://89605203077600",
        ["mythic_gauntlets_plain"] = "rbxassetid://99870257527995",
        ["mythic_gauntlets"] = "rbxassetid://99870257527995",
        ["warlock_staff"] = "rbxassetid://132768206097901",
        ["warrior_boots"] = "rbxassetid://133410921677510",
        ["warrior_chestplate"] = "rbxassetid://113459313915296",
        ["warrior_helmet"] = "rbxassetid://94441132405234",
        ["frost_water_balloon"] = "rbxassetid://135620245444551",
        ["water_balloon"] = "rbxassetid://108047608278699",
        ["aqua_gun"] = "rbxassetid://138325974068511",
        ["water_gun"] = "rbxassetid://138325974068511",
        ["water_spray_gun"] = "rbxassetid://122767633125527",
        ["water_backpack"] = "rbxassetid://97176419716318",
        ["watering_can"] = "rbxassetid://78619093690553",
        ["watermelon"] = "rbxassetid://109279107720947",
        ["big_web_launcher"] = "rbxassetid://82161330753637",
        ["web_launcher"] = "rbxassetid://82161330753637",
        ["clay_white"] = "rbxassetid://7884368439",
        ["wool_white"] = "rbxassetid://7923579263",
        ["wilted_foliage"] = "rbxassetid://104475814145570",
        ["wizard_staff"] = "rbxassetid://80207012471141",
        ["wizard_staff_2"] = "rbxassetid://93132409113840",
        ["wizard_staff_3"] = "rbxassetid://81848452375128",
        ["wood_axe"] = "rbxassetid://82292588711349",
        ["tinker_weapon_1"] = "rbxassetid://107342299538366",
        ["wood_gun_blade"] = "rbxassetid://121715767465157",
        ["wood_dagger"] = "rbxassetid://78543136832946",
        ["wood_dao"] = "rbxassetid://78856778199428",
        ["wood_gauntlets"] = "rbxassetid://102975506535452",
        ["wood_great_hammer"] = "rbxassetid://121555878097227",
        ["wood_pickaxe"] = "rbxassetid://96618959371995",
        ["wood_scythe"] = "rbxassetid://83564894302005",
        ["wood_sword"] = "rbxassetid://77272345986931",
        ["glitch_wood_sword"] = "rbxassetid://77272345986931",
        ["wool_builder"] = "rbxassetid://98916734642331",
        ["world_edit_wand"] = "rbxassetid://102940180213288",
        ["world_guard_wand"] = "rbxassetid://96213170073121",
        ["wormhole"] = "rbxassetid://96271517429474",
        ["clay_yellow"] = "rbxassetid://7884368673",
        ["cotton_candy_block_yellow"] = "rbxassetid://72099047987711",
        ["wool_yellow"] = "rbxassetid://7923579520",
        ["zipline_base"] = "rbxassetid://111542963204966",
        ["zipline"] = "rbxassetid://111542963204966",
    },
    Kits = {
        ["black_market_trader"] = "rbxassetid://110711746839834",
        ["nyoka"] = "rbxassetid://90570608969997",
        ["ice_queen"] = "rbxassetid://128785234110268",
        ["yeti"] = "rbxassetid://78559235598153",
        ["infected"] = "rbxassetid://95932519784040",
        ["winter_lady"] = "rbxassetid://97552416231580",
        ["rebellion_leader"] = "rbxassetid://127854239649111",
        ["void_dragon"] = "rbxassetid://140545337323065",
        ["santa"] = "rbxassetid://136914284439892",
        ["barbarian"] = "rbxassetid://110555271243914",
        ["card"] = "rbxassetid://92857681906290",
        ["raven"] = "rbxassetid://96079780356520",
        ["spirit_assassin"] = "rbxassetid://77231542794846",
        ["spirit_summoner"] = "rbxassetid://78725232846270",
        ["metal_detector"] = "rbxassetid://76329375067038",
        ["builder"] = "rbxassetid://102387747689079",
        ["midnight"] = "rbxassetid://76358749393356",
        ["infected_disruptor"] = "rbxassetid://95932519784040",
        ["merchant"] = "rbxassetid://81957923263166",
        ["bigman"] = "rbxassetid://87694627836510",
        ["void_walker"] = "rbxassetid://114839788144021",
        ["grim_reaper"] = "rbxassetid://86602640135068",
        ["sheep_herder"] = "rbxassetid://72119242704981",
        ["aery"] = "rbxassetid://128665329526198",
        ["archer"] = "rbxassetid://139786277636594",
        ["none"] = "rbxassetid://88127785171552",
        ["ember"] = "rbxassetid://87129411085022",
        ["harpoon"] = "rbxassetid://121220218146634",
        ["spearman"] = "rbxassetid://75938981695199",
        ["void_hunter"] = "rbxassetid://129272558168265",
        ["gargoyle"] = "rbxassetid://107301478672311",
        ["vesta"] = "rbxassetid://136909111665589",
        ["skeleton"] = "rbxassetid://85324261778190",
        ["cyber"] = "rbxassetid://122937183586564",
        ["dasher"] = "rbxassetid://120041539427351",
        ["ghost_catcher"] = "rbxassetid://113752704011687",
        ["miner"] = "rbxassetid://72567120933938",
        ["glacial_skater"] = "rbxassetid://117187556685238",
        ["oil_man"] = "rbxassetid://105446295823018",
        ["axolotl"] = "rbxassetid://100727552818743",
        ["warrior"] = "rbxassetid://98923474606954",
        ["spirit_catcher"] = "rbxassetid://78699308773301",
        ["summoner"] = "rbxassetid://120098524459856",
        ["hannah"] = "rbxassetid://131882135659962",
        ["frosty"] = "rbxassetid://91998606609743",
        ["agni"] = "rbxassetid://133015560143842",
        ["ninja"] = "rbxassetid://71239128941669",
        ["dino_tamer"] = "rbxassetid://114550796009358",
        ["random"] = "rbxassetid://138591077181809",
        ["lumen"] = "rbxassetid://98441857531995",
        ["soul_broker"] = "rbxassetid://90100211262946",
        ["scarab"] = "rbxassetid://80235472468154",
        ["mimic"] = "rbxassetid://121053740329492",
        ["queen_bee"] = "rbxassetid://77506402882644",
        ["slime_tamer"] = "rbxassetid://117034995757038",
        ["oasis"] = "rbxassetid://135547316311877",
        ["void_knight"] = "rbxassetid://74579650838592",
        ["gun_blade"] = "rbxassetid://74758476536826",
        ["beekeeper"] = "rbxassetid://71693490610840",
        ["regent"] = "rbxassetid://86956686237895",
        ["sword_shield"] = "rbxassetid://101544416487997",
        ["wind_walker"] = "rbxassetid://118219467829515",
        ["falconer"] = "rbxassetid://111564181710279",
        ["trapper"] = "rbxassetid://103724550982460",
        ["blood_assassin"] = "rbxassetid://96770702899799",
        ["jailor"] = "rbxassetid://86442736422351",
        ["alchemist"] = "rbxassetid://139743988276829",
        ["defender"] = "rbxassetid://135612202958397",
        ["cat"] = "rbxassetid://75186070748500",
        ["cowgirl"] = "rbxassetid://131936769866518",
        ["airbender"] = "rbxassetid://74978885782392",
        ["infected_tank"] = "rbxassetid://95932519784040",
        ["triple_shot"] = "rbxassetid://75617066930274",
        ["elk_master"] = "rbxassetid://107211513516115",
        ["steam_engineer"] = "rbxassetid://129257135207834",
        ["drill"] = "rbxassetid://95268215348195",
        ["flower_bee"] = "rbxassetid://91930905333899",
        ["dragon_slayer"] = "rbxassetid://127294287820794",
        ["melody"] = "rbxassetid://131954608140758",
        ["super_infected"] = "rbxassetid://95932519784040",
        ["angel"] = "rbxassetid://112355744710472",
        ["jellyfish"] = "rbxassetid://137337538990558",
        ["seahorse"] = "rbxassetid://97038473262234",
        ["paladin"] = "rbxassetid://108919548277586",
        ["cactus"] = "rbxassetid://129436896659981",
        ["farmer_cletus"] = "rbxassetid://139594176886599",
        ["dragon_sword"] = "rbxassetid://135326679979199",
        ["disruptor"] = "rbxassetid://94755614961694",
        ["beast"] = "rbxassetid://131924862561485",
        ["hatter"] = "rbxassetid://78821664156966",
        ["infected_prowler"] = "rbxassetid://95932519784040",
        ["pyro"] = "rbxassetid://137515220784189",
        ["bounty_hunter"] = "rbxassetid://139723957142687",
        ["jade"] = "rbxassetid://106547879080302",
        ["berserker"] = "rbxassetid://125019106696445",
        ["owl"] = "rbxassetid://86489386538846",
        ["battery"] = "rbxassetid://73834166477410",
        ["necromancer"] = "rbxassetid://78816858883573",
        ["ignis"] = "rbxassetid://111825181807436",
        ["gingerbread_man"] = "rbxassetid://84261297927173",
        ["smoke"] = "rbxassetid://115923622563599",
        ["styx"] = "rbxassetid://80457521662429",
        ["pinata"] = "rbxassetid://80841683780580",
        ["shielder"] = "rbxassetid://84931661856422",
        ["taliyah"] = "rbxassetid://137943193297031",
        ["vulcan"] = "rbxassetid://109794247814725",
        ["frost_hammer_kit"] = "rbxassetid://75997613820822",
        ["baker"] = "rbxassetid://85754750342992",
        ["infected_rush"] = "rbxassetid://95932519784040",
        ["elektra"] = "rbxassetid://127007589880652",
        ["star_collector"] = "rbxassetid://120015155094944",
        ["mage"] = "rbxassetid://124458264722930",
        ["davey"] = "rbxassetid://139040666015274",
        ["block_kicker"] = "rbxassetid://92865826457861",
        ["tinker"] = "rbxassetid://128951175702798",
        ["warlock"] = "rbxassetid://80268994897725",
        ["spirit_gardener"] = "rbxassetid://85468040740729",
        ["spider_queen"] = "rbxassetid://73252026171950",
        ["nazar"] = "rbxassetid://126386635809297",
        ["sorcerer"] = "rbxassetid://85553101471599",
        ["wizard"] = "rbxassetid://97812893876603",
        ["fisherman"] = "rbxassetid://80329695301460",
    },
    Enchants = {
        ["soul_reaver"] = "rbxassetid://81080546624764",
        ["execute"] = "rbxassetid://71877480210780",
        ["fire"] = "rbxassetid://131081704940563",
        ["cleave"] = "rbxassetid://81151031012698",
        ["berserker"] = "rbxassetid://82560255878171",
        ["static"] = "rbxassetid://106186066044281",
        ["critical_strike"] = "rbxassetid://119853949957472",
        ["forest"] = "rbxassetid://87746007229992",
    },
}

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local Config = {
    MenuKey = Enum.KeyCode.RightShift,
    UseCanvasGroup = true,
    MaxToasts = 5,
    BoxSize = Vector3.new(3.4, 5.8, 3.4),
    ConfigFile = "pistonware/wrenchhub_cfg.json",
    Resolver = {
        ArmorValueNames = { helmet = "ArmorInvItem_0", chestplate = "ArmorInvItem_1", boots = "ArmorInvItem_2" },
        ArmorOrder = { "helmet", "chestplate", "boots" },
        HandValueName = "HandInvItem",
        KitAttribute = "PlayingAsKit",
        EnchantAttribute = "Enchant",
    },
    Combat = {
        AttackRemoteName = "SwordHit",
        AttackRemotePath = { "rbxts_include", "node_modules", "@rbxts", "net", "out", "_NetManaged", "SwordHit" },
        PlaceRemoteName = "PlaceBlock",
        PlaceRemotePath = { "rbxts_include", "node_modules", "@rbxts", "net", "out", "_NetManaged", "PlaceBlock" },
        InventoriesFolder = "Inventories",
        DefaultAttackDelay = 0.15,
        SwordRank = { wood = 1, stone = 2, iron = 3, diamond = 4, emerald = 5, rageblade = 6 },
    },
    ProjectileProfiles = {
        arrow = { speed = 240, gravity = 35 },
        crossbow = { speed = 400, gravity = 35 },
        headhunter = { speed = 400, gravity = 35 },
        fireball = { speed = 68, gravity = 0 },
        snowball = { speed = 240, gravity = 35 },
        telepearl = { speed = 120, gravity = 70 },
    },
    RangedKeywords = { "bow", "crossbow", "headhunter", "snowball", "fireball", "telepearl", "cannon", "slingshot", "dart", "gun", "lasso" },
    Tiers = {
        { key = "emerald", color = Color3.fromRGB(45, 230, 120) },
        { key = "diamond", color = Color3.fromRGB(60, 200, 255) },
        { key = "iron",    color = Color3.fromRGB(220, 225, 240) },
        { key = "leather", color = Color3.fromRGB(200, 140, 80) },
    },
}

local T = {
    bg = Color3.fromRGB(9, 12, 28),
    off = Color3.fromRGB(30, 35, 58),
    accent = Color3.fromRGB(70, 135, 255),
    header = Color3.fromRGB(110, 235, 215),
    white = Color3.new(1, 1, 1),
    muted = Color3.fromRGB(150, 158, 185),
    danger = Color3.fromRGB(220, 20, 60),
    good = Color3.fromRGB(75, 215, 120),
    warn = Color3.fromRGB(255, 195, 45),
    font = Enum.Font.GothamBold,
}

local Left, Right, Center = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center

local function isolatedRequire(mod)
    if not mod or not mod:IsA("ModuleScript") then return nil end
    local ok, res = pcall(require, mod)
    return ok and res or nil
end

--------------------------------------------------------------------------------
-- Maid
--------------------------------------------------------------------------------
local function Maid()
    local m = { tasks = {} }
    function m:give(x)
        if x ~= nil then table.insert(self.tasks, x) end
        return x
    end
    function m:clean()
        for i = #self.tasks, 1, -1 do
            local t = self.tasks[i]
            self.tasks[i] = nil
            local ty = typeof(t)
            if ty == "RBXScriptConnection" then pcall(function() t:Disconnect() end)
            elseif ty == "Instance" then pcall(function() t:Destroy() end)
            elseif ty == "function" then pcall(t) end
        end
    end
    return m
end
local CoreMaid = Maid()

--------------------------------------------------------------------------------
-- Animation: frame-rate independent exponential follow
--------------------------------------------------------------------------------
local Anim = { live = {} }
local function mix(a, b, k)
    if type(a) == "number" then return a + (b - a) * k end
    return a:Lerp(b, k)
end
local function near(a, b)
    if type(a) == "number" then return math.abs(a - b) < 5e-4 end
    return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 2e-3
end
function Anim.new(initial, rate, apply)
    local s = { value = initial, target = initial, rate = rate }
    function s.to(t, instant)
        s.target = t
        if instant then
            s.value = t
            Anim.live[s] = nil
            apply(t)
        else
            Anim.live[s] = apply
        end
    end
    apply(initial)
    return s
end
local function stepAnims(dt)
    for s, apply in pairs(Anim.live) do
        s.value = mix(s.value, s.target, 1 - math.exp(-s.rate * dt))
        if near(s.value, s.target) then
            s.value = s.target
            Anim.live[s] = nil
        end
        apply(s.value)
    end
end

--------------------------------------------------------------------------------
-- GUI roots
--------------------------------------------------------------------------------
local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r, s)
    return make("UICorner", { CornerRadius = UDim.new(s or 0, r) }, p)
end
local function text(parent, str, size, color, align, pos, sz)
    return make("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = T.font, Text = str, TextSize = size,
        TextColor3 = color, TextXAlignment = align or Left, Position = pos or UDim2.new(),
        Size = sz or UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local guiParent
do
    local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    guiParent = ok and p or LP:WaitForChild("PlayerGui")
end
local Gui = make("ScreenGui", {
    Name = "WrenchHub", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)
local function layer(z)
    return make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z }, Gui)
end
local OverlayL, HudL, MenuL, ToastL = layer(1), layer(2), layer(3), layer(4)

local dragFn, capturing = nil, nil
local State = { notify = true, notifyDuration = 3 }

--------------------------------------------------------------------------------
-- Notifications (custom toasts)
--------------------------------------------------------------------------------
local Toasts = {}
local function layoutToasts()
    for i, t in ipairs(Toasts) do t.y.to((i - 1) * (t.h + 8)) end
end
local function dismiss(t)
    if t.dead then return end
    t.dead = true
    local idx = table.find(Toasts, t)
    if idx then table.remove(Toasts, idx) end
    layoutToasts()
    t.x.to(320)
    t.fade.to(1)
    task.delay(0.45, function() if t.g then t.g:Destroy() end end)
end
local function Notify(title, body, duration, force)
    if not (State.notify or force) then return end
    local h = 50
    local t = { h = h, born = os.clock(), dur = duration or State.notifyDuration, xo = 300, yo = 0, dead = false }
    t.g = make(Config.UseCanvasGroup and "CanvasGroup" or "Frame", {
        AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(250, h), BackgroundColor3 = T.bg,
        BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true,
    }, ToastL)
    corner(t.g, 8)
    make("UIStroke", { Color = T.white, Thickness = 1.5, Transparency = 0.15 }, t.g)
    text(t.g, tostring(title):upper(), 13, T.header, Left, UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 16))
    text(t.g, tostring(body), 12, T.white, Left, UDim2.fromOffset(12, 23), UDim2.new(1, -24, 0, 16))
    local track = make("Frame", { Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = T.off, BorderSizePixel = 0 }, t.g)
    t.bar = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, track)
    local function place() t.g.Position = UDim2.new(1, -16 + t.xo, 1, -16 - t.yo) end
    t.x = Anim.new(300, 15, function(v) t.xo = v place() end)
    t.y = Anim.new(0, 14, function(v) t.yo = v place() end)
    t.fade = Anim.new(1, 14, function(v) if Config.UseCanvasGroup then t.g.GroupTransparency = v end end)
    t.x.to(0)
    t.fade.to(0)
    table.insert(Toasts, 1, t)
    layoutToasts()
    if #Toasts > Config.MaxToasts then dismiss(Toasts[#Toasts]) end
end
local function tickToasts()
    local now = os.clock()
    for i = #Toasts, 1, -1 do
        local t = Toasts[i]
        local k = (now - t.born) / t.dur
        t.bar.Size = UDim2.new(math.clamp(1 - k, 0, 1), 0, 1, 0)
        if k >= 1 then dismiss(t) end
    end
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------
local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function Switch(parent, pos, initial)
    local w, h = 28, 14
    local track = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = pos, Size = UDim2.fromOffset(w, h), BackgroundColor3 = T.off, BorderSizePixel = 0 }, parent)
    corner(track, 99)
    local knob = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(h - 4, h - 4), BackgroundColor3 = T.white, BorderSizePixel = 0 }, track)
    corner(knob, 99)
    local a = Anim.new(initial and 1 or 0, 22, function(v)
        track.BackgroundColor3 = T.off:Lerp(T.accent, v)
        knob.Position = UDim2.new(0, 2 + v * (w - h), 0.5, 0)
    end)
    return { set = function(on, instant) a.to(on and 1 or 0, instant) end }
end

local W = {}
local function rowFrame(parent, order, h)
    return make("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = order, Active = true }, parent)
end

function W.Slider(parent, order, label, min, max, value, step, fmt, onChange)
    local f = rowFrame(parent, order, 30)
    text(f, label:upper(), 11, T.muted, Left, UDim2.new(), UDim2.new(0.65, 0, 0, 14))
    local valL = text(f, string.format(fmt, value), 11, T.white, Right, UDim2.new(0.45, 0, 0, 0), UDim2.new(0.55, 0, 0, 14))
    local track = make("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = T.off, BorderSizePixel = 0 }, f)
    corner(track, 99)
    local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, track)
    corner(fill, 99)
    local knob = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = T.white, BorderSizePixel = 0, ZIndex = 2 }, fill)
    corner(knob, 99)
    local a = Anim.new((value - min) / (max - min), 26, function(p) fill.Size = UDim2.fromScale(p, 1) end)
    local function setValue(v)
        v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
        valL.Text = string.format(fmt, v)
        a.to((v - min) / (max - min))
        if onChange then onChange(v) end
    end
    local function fromX(x)
        local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        setValue(min + p * (max - min))
    end
    local hit = make("Frame", { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Active = true }, f)
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            fromX(i.Position.X)
            dragFn = function(inp) fromX(inp.Position.X) end
        end
    end)
    return setValue
end

function W.Toggle(parent, order, label, value, onChange)
    local f = rowFrame(parent, order, 22)
    text(f, label:upper(), 11, T.muted, Left, UDim2.new(), UDim2.new(1, -40, 1, 0))
    local sw = Switch(f, UDim2.new(1, 0, 0.5, 0), value)
    local state = value
    f.InputBegan:Connect(function(i)
        if isPress(i) then
            state = not state
            sw.set(state)
            onChange(state)
        end
    end)
    return function(v) state = v sw.set(v, true) end
end

function W.Cycle(parent, order, label, options, value, onChange)
    local f = rowFrame(parent, order, 24)
    text(f, label:upper(), 11, T.muted, Left, UDim2.new(), UDim2.new(0.48, 0, 1, 0))
    local idx = table.find(options, value) or 1
    local pill = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.5, 0, 0, 18), BackgroundColor3 = T.off, BorderSizePixel = 0,
    }, f)
    corner(pill, 4)
    make("UIStroke", { Color = T.accent, Thickness = 1, Transparency = 0.35 }, pill)
    local valL = text(pill, "< " .. options[idx]:upper() .. " >", 11, T.header, Center)
    valL.Font = Enum.Font.GothamBold
    f.InputBegan:Connect(function(i)
        local d = 0
        if isPress(i) then d = 1 elseif i.UserInputType == Enum.UserInputType.MouseButton2 then d = -1 end
        if d ~= 0 then
            idx = (idx - 1 + d) % #options + 1
            valL.Text = "< " .. options[idx]:upper() .. " >"
            onChange(options[idx])
        end
    end)
    return function(v)
        local ni = table.find(options, v)
        if ni then idx = ni valL.Text = "< " .. options[idx]:upper() .. " >" end
    end
end

function W.Button(parent, order, label, fn)
    local f = make("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.off, BorderSizePixel = 0, LayoutOrder = order, Active = true }, parent)
    corner(f, 5)
    make("UIStroke", { Color = T.white, Thickness = 1, Transparency = 0.8 }, f)
    text(f, label:upper(), 11, T.white, Center)
    local press = Anim.new(0, 18, function(v) f.BackgroundColor3 = T.off:Lerp(T.accent, v) end)
    f.InputBegan:Connect(function(i)
        if isPress(i) then
            press.to(1, true)
            press.to(0)
            local ok, err = pcall(fn)
            if not ok then warn("[WrenchHub] button error: " .. tostring(err)) end
        end
    end)
end

function W.Bind(parent, order, getKey, setKey)
    local f = rowFrame(parent, order, 22)
    text(f, "KEYBIND", 11, T.muted, Left, UDim2.new(), UDim2.new(0.5, 0, 1, 0))
    local valL = text(f, "", 11, T.white, Right, UDim2.new(0.4, 0, 0, 0), UDim2.new(0.6, 0, 1, 0))
    local function refresh()
        local k = getKey()
        valL.Text = k and ("[" .. k.Name:upper() .. "]") or "[NONE]"
    end
    refresh()
    f.InputBegan:Connect(function(i)
        if isPress(i) then
            valL.Text = "[...]"
            capturing = function(k) setKey(k) refresh() end
        end
    end)
    return refresh
end

--------------------------------------------------------------------------------
-- Panels and modules (higher opacity 0.06 so game text doesn't bleed through)
--------------------------------------------------------------------------------
local ROW_H, PANEL_W = 28, 182
local Modules, Panels = {}, {}
local scheduleAutoSave = function() end

local function Panel(title, index)
    local P = {}
    local holder = make(Config.UseCanvasGroup and "CanvasGroup" or "Frame", {
        Name = title, Position = UDim2.fromOffset(22 + (index - 1) * (PANEL_W + 12), 86),
        Size = UDim2.fromOffset(PANEL_W, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.06, BorderSizePixel = 0,
    }, MenuL)
    corner(holder, 8)
    make("UIStroke", { Color = T.white, Thickness = 1.5, Transparency = 0.12, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, holder)
    local scale = make("UIScale", { Scale = 0.94 }, holder)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, holder)
    make("UIPadding", { PaddingBottom = UDim.new(0, 6) }, holder)
    local head = make("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 0, Active = true }, holder)
    text(head, title:upper(), 15, T.header, Center)
    head.InputBegan:Connect(function(i)
        if isPress(i) then
            local start, base = i.Position, holder.Position
            dragFn = function(inp)
                local d = inp.Position - start
                holder.Position = UDim2.fromOffset(base.X.Offset + d.X, base.Y.Offset + d.Y)
            end
        end
    end)
    P.alpha = Anim.new(0, 17 - index * 1.2, function(a)
        holder.Visible = a > 0.01
        scale.Scale = 0.94 + 0.06 * a
        if Config.UseCanvasGroup then holder.GroupTransparency = 1 - a end
    end)
    Panels[#Panels + 1] = P

    local nextRow = 0
    function P.add(def)
        local m = { name = def.name, opt = {}, enabled = false, key = nil, maid = nil }
        nextRow += 1
        local container = make("Frame", { Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = nextRow }, holder)
        local header = make("Frame", { Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = T.white, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, container)
        text(header, def.name:upper(), 13, def.action and T.danger or T.white, Left, UDim2.fromOffset(12, 0), UDim2.new(1, -54, 1, 0))
        local bar = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, header)
        local sw = (not def.action) and Switch(header, UDim2.new(1, -10, 0.5, 0), false) or nil
        local hover = Anim.new(0, 24, function(v) header.BackgroundTransparency = 1 - 0.08 * v end)
        local sel = Anim.new(0, 22, function(v) bar.Size = UDim2.fromOffset(3, v * (ROW_H - 8)) end)
        header.MouseEnter:Connect(function() hover.to(1) end)
        header.MouseLeave:Connect(function() hover.to(0) end)

        local sf = make("Frame", { Position = UDim2.fromOffset(0, ROW_H), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false }, container)
        local sl = make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
        make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, sf)
        local open, contentH = false, 0
        local expand = Anim.new(0, 20, function(h)
            container.Size = UDim2.new(1, 0, 0, ROW_H + h)
            sf.Visible = h > 0.5
        end)
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            contentH = sl.AbsoluteContentSize.Y + 12
            if open then expand.to(contentH) end
        end)

        local order = 0
        local function nextOrder() order += 1 return order end
        m._syncers = {}
        local ui = {}
        function ui.Slider(key, label, min, max, dflt, step, fmt, cb)
            m.opt[key] = dflt
            m._syncers[key] = W.Slider(sf, nextOrder(), label, min, max, dflt, step, fmt or "%.0f", function(v)
                m.opt[key] = v
                if cb then cb(v) end
                scheduleAutoSave()
            end)
        end
        function ui.Toggle(key, label, dflt, cb)
            m.opt[key] = dflt
            m._syncers[key] = W.Toggle(sf, nextOrder(), label, dflt, function(v)
                m.opt[key] = v
                if cb then cb(v) end
                scheduleAutoSave()
            end)
        end
        function ui.Cycle(key, label, options, dflt)
            m.opt[key] = dflt
            m._syncers[key] = W.Cycle(sf, nextOrder(), label, options, dflt, function(v)
                m.opt[key] = v
                scheduleAutoSave()
            end)
        end
        function ui.Button(label, fn) W.Button(sf, nextOrder(), label, fn) end
        function ui.Note(msg)
            local lbl = text(sf, msg, 10, T.warn, Left, UDim2.new(), UDim2.new(1, 0, 0, 14))
            lbl.LayoutOrder = nextOrder()
        end

        if def.settings then def.settings(ui, m) end
        if not def.action then
            m._syncBind = W.Bind(sf, nextOrder(), function() return m.key end, function(k) m.key = k scheduleAutoSave() end)
        end

        function m.set(v, silent)
            v = v and true or false
            if v == m.enabled then return end
            if v then
                local maid = Maid()
                local ok, err = pcall(def.enable, m, maid)
                if not ok then
                    maid:clean()
                    warn("[WrenchHub] " .. def.name .. " enable failed: " .. tostring(err))
                    Notify(def.name, (tostring(err):gsub("^[^:]*:%d+: ", "")), 5, true)
                    return
                end
                m.maid = maid
                m.enabled = true
            else
                m.enabled = false
                if m.maid then m.maid:clean() m.maid = nil end
                if def.disable then pcall(def.disable, m) end
            end
            if sw then sw.set(m.enabled) end
            sel.to(m.enabled and 1 or 0)
            if not silent then
                Notify(def.name, m.enabled and "Enabled" or "Disabled", 2)
                scheduleAutoSave()
            end
        end

        header.InputBegan:Connect(function(i)
            if isPress(i) then
                if def.action then def.action() else m.set(not m.enabled) end
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 and not def.action then
                open = not open
                expand.to(open and contentH or 0)
            end
        end)

        Modules[#Modules + 1] = m
        if def.default then m.set(true, true) end
        return m
    end
    return P
end

local menuOpen, tipShown = false, false
local function setMenu(v)
    menuOpen = v
    for _, p in ipairs(Panels) do p.alpha.to(v and 1 or 0) end
    if v and not tipShown then
        tipShown = true
        Notify("Hub", "Right click a row for settings", 3)
    end
end

--------------------------------------------------------------------------------
-- Entities (TargetScanner + Viewmodel/Shopkeeper filtering)
--------------------------------------------------------------------------------
local Entities = { list = {}, byModel = {}, refs = 0 }
local npcRegistry = {}

local SHOP_KEYWORDS = {
    "merchant", "shop", "florist", "blacksmith", "vendor",
    "store", "guide", "banker", "teller", "upgrade"
}

local blockedCache = setmetatable({}, { __mode = "k" })
local function isBlockedModel(model)
    if not model or not model:IsA("Model") then return true end
    local myChar = LP.Character
    if myChar and (model == myChar or model:IsDescendantOf(myChar)) then return true end
    local cached = blockedCache[model]
    if cached ~= nil then return cached end
    local blocked = false
    local c = cam()
    if c and model:IsDescendantOf(c) then blocked = true end
    if not blocked then
        local nl = model.Name:lower()
        if nl:find("viewmodel", 1, true) or nl:find("arms", 1, true) or nl:find("hand", 1, true) then
            blocked = true
        elseif not Players:GetPlayerFromCharacter(model) then
            for _, kw in ipairs(SHOP_KEYWORDS) do
                if nl:find(kw, 1, true) then blocked = true break end
            end
            if not blocked and model:FindFirstChildWhichIsA("ProximityPrompt", true) then
                blocked = true
            end
        end
    end
    blockedCache[model] = blocked
    return blocked
end

local function registerNpc(model, kind)
    if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return end
    if isBlockedModel(model) then return end
    task.spawn(function()
        local h = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 2)
        if h and h:IsA("Humanoid") and not npcRegistry[h] then
            npcRegistry[h] = kind
        end
    end)
end

local function trackDummy(h)
    if not h:IsA("Humanoid") then return end
    local model = h.Parent
    if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) and not isBlockedModel(model) then
        if model.Name:lower():find("dummy", 1, true) then
            npcRegistry[h] = "dummy"
        end
    end
end

for _, d in ipairs(workspace:GetDescendants()) do trackDummy(d) end
CoreMaid:give(workspace.DescendantAdded:Connect(trackDummy))
CoreMaid:give(workspace.DescendantRemoving:Connect(function(d) npcRegistry[d] = nil end))

local BEDWARS_TAGS = { "Monster", "DiamondGuardian", "GolemBoss", "Drone", "Mob", "NPC", "Enemy", "monster", "mob", "npc", "enemy" }
for _, tag in ipairs(BEDWARS_TAGS) do
    for _, inst in ipairs(CollectionService:GetTagged(tag)) do registerNpc(inst, "npc") end
    CoreMaid:give(CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst) registerNpc(inst, "npc") end))
end
for _, folderName in ipairs({ "NPCs", "Mobs" }) do
    local f = workspace:FindFirstChild(folderName)
    if f then
        for _, ch in ipairs(f:GetChildren()) do registerNpc(ch, "npc") end
        CoreMaid:give(f.ChildAdded:Connect(function(ch) registerNpc(ch, "npc") end))
    end
end

function Entities.acquire()
    Entities.refs += 1
    local released = false
    return function()
        if not released then released = true Entities.refs -= 1 end
    end
end

function Entities.rebuild()
    local list, by = {}, {}
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local mp = myRoot and myRoot.Position
    local myTeam = LP.Team
    local myTeamAttr = LP:GetAttribute("Team")

    local function push(model, hum, root, name, player, color, friendly, dummy, npc)
        local pos = root.Position
        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return end
        local e = {
            model = model, hum = hum, root = root, head = model:FindFirstChild("Head"),
            name = name, player = player, color = color,
            friendly = friendly, isDummy = dummy, isNpc = npc, dist = mp and (pos - mp).Magnitude or math.huge,
        }
        list[#list + 1] = e
        by[model] = e
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and not isBlockedModel(ch) then
                local sameTeam = (myTeam ~= nil and p.Team == myTeam) or (myTeamAttr ~= nil and p:GetAttribute("Team") == myTeamAttr)
                push(ch, hum, root, p.Name, p, p.TeamColor.Color, sameTeam, false, false)
            end
        end
    end

    for hum, kind in pairs(npcRegistry) do
        local model = hum.Parent
        if model and hum.Health > 0 and not isBlockedModel(model) then
            local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head")
            if root then
                local npcTeam = model:GetAttribute("Team")
                local ownerId = tonumber(model:GetAttribute("PlayerUserId"))
                local friendly = (myTeamAttr ~= nil and npcTeam == myTeamAttr) or (ownerId == LP.UserId)
                push(model, hum, root, model.Name, nil, Color3.fromRGB(190, 190, 205), friendly, true, kind == "npc")
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    Entities.list, Entities.byModel = list, by
end

local TargetState = { model = nil }
local Targeting = { by = {}, last = nil }
function Targeting.report(e, src)
    local r = { model = e.model, src = src, t = os.clock() }
    Targeting.by[src] = r
    Targeting.last = r
end
function Targeting.model()
    local L = Targeting.last
    if L and os.clock() - L.t < 0.6 then return L.model end
    return TargetState.model
end

local PRESET = {
    Red = Color3.fromRGB(255, 70, 70),
    Cyan = Color3.fromRGB(80, 230, 255),
    White = Color3.new(1, 1, 1),
}
local function entColor(e, mode, markTarget)
    if markTarget and Targeting.model() == e.model then return T.danger end
    if mode == "Team" then return e.color end
    return PRESET[mode] or e.color
end

--------------------------------------------------------------------------------
-- Static Item / Kit / Enchant Resolver (zero item-meta require)
--------------------------------------------------------------------------------
local function itemImage(name, model)
    if not name or name == "" then return nil end
    local img = AssetData.Items[name] or AssetData.Items[name:lower()]
    if img and img ~= "" then return img end
    if model then
        local tool = model:FindFirstChild(name)
        if tool and tool:IsA("Tool") and tool.TextureId ~= "" then return tool.TextureId end
    end
    return nil
end

local function kitImage(player, model)
    local kid = (player and player:GetAttribute(Config.Resolver.KitAttribute)) or (model and model:GetAttribute(Config.Resolver.KitAttribute))
    if type(kid) == "string" and kid ~= "" then
        return AssetData.Kits[kid] or AssetData.Kits[kid:lower()], kid
    end
    return nil, nil
end

local function enchantImage(model)
    if not model then return nil end
    local ench = model:GetAttribute(Config.Resolver.EnchantAttribute) or model:GetAttribute("WeaponEnchant")
    if type(ench) == "string" and ench ~= "" then
        return AssetData.Enchants[ench] or AssetData.Enchants[ench:lower()]
    end
    return nil
end

local function heldName(model)
    if not model then return nil end
    local hvName = Config.Resolver.HandValueName
    local hv = hvName and model:FindFirstChild(hvName)
    if hv then
        if hv:IsA("ObjectValue") and hv.Value then return hv.Value.Name end
        if hv:IsA("StringValue") and hv.Value ~= "" then return hv.Value end
    end
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    for _, ch in ipairs(model:GetChildren()) do
        if ch:IsA("Model") and (AssetData.Items[ch.Name] or AssetData.Items[ch.Name:lower()] or ch:FindFirstChild("Handle")) then
            return ch.Name
        end
    end
    return nil
end

local function isRangedWeapon(itemName)
    if not itemName then return false end
    local nl = itemName:lower()
    for _, kw in ipairs(Config.RangedKeywords) do
        if nl:find(kw, 1, true) then return true end
    end
    return false
end

local function getProjectileProfile(itemName)
    if not itemName then return nil end
    local nl = itemName:lower()
    for key, prof in pairs(Config.ProjectileProfiles) do
        if nl:find(key, 1, true) then return prof end
    end
    return Config.ProjectileProfiles.arrow
end

local function readLoadout(model, isDummy)
    local armor = {}
    if isDummy then
        local nl = model.Name:lower()
        for _, t in ipairs(Config.Tiers) do
            if nl:find(t.key, 1, true) then
                for _, slot in ipairs(Config.Resolver.ArmorOrder) do armor[slot] = t.key .. "_" .. slot end
                break
            end
        end
    else
        for slot, valName in pairs(Config.Resolver.ArmorValueNames) do
            local v = model:FindFirstChild(valName)
            if v then
                if v:IsA("ObjectValue") and v.Value then armor[slot] = v.Value.Name
                elseif v:IsA("StringValue") and v.Value ~= "" then armor[slot] = v.Value end
            end
        end
    end
    return armor, heldName(model)
end

--------------------------------------------------------------------------------
-- Target Info Card (newgui.lua Glassmorphism + Circular Avatar + Kit Icon + RichText)
--------------------------------------------------------------------------------
local function healthColor(p)
    if p > 0.5 then return T.good elseif p >= 0.2 then return T.warn end
    return Color3.fromRGB(245, 65, 65)
end
local function colorHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

local Card
local function buildCard()
    local C = { lastPct = 1, holdUntil = 0, lastHpStr = "", lastDistStr = "" }
    local card = make(Config.UseCanvasGroup and "CanvasGroup" or "Frame", {
        Name = "TargetInfo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.6, 0, 0.72, 0),
        Size = UDim2.fromOffset(268, 76), BackgroundColor3 = Color3.fromRGB(16, 18, 28), BackgroundTransparency = 0.72,
        BorderSizePixel = 0, Active = true, Visible = false,
    }, HudL)
    corner(card, 18)
    make("UIStroke", { Color = T.white, Thickness = 1, Transparency = 0.75 }, card)
    local sc = make("UIScale", { Scale = 0.9 }, card)

    local av = make("Frame", { Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.off, BorderSizePixel = 0 }, card)
    corner(av, 0, 1)
    local ring = make("UIStroke", { Thickness = 2, Color = T.good }, av)
    local avImg = make("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150" }, av)
    corner(avImg, 0, 1)

    local kitBadge = make("ImageLabel", {
        Position = UDim2.fromOffset(38, 40), Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(18, 20, 32), BackgroundTransparency = 0.1,
        BorderSizePixel = 0, Visible = false, ZIndex = 4, ScaleType = Enum.ScaleType.Fit,
    }, card)
    corner(kitBadge, 0, 1)
    make("UIStroke", { Color = T.white, Thickness = 1, Transparency = 0.65 }, kitBadge)

    local topRow = make("Frame", { Position = UDim2.fromOffset(62, 10), Size = UDim2.new(1, -114, 0, 16), BackgroundTransparency = 1, ClipsDescendants = true }, card)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, topRow)

    local nameL = text(topRow, "", 13, T.white, Left, UDim2.new(), UDim2.fromOffset(0, 16))
    nameL.Font = Enum.Font.GothamBold
    nameL.TextStrokeTransparency = 0.55
    nameL.AutomaticSize = Enum.AutomaticSize.X
    nameL.LayoutOrder = 1
    make("UISizeConstraint", { MaxSize = Vector2.new(96, 16) }, nameL)

    local iconsRow = make("Frame", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 2 }, topRow)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 3) }, iconsRow)
    local iconSlots = {}
    for i = 1, 5 do
        iconSlots[i] = make("ImageLabel", { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Visible = false, ScaleType = Enum.ScaleType.Fit }, iconsRow)
    end

    local distL = text(card, "", 11, T.muted, Right, UDim2.new(1, -54, 0, 11), UDim2.fromOffset(44, 14))
    distL.Font = Enum.Font.GothamMedium
    distL.TextStrokeTransparency = 0.55
    distL.TextColor3 = T.white

    local hpL = text(card, "", 12, T.white, Left, UDim2.fromOffset(62, 30), UDim2.new(1, -72, 0, 15))
    hpL.Font = Enum.Font.GothamBold
    hpL.RichText = true

    local barBg = make("Frame", { Position = UDim2.fromOffset(62, 50), Size = UDim2.new(1, -74, 0, 5), BackgroundColor3 = T.off, BorderSizePixel = 0 }, card)
    corner(barBg, 99)
    local ghostBar = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(245, 225, 140), BorderSizePixel = 0, ZIndex = 2 }, barBg)
    corner(ghostBar, 99)
    local mainBar = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.good, BorderSizePixel = 0, ZIndex = 3 }, barBg)
    corner(mainBar, 99)

    local flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 55, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Active = false }, card)
    corner(flash, 18)

    C.card = card
    C.show = Anim.new(0, 14, function(a)
        card.Visible = a > 0.01
        sc.Scale = 0.9 + 0.1 * a
        if Config.UseCanvasGroup then card.GroupTransparency = 1 - a end
    end)
    C.main = Anim.new(1, 18, function(p) mainBar.Size = UDim2.fromScale(math.clamp(p, 0, 1), 1) end)
    C.ghost = Anim.new(1, 3.2, function(p) ghostBar.Size = UDim2.fromScale(math.clamp(p, 0, 1), 1) end)
    C.col = Anim.new(T.good, 12, function(c) mainBar.BackgroundColor3 = c ring.Color = c end)
    C.flash = Anim.new(0, 10, function(v) flash.BackgroundTransparency = 1 - 0.35 * v end)

    card.InputBegan:Connect(function(i)
        if isPress(i) then
            local start, base = i.Position, card.Position
            dragFn = function(inp)
                local d = inp.Position - start
                card.Position = UDim2.new(base.X.Scale, base.X.Offset + d.X, base.Y.Scale, base.Y.Offset + d.Y)
            end
        end
    end)

    function C.bind(cur)
        nameL.Text = cur.name
        local uid = (cur.player and cur.player.UserId) or 1
        avImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150"
        local kImg = (not cur.isDummy) and kitImage(cur.player, cur.model) or nil
        if kImg then
            kitBadge.Image = kImg
            kitBadge.Visible = true
        else
            kitBadge.Visible = false
        end
        local p = math.clamp(cur.hum.Health / math.max(cur.hum.MaxHealth, 1), 0, 1)
        C.lastPct, C.holdUntil, C.lastHpStr, C.lastDistStr, C.sig = p, 0, "", "", ""
        C.main.to(p, true)
        C.ghost.to(p, true)
        C.col.to(healthColor(p), true)
        C.flash.to(0, true)
    end

    function C.setLoadout(armor, held, enchImg, model)
        local parts = { held or "", enchImg or "" }
        for _, slot in ipairs(Config.Resolver.ArmorOrder) do parts[#parts + 1] = armor[slot] or "" end
        local sig = table.concat(parts, "|")
        if sig == C.sig then return end
        C.sig = sig
        local imgs = {}
        if held then
            local hi = itemImage(held, model)
            if hi then imgs[#imgs + 1] = hi end
        end
        for _, slot in ipairs(Config.Resolver.ArmorOrder) do
            if armor[slot] then
                local ai = itemImage(armor[slot], model)
                if ai then imgs[#imgs + 1] = ai end
            end
        end
        if enchImg and #imgs < 5 then imgs[#imgs + 1] = enchImg end
        for i, slotImg in ipairs(iconSlots) do
            local u = imgs[i]
            slotImg.Visible = u ~= nil
            if u then slotImg.Image = u end
        end
    end

    function C.update(cur, dist, now)
        local hum = cur.hum
        local hp = math.max(hum.Health, 0)
        local maxHp = math.max(hum.MaxHealth, 1)
        local p = math.clamp(hp / maxHp, 0, 1)
        local c = healthColor(p)
        local hpStr = cur.deadAt
            and '<font color="#F54141">ELIMINATED</font>'
            or string.format('<font color="%s"><b>%d ♥</b></font> <font size="10" color="#969EB9">/ %d</font>', colorHex(c), math.ceil(hp), math.ceil(maxHp))
        if hpStr ~= C.lastHpStr then hpL.Text = hpStr C.lastHpStr = hpStr end
        local dStr = dist and string.format("%dm", math.floor(dist + 0.5)) or ""
        if dStr ~= C.lastDistStr then distL.Text = dStr C.lastDistStr = dStr end

        if p < C.lastPct - 0.0005 then
            C.flash.to(1, true)
            C.flash.to(0)
            C.holdUntil = now + 0.35
        elseif p > C.lastPct then
            C.ghost.to(p, true)
        end
        C.lastPct = p
        C.main.to(p)
        if now >= C.holdUntil then C.ghost.to(p) end
        C.col.to(c)
    end
    return C
end

--------------------------------------------------------------------------------
-- Build panels
--------------------------------------------------------------------------------
local PCombat = Panel("Combat", 1)
local PRender = Panel("Render", 2)
local PHud = Panel("Hud", 3)
local PMovement = Panel("Movement", 4)
local PMisc = Panel("Misc", 5)
local SIGNS = { -1, 1 }

--------------------------------------------------------------------------------
-- Combat Helpers (Kill Aura + Projectile Aimbot)
--------------------------------------------------------------------------------
local function findRemote(pathList, nameFallback)
    local node = ReplicatedStorage
    for _, k in ipairs(pathList) do
        node = node and node:FindFirstChild(k)
    end
    if node and (node:IsA("RemoteEvent") or node:IsA("RemoteFunction")) then return node end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name == nameFallback then return d end
    end
    return nil
end

local attackRemote
local function getAttackRemote()
    if attackRemote and attackRemote.Parent then return attackRemote end
    attackRemote = findRemote(Config.Combat.AttackRemotePath, Config.Combat.AttackRemoteName)
    return attackRemote
end

local placeRemote
local function getPlaceRemote()
    if placeRemote and placeRemote.Parent then return placeRemote end
    placeRemote = findRemote(Config.Combat.PlaceRemotePath, Config.Combat.PlaceRemoteName)
    return placeRemote
end

local function pickSword()
    local ch = LP.Character
    if ch then
        local hv = ch:FindFirstChild(Config.Resolver.HandValueName)
        if hv and hv:IsA("ObjectValue") and hv.Value then
            local hn = hv.Value.Name:lower()
            if hn:find("sword", 1, true) or hn:find("blade", 1, true) or hn:find("scythe", 1, true) then
                return hv.Value
            end
        end
    end
    local held = heldName(ch)
    local inv = ReplicatedStorage:FindFirstChild(Config.Combat.InventoriesFolder)
    inv = inv and inv:FindFirstChild(LP.Name)
    local best, bestRank = nil, -1
    if inv then
        for _, it in ipairs(inv:GetChildren()) do
            local n = it.Name:lower()
            if n:find("sword", 1, true) or n:find("blade", 1, true) or n:find("scythe", 1, true) then
                local rank = 0
                for key, r in pairs(Config.Combat.SwordRank) do
                    if n:find(key, 1, true) and r > rank then rank = r end
                end
                if held and it.Name == held then rank += 100 end
                if rank > bestRank then best, bestRank = it, rank end
            end
        end
    end
    if best then return best end
    for _, container in ipairs({ ch, LP:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, c in ipairs(container:GetChildren()) do
                if c:IsA("Tool") then
                    local n = c.Name:lower()
                    if n:find("sword", 1, true) or n:find("blade", 1, true) or n:find("scythe", 1, true) then return c end
                end
            end
        end
    end
    return nil
end

local function equipToolIfNeeded(itemObj)
    if not itemObj then return end
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if itemObj:IsA("Tool") and itemObj.Parent ~= ch then
        pcall(function() hum:EquipTool(itemObj) end)
    end
end

local function collectAvailableProjectiles()
    local found = {}
    local inv = ReplicatedStorage:FindFirstChild(Config.Combat.InventoriesFolder)
    inv = inv and inv:FindFirstChild(LP.Name)
    if inv then
        for _, it in ipairs(inv:GetChildren()) do
            if isRangedWeapon(it.Name) then
                found[#found + 1] = { Name = it.Name, Profile = getProjectileProfile(it.Name) }
            end
        end
    end
    return found
end

local PRED_EPS = 1e-9
local function predZero(d) return d > -PRED_EPS and d < PRED_EPS end
local function predCbrt(x) return (x > 0) and math.pow(x, 1 / 3) or -math.pow(math.abs(x), 1 / 3) end
local function predPush(list, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then list[#list + 1] = v end
    end
end
local function solveQuadric(c0, c1, c2)
    local p, q = c1 / (2 * c0), c2 / c0
    local D = p * p - q
    if predZero(D) then return -p
    elseif D < 0 then return nil
    else
        local sq = math.sqrt(D)
        return sq - p, -sq - p
    end
end
local function solveCubic(c0, c1, c2, c3)
    local A, B, C = c1 / c0, c2 / c0, c3 / c0
    local sqA = A * A
    local p = (1 / 3) * (-(1 / 3) * sqA + B)
    local q = 0.5 * ((2 / 27) * A * sqA - (1 / 3) * A * B + C)
    local cbP = p * p * p
    local D = q * q + cbP
    local s0, s1, s2, num = 0, 0, 0, 0
    if predZero(D) then
        if predZero(q) then s0 = 0 num = 1
        else local u = predCbrt(-q) s0 = 2 * u s1 = -u num = 2 end
    elseif D < 0 then
        local phi = (1 / 3) * math.acos(math.clamp(-q / math.sqrt(-cbP), -1, 1))
        local t = 2 * math.sqrt(-p)
        s0 = t * math.cos(phi)
        s1 = -t * math.cos(phi + math.pi / 3)
        s2 = -t * math.cos(phi - math.pi / 3)
        num = 3
    else
        local sqD = math.sqrt(D)
        s0 = predCbrt(sqD - q) - predCbrt(sqD + q)
        num = 1
    end
    local sub = (1 / 3) * A
    if num > 0 then s0 -= sub end
    if num > 1 then s1 -= sub end
    if num > 2 then s2 -= sub end
    if num == 3 then return s0, s1, s2
    elseif num == 2 then return s0, s1
    elseif num == 1 then return s0 end
end
local function softSqrt(x, scale)
    if x >= 0 then return math.sqrt(x) end
    if x > -1e-9 * math.max(scale, 1) then return 0 end
    return nil
end
local function solveQuartic(c0, c1, c2, c3, c4)
    local roots = {}
    local A, B, C, D = c1 / c0, c2 / c0, c3 / c0, c4 / c0
    local sqA = A * A
    local p = -0.375 * sqA + B
    local q = 0.125 * sqA * A - 0.5 * A * B + C
    local r = -(3 / 256) * sqA * sqA + 0.0625 * sqA * B - 0.25 * A * C + D
    if predZero(r) then
        predPush(roots, solveCubic(1, 0, p, q))
        predPush(roots, 0)
    else
        local z = solveCubic(1, -0.5 * p, -r, 0.5 * r * p - 0.125 * q * q)
        if not z then return nil end
        local u = softSqrt(z * z - r, math.max(z * z, math.abs(r)))
        local v = softSqrt(2 * z - p, math.max(math.abs(2 * z), math.abs(p)))
        if not (u and v) then return nil end
        predPush(roots, solveQuadric(1, q < 0 and -v or v, z - u))
        predPush(roots, solveQuadric(1, q < 0 and v or -v, z + u))
    end
    local sub = 0.25 * A
    for i, s in ipairs(roots) do roots[i] = s - sub end
    return roots
end
local function evalQuartic(c4, c3, c2, c1, c0, t)
    return (((c4 * t + c3) * t + c2) * t + c1) * t + c0,
           ((4 * c4 * t + 3 * c3) * t + 2 * c2) * t + c1
end
local function earliestRoot(c4, c3, c2, c1, c0)
    local tMin = 1e-6
    local scale = math.max(math.abs(c4), math.abs(c3), math.abs(c2), math.abs(c1), math.abs(c0), 1e-12)
    local candidates = {}
    if math.abs(c4) > 1e-12 * scale then
        candidates = solveQuartic(c4, c3, c2, c1, c0) or candidates
    elseif math.abs(c2) > 1e-12 * scale then
        predPush(candidates, solveQuadric(c2, c1, c0))
    elseif math.abs(c1) > 1e-12 * scale then
        predPush(candidates, -c0 / c1)
    end
    local best
    for _, t in ipairs(candidates) do
        if t == t then
            local f = evalQuartic(c4, c3, c2, c1, c0, t)
            local pol = t
            for _ = 1, 4 do
                local pf, df = evalQuartic(c4, c3, c2, c1, c0, pol)
                if df == 0 then break end
                pol -= pf / df
            end
            local pf = evalQuartic(c4, c3, c2, c1, c0, pol)
            if pf == pf and math.abs(pf) <= math.abs(f) then t, f = pol, pf end
            local at = math.abs(t)
            local size = math.abs(c4) * at^4 + math.abs(c3) * at^3 + math.abs(c2) * at * at + math.abs(c1) * at + math.abs(c0)
            if t > tMin and math.abs(f) <= 1e-6 * size and (not best or t < best) then best = t end
        end
    end
    return best
end

local function leadAim(origin, pos, vel, speed, gravity, tracker, now)
    if not speed or speed <= 0 then return pos end
    local g = gravity or 0
    local isKb = tracker and tracker.kbUntil and now and now < tracker.kbUntil
    local effVel = vel
    if isKb and tracker.kbBase then
        local approxT = (pos - origin).Magnitude / speed
        effVel = tracker.kbBase:Lerp(vel, math.exp(-(tracker.kbDecay or 3.0) * approxT))
    elseif tracker and tracker.turnRate and math.abs(tracker.turnRate) > 0.05 then
        local approxT = (pos - origin).Magnitude / speed
        local ang = math.clamp(tracker.turnRate * approxT * 0.5, -1.2, 1.2)
        local cs, sn = math.cos(ang), math.sin(ang)
        effVel = Vector3.new(vel.X * cs - vel.Z * sn, vel.Y, vel.X * sn + vel.Z * cs)
    end
    local disp = pos - origin
    local h, j, k = disp.X, disp.Y, disp.Z
    local p, q, r = effVel.X, effVel.Y, effVel.Z
    local l = -0.5 * g
    local t = earliestRoot(
        l * l,
        -2 * q * l,
        q * q - 2 * j * l - speed * speed + p * p + r * r,
        2 * j * q + 2 * h * p + 2 * k * r,
        j * j + h * h + k * k
    )
    if t then
        return pos + effVel * t + Vector3.new(0, 0.5 * g * t * t, 0)
    end
    local approxT = disp.Magnitude / speed
    return pos + effVel * approxT + Vector3.new(0, 0.5 * g * approxT * approxT, 0)
end

local function dumpValue(v, depth)
    depth = depth or 0
    local ty = typeof(v)
    if ty == "table" then
        if depth >= 4 then return "{...}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > 16 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. dumpValue(x, depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif ty == "Instance" then
        return "<" .. v.ClassName .. " " .. v:GetFullName() .. ">"
    elseif ty == "string" then
        return string.format("%q", v)
    end
    return ty .. ":" .. tostring(v)
end

local capture = { installed = false, untilT = 0, counts = {} }
local function captureShots(seconds)
    if not (hookmetamethod and getnamecallmethod) then
        Notify("Capture", "Executor has no hookmetamethod", 4, true)
        return
    end
    capture.untilT = os.clock() + seconds
    capture.counts = {}
    if not capture.installed then
        capture.installed = true
        local old
        local function hooked(self, ...)
            if os.clock() < capture.untilT and getnamecallmethod() == "FireServer" and typeof(self) == "Instance" then
                local full = self:GetFullName()
                local n = (capture.counts[full] or 0) + 1
                capture.counts[full] = n
                if n <= 2 then
                    local packed = table.pack(...)
                    task.spawn(function()
                        local parts = {}
                        for i = 1, packed.n do parts[i] = dumpValue(packed[i]) end
                        print("[WrenchHub capture] " .. full .. " #" .. n .. " (" .. table.concat(parts, " | ") .. ")")
                    end)
                end
            end
            return old(self, ...)
        end
        old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(hooked) or hooked)
    end
    Notify("Capture", "Fire your launcher now (" .. seconds .. "s)", 4, true)
end

--------------------------------------------------------------------------------
-- COMBAT : Kill Aura (Blatant + KillauraTargetLoop multi-target/FOV/priority)
--------------------------------------------------------------------------------
PCombat.add({
    name = "Kill Aura",
    settings = function(ui)
        ui.Slider("range", "Attack range", 6, 30, 20, 0.5, "%.1f")
        ui.Slider("swing", "Swing range", 6, 35, 22, 0.5, "%.1f")
        ui.Slider("delay", "Delay (s)", 0.05, 0.5, Config.Combat.DefaultAttackDelay, 0.01, "%.2f")
        ui.Slider("fov", "FOV", 30, 360, 360, 10, "%.0f")
        ui.Slider("maxTargets", "Max targets", 1, 5, 1, 1, "%.0f")
        ui.Cycle("priority", "Priority", { "Distance", "Health" }, "Distance")
        ui.Toggle("players", "Players", true)
        ui.Toggle("npcs", "NPCs & dummies", true)
        ui.Toggle("wallcheck", "Wallcheck", false)
        ui.Toggle("autoEquip", "Auto equip", false)
        ui.Toggle("swingAnim", "3rd person swing", true)
        ui.Toggle("face", "Face target", false)
    end,
    enable = function(m, maid)
        local o = m.opt
        if not getAttackRemote() then
            error("attack remote '" .. Config.Combat.AttackRemoteName .. "' not found")
        end
        maid:give(Entities.acquire())
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local last = 0
        local swingAnimObj = maid:give(Instance.new("Animation"))
        swingAnimObj.AnimationId = "rbxassetid://4947108314"
        local cachedHum, cachedTrack = nil, nil
        local function playSwing(hum)
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            if cachedHum ~= hum or not cachedTrack then
                cachedHum = hum
                local ok, tr = pcall(function() return animator:LoadAnimation(swingAnimObj) end)
                if ok and tr then
                    tr.Priority = Enum.AnimationPriority.Action
                    cachedTrack = tr
                end
            end
            if cachedTrack then
                pcall(function() cachedTrack:Play(0.05, 1, 1.8) end)
            end
        end
        maid:give(RunService.Heartbeat:Connect(function()
            local c = cam()
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not c or not hum or not root or hum.Health <= 0 then return end
            local spos = root.Position
            local lookFlat = (root.CFrame.LookVector * Vector3.new(1, 0, 1))
            if lookFlat.Magnitude > 1e-3 then lookFlat = lookFlat.Unit end

            local playerPool, npcPool = {}, {}
            local scanRange = math.max(o.range, o.swing)
            for _, e in ipairs(Entities.list) do
                if e.dist > scanRange then break end
                if not e.friendly then
                    local okType = (not e.isDummy and o.players) or (e.isDummy and o.npcs)
                    if okType then
                        local passFov = true
                        if o.fov < 360 then
                            local flat = (e.root.Position - spos) * Vector3.new(1, 0, 1)
                            if flat.Magnitude > 0.1 then
                                local ang = math.deg(math.acos(math.clamp(lookFlat:Dot(flat.Unit), -1, 1)))
                                passFov = ang <= (o.fov / 2)
                            end
                        end
                        local passWall = true
                        if passFov and o.wallcheck then
                            rp.FilterDescendantsInstances = { ch, e.model }
                            passWall = workspace:Raycast(spos, e.root.Position - spos, rp) == nil
                        end
                        if passFov and passWall then
                            if not e.isDummy then playerPool[#playerPool + 1] = e else npcPool[#npcPool + 1] = e end
                        end
                    end
                end
            end

            local pool = (#playerPool > 0) and playerPool or npcPool
            if #pool == 0 then return end
            if o.priority == "Health" then
                table.sort(pool, function(a, b) return a.hum.Health < b.hum.Health end)
            end

            local primary = pool[1]
            Targeting.report(primary, "KillAura")

            local now = os.clock()
            if now - last < o.delay then return end
            local sword = pickSword()
            local remote = getAttackRemote()
            if not sword or not remote then return end
            if o.autoEquip then equipToolIfNeeded(sword) end

            last = now
            if o.face then
                local tp = primary.root.Position
                root.CFrame = CFrame.lookAt(spos, Vector3.new(tp.X, spos.Y, tp.Z))
            end

            local hits = 0
            for i = 1, math.min(#pool, o.maxTargets) do
                local t = pool[i]
                if t.dist <= o.range then
                    local tpos = t.root.Position
                    local dir = tpos - spos
                    if dir.Magnitude >= 0.01 then
                        local validSelf = (dir.Magnitude > 13.5) and (tpos - dir.Unit * 13.5) or spos
                        local camPos = c.CFrame.Position
                        local camDir = (tpos - camPos)
                        camDir = (camDir.Magnitude >= 0.01) and camDir.Unit or dir.Unit
                        local packet = {
                            entityInstance = t.model,
                            chargedAttack = { chargeRatio = 0 },
                            validate = {
                                targetPosition = { value = tpos },
                                selfPosition = { value = validSelf },
                                raycast = {
                                    cameraPosition = { value = camPos },
                                    cursorDirection = { value = camDir },
                                },
                            },
                            weapon = sword,
                        }
                        if remote:IsA("RemoteFunction") then
                            task.spawn(function() pcall(function() remote:InvokeServer(packet) end) end)
                        else
                            pcall(function() remote:FireServer(packet) end)
                        end
                        hits += 1
                    end
                end
            end
            if hits > 0 and o.swingAnim then
                playSwing(hum)
            end
        end))
    end,
})

--------------------------------------------------------------------------------
-- COMBAT : Projectile Aimbot (ProjectileAura lead + parabolic compensation)
--------------------------------------------------------------------------------
local SilentAimState = { active = false, targetPos = nil, origin = nil }
local silentHookInstalled = false

local function redirectVecTable(tbl, origin, targetPos)
    local dir = (targetPos - origin)
    if dir.Magnitude < 0.01 then return end
    local unitDir = dir.Unit
    for k, v in pairs(tbl) do
        local kl = tostring(k):lower()
        if typeof(v) == "Vector3" then
            if kl:find("vel", 1, true) and v.Magnitude > 5 then
                tbl[k] = unitDir * v.Magnitude
            elseif kl:find("dir", 1, true) then
                tbl[k] = unitDir
            elseif kl:find("pos", 1, true) and kl:find("target", 1, true) then
                tbl[k] = targetPos
            end
        elseif type(v) == "table" and typeof(v.value) == "Vector3" then
            if kl:find("dir", 1, true) then
                v.value = unitDir
            elseif kl:find("vel", 1, true) and v.value.Magnitude > 5 then
                v.value = unitDir * v.value.Magnitude
            elseif kl:find("target", 1, true) then
                v.value = targetPos
            end
        end
    end
end

local function installSilentAimHook()
    if silentHookInstalled or not (hookmetamethod and getnamecallmethod) then return end
    silentHookInstalled = true
    local mouse = LP:GetMouse()

    local oldNamecall
    local function namecallHook(self, ...)
        local method = getnamecallmethod()
        if SilentAimState.active and SilentAimState.targetPos and typeof(self) == "Instance"
            and (method == "FireServer" or method == "InvokeServer") then
            local nl = self.Name:lower()
            if nl:find("proj", 1, true) or nl:find("shoot", 1, true) or nl:find("fire", 1, true) or nl:find("bow", 1, true) or nl:find("throw", 1, true) or nl:find("launch", 1, true) then
                local args = table.pack(...)
                local origin = SilentAimState.origin or (cam() and cam().CFrame.Position) or Vector3.zero
                local tpos = SilentAimState.targetPos
                local unitDir = (tpos - origin).Unit
                for i = 1, args.n do
                    local a = args[i]
                    if typeof(a) == "Vector3" then
                        if a.Magnitude > 10 then
                            args[i] = unitDir * a.Magnitude
                        elseif math.abs(a.Magnitude - 1) < 0.08 then
                            args[i] = unitDir
                        end
                    elseif typeof(a) == "CFrame" then
                        args[i] = CFrame.lookAt(a.Position, tpos)
                    elseif type(a) == "table" then
                        redirectVecTable(a, origin, tpos)
                    end
                end
                return oldNamecall(self, table.unpack(args, 1, args.n))
            end
        end
        return oldNamecall(self, ...)
    end
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure and newcclosure(namecallHook) or namecallHook)

    local oldIndex
    local function indexHook(self, key)
        if SilentAimState.active and SilentAimState.targetPos and self == mouse then
            if key == "Hit" then
                return CFrame.new(SilentAimState.targetPos)
            elseif key == "UnitRay" then
                local origin = cam() and cam().CFrame.Position or Vector3.zero
                return Ray.new(origin, (SilentAimState.targetPos - origin).Unit)
            end
        end
        return oldIndex(self, key)
    end
    oldIndex = hookmetamethod(game, "__index", newcclosure and newcclosure(indexHook) or indexHook)
end

local function updateTargetMotion(e, now, trackers)
    local rootPart = e.root
    local pos = rootPart.Position
    local rawVel = rootPart.AssemblyLinearVelocity
    local char = e.model
    local lastDamageTime = typeof(char) == "Instance" and char:GetAttribute("LastDamageTakenTime") or nil
    local isAirborne = e.hum and e.hum.FloorMaterial == Enum.Material.Air

    local tracker = trackers[char]
    if not tracker or tracker.root ~= rootPart or (now - tracker.time) > 0.75 then
        tracker = {
            root = rootPart,
            time = now,
            position = pos,
            velocity = rawVel,
            stable = rawVel,
            samplePos = { pos },
            sampleTime = { now },
            sampleHead = 1,
            sampleCount = 1,
            damageTime = lastDamageTime,
        }
        trackers[char] = tracker
        return tracker
    end

    local dt = now - tracker.time
    if dt <= 1e-4 then return tracker end

    -- Ignore Telepearl / velocity spikes > 260
    local displacement = pos - tracker.position
    local maxAllowedDist = math.max(12, (math.max(tracker.velocity.Magnitude, rawVel.Magnitude) + 30) * dt * 1.5)
    if displacement.Magnitude > maxAllowedDist or rawVel.Magnitude > 260 then
        tracker.position = pos
        tracker.velocity = Vector3.zero
        tracker.time = now
        return tracker
    end

    -- 8-sample ring buffer
    local idx = (tracker.sampleHead + tracker.sampleCount - 1) % 8 + 1
    tracker.samplePos[idx] = pos
    tracker.sampleTime[idx] = now
    tracker.sampleCount += 1

    while tracker.sampleCount > 6 or (tracker.sampleCount > 2 and now - tracker.sampleTime[tracker.sampleHead] > 0.2) do
        tracker.sampleHead = tracker.sampleHead % 8 + 1
        tracker.sampleCount -= 1
    end

    local newestIdx = (tracker.sampleHead + tracker.sampleCount - 2) % 8 + 1
    local sampledVel = rawVel
    if tracker.sampleCount >= 2 then
        local span = tracker.sampleTime[newestIdx] - tracker.sampleTime[tracker.sampleHead]
        if span > 0.02 then
            local v = (tracker.samplePos[newestIdx] - tracker.samplePos[tracker.sampleHead]) / span
            if v.Magnitude <= 260 then sampledVel = v end
        end
    end

    local smoothedVel = rawVel:Lerp(sampledVel, 0.15)
    local finalVel = Vector3.new(smoothedVel.X, rawVel.Y, smoothedVel.Z)

    local tookDamage = (type(lastDamageTime) == "number" and lastDamageTime > 0 and lastDamageTime ~= tracker.damageTime)
    if tookDamage then
        tracker.hitAt = now
        if (finalVel - tracker.velocity).Magnitude > 1.5 then
            tracker.kbBase = tracker.stable
            tracker.kbDecay = isAirborne and 1.8 or 3.5
            tracker.kbStart = now
            tracker.kbUntil = now + 0.6
        end
    end

    local isKnockedBack = tracker.kbUntil and now < tracker.kbUntil
    if not isKnockedBack then tracker.stable = finalVel end

    if finalVel.Magnitude > 5 and not isKnockedBack then
        local dir = finalVel.Unit
        if tracker.turnUnit then
            local crossY = tracker.turnUnit.X * dir.Z - tracker.turnUnit.Z * dir.X
            local angleDiff = math.atan2(crossY, math.clamp(tracker.turnUnit:Dot(dir), -1, 1))
            if math.abs(angleDiff) < 1.4 then
                local rate = angleDiff / dt
                tracker.turnRate = tracker.turnRate and (tracker.turnRate + (rate - tracker.turnRate) * 0.3) or rate
            else
                tracker.turnRate = nil
            end
        end
        tracker.turnUnit = dir
    else
        tracker.turnRate = nil
        tracker.turnUnit = nil
    end

    tracker.damageTime = lastDamageTime
    tracker.position = pos
    tracker.time = now
    tracker.velocity = finalVel
    return tracker
end

PCombat.add({
    name = "Projectile Aimbot",
    settings = function(ui)
        ui.Cycle("mode", "Mode", { "Camera", "Flick", "Silent" }, "Camera")
        ui.Toggle("players", "Players", true)
        ui.Toggle("npcs", "NPCs", true)
        ui.Cycle("part", "Part", { "Head", "Body" }, "Head")
        ui.Slider("fov", "FOV", 5, 180, 75, 1, "%.0f")
        ui.Slider("range", "Range", 20, 300, 150, 5, "%.0f")
        ui.Slider("speed", "Aim speed", 1, 40, 40, 1, "%.0f")
        ui.Toggle("walls", "Ignore behind walls", true)
        ui.Toggle("rangedOnly", "Ranged weapon only", true)
        ui.Toggle("circle", "FOV circle", true)
        ui.Note("Note: 1st person only (pauses in 3rd)")
        ui.Button("Capture shots (6s)", function() captureShots(6) end)
    end,
    enable = function(m, maid)
        local o = m.opt
        if hookmetamethod and getnamecallmethod then installSilentAimHook() end
        maid:give(Entities.acquire())
        local circle = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, OverlayL)
        maid:give(circle)
        corner(circle, 9999)
        make("UIStroke", { Color = T.white, Thickness = 1.5, Transparency = 0.4 }, circle)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local lastBestPos, lastOrigin = nil, nil
        local flickUntil, flickTarget, flickSavedCF = 0, nil, nil
        local wasFirstPerson = true
        local motionTrackers = setmetatable({}, { __mode = "k" })

        -- Flick mode: keep camera free while holding Mouse1, snap for 60ms on release then restore
        maid:give(UserInputService.InputEnded:Connect(function(input)
            if o.mode ~= "Flick" or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not lastBestPos then return end
            local c = cam()
            if not c then return end
            flickSavedCF = c.CFrame
            flickTarget = lastBestPos
            flickUntil = os.clock() + 0.06
            c.CFrame = CFrame.lookAt(flickSavedCF.Position, flickTarget)
        end))

        local id = "WrenchHub.Aimbot"
        RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value + 2, function(dt)
            local c = cam()
            local ch = LP.Character
            if not c or not ch then
                circle.Visible = false
                SilentAimState.active = false
                lastBestPos = nil
                return
            end
            if flickSavedCF then
                if os.clock() < flickUntil and flickTarget then
                    c.CFrame = CFrame.lookAt(c.CFrame.Position, flickTarget)
                    return
                else
                    c.CFrame = flickSavedCF
                    flickSavedCF, flickTarget = nil, nil
                end
            end
            local held = heldName(ch)
            local armed = (not o.rangedOnly) or isRangedWeapon(held)
            local isFirstPerson = (c.CFrame.Position - c.Focus.Position).Magnitude < 1.5
            if not isFirstPerson then
                circle.Visible = false
                SilentAimState.active = false
                lastBestPos = nil
                if wasFirstPerson and armed then
                    Notify("Projectile Aimbot", "Paused in 3rd person (1st person only)", 2)
                end
                wasFirstPerson = false
                return
            end
            wasFirstPerson = true
            circle.Visible = o.circle and armed
            if not armed then
                SilentAimState.active = false
                lastBestPos = nil
                return
            end

            local vp = c.ViewportSize
            local r = math.tan(math.rad(o.fov / 2)) / math.tan(math.rad(c.FieldOfView / 2)) * (vp.Y / 2)
            circle.Size = UDim2.fromOffset(r * 2, r * 2)

            local prof = getProjectileProfile(held)
            local look, origin = c.CFrame.LookVector, c.CFrame.Position
            local now = os.clock()
            local best, bestAng, bestPos
            for _, e in ipairs(Entities.list) do
                if e.dist > o.range then break end
                if not e.friendly and ((e.isDummy and o.npcs) or (not e.isDummy and o.players)) then
                    local tracker = updateTargetMotion(e, now, motionTrackers)
                    local predVel = tracker and tracker.velocity or e.root.AssemblyLinearVelocity
                    local headPart = e.head
                    local part = (o.part == "Head" and headPart) or e.root
                    local basePos = (o.part == "Head" and headPart) and (part.Position + Vector3.new(0, 0.15, 0)) or part.Position
                    local pos = leadAim(origin, basePos, predVel, prof.speed, prof.gravity, tracker, now)
                    local to = pos - origin
                    if to.Magnitude > 0 then
                        local ang = math.deg(math.acos(math.clamp(look:Dot(to.Unit), -1, 1)))
                        if ang <= o.fov / 2 and (not best or ang < bestAng) then
                            local visible = true
                            if o.walls then
                                rp.FilterDescendantsInstances = { ch, e.model, c }
                                local hitRes = workspace:Raycast(origin, part.Position - origin, rp)
                                visible = (not hitRes) or (not hitRes.Instance.CanCollide) or (hitRes.Instance.Transparency >= 0.9)
                            end
                            if visible then best, bestAng, bestPos = e, ang, pos end
                        end
                    end
                end
            end
            if not best then
                SilentAimState.active = false
                lastBestPos = nil
                return
            end
            Targeting.report(best, "ProjectileAimbot")
            lastBestPos, lastOrigin = bestPos, origin
            if o.mode == "Silent" and silentHookInstalled then
                SilentAimState.active = true
                SilentAimState.targetPos = bestPos
                SilentAimState.origin = origin
            elseif o.mode == "Camera" then
                SilentAimState.active = false
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    c.CFrame = c.CFrame:Lerp(CFrame.lookAt(origin, bestPos), 1 - math.exp(-o.speed * dt))
                end
            else
                SilentAimState.active = false
            end
        end)
        maid:give(function()
            RunService:UnbindFromRenderStep(id)
            SilentAimState.active = false
            SilentAimState.targetPos = nil
            lastBestPos = nil
        end)
    end,
})

-- COMBAT : Spin Bot -----------------------------------------------------------
PCombat.add({
    name = "Spin Bot",
    settings = function(ui)
        ui.Slider("speed", "Speed (deg/s)", 30, 2000, 720, 10, "%.0f")
        ui.Cycle("dir", "Direction", { "Left", "Right" }, "Left")
    end,
    enable = function(m, maid)
        local touched = setmetatable({}, { __mode = "k" })
        maid:give(RunService.Stepped:Connect(function(_, dt)
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.Health <= 0 then return end
            if touched[hum] == nil then touched[hum] = hum.AutoRotate end
            if hum.AutoRotate then hum.AutoRotate = false end
            if hum.Sit then return end
            local sgn = m.opt.dir == "Right" and -1 or 1
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(m.opt.speed * dt) * sgn, 0)
        end))
        maid:give(function()
            for hum, original in pairs(touched) do
                if hum.Parent then hum.AutoRotate = original end
            end
        end)
    end,
})

--------------------------------------------------------------------------------
-- RENDER : Player ESP (4 layers: Kit, Item/Armor, Enchant, Box2D/3D + Maid)
--------------------------------------------------------------------------------
PRender.add({
    name = "Player ESP",
    settings = function(ui)
        ui.Cycle("color", "Color", { "Team", "Red", "Cyan", "White" }, "Team")
        ui.Slider("npcRange", "NPC range", 20, 300, 100, 10, "%.0f")
        ui.Slider("max", "Max players", 5, 25, 25, 1, "%.0f")
        ui.Toggle("highlight", "Highlight", true)
        ui.Toggle("boxes", "2D Boxes", false)
        ui.Toggle("hitbox3d", "3D Hitbox", false)
        ui.Toggle("names", "Names", true)
        ui.Toggle("health", "Health bar", true)
        ui.Toggle("info", "HP and distance", true)
        ui.Toggle("team", "Teammates", false)
        ui.Toggle("dummies", "Dummies", false)
        ui.Toggle("mark", "Mark fight target", true)
    end,
    enable = function(m, maid)
        local o = m.opt
        local root = make("Frame", { Name = "ESP", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, OverlayL)
        local box3dFolder = make("Folder", { Name = "WrenchHub_Hitboxes" }, OverlayL)
        local hlFolder = make("Folder", { Name = "WrenchHub_Highlights" }, OverlayL)
        maid:give(root)
        maid:give(box3dFolder)
        maid:give(hlFolder)
        maid:give(Entities.acquire())
        local pool, frame = {}, 0

        local function newRec()
            local r = {}
            r.outline = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, root)
            make("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.45 }, r.outline)
            r.box = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2 }, root)
            r.stroke = make("UIStroke", { Thickness = 1.5, Color = T.white }, r.box)
            r.name = text(root, "", 12, T.white, Center)
            r.name.AnchorPoint, r.name.Size, r.name.Visible, r.name.ZIndex = Vector2.new(0.5, 1), UDim2.fromOffset(180, 14), false, 3
            r.name.TextStrokeTransparency = 0.4
            r.info = text(root, "", 11, T.white, Center)
            r.info.AnchorPoint, r.info.Size, r.info.Visible, r.info.ZIndex = Vector2.new(0.5, 0), UDim2.fromOffset(180, 14), false, 3
            r.info.TextStrokeTransparency = 0.4
            r.hbg = make("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, ZIndex = 2 }, root)
            r.hfill = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 3 }, r.hbg)

            local box3d = Instance.new("BoxHandleAdornment")
            box3d.Name = "PlayerBox"
            box3d.AlwaysOnTop = true
            box3d.ZIndex = 0
            box3d.Size = Vector3.new(3, 5, 3)
            box3d.CFrame = CFrame.new(0, -0.5, 0)
            box3d.Transparency = 0.72
            box3d.Visible = false
            box3d.Parent = box3dFolder
            r.box3d = box3d

            local hl = Instance.new("Highlight")
            hl.Name = "PlayerHL"
            hl.FillTransparency = 0.55
            hl.OutlineColor = T.white
            hl.OutlineTransparency = 0.1
            hl.Enabled = false
            hl.Parent = hlFolder
            r.hl = hl

            r.parts = { r.outline, r.box, r.name, r.info, r.hbg, r.box3d, r.hl }
            return r
        end

        local function setVis(r, v)
            if r.vis == v then return end
            r.vis = v
            for _, p in ipairs(r.parts) do
                if p:IsA("Highlight") then p.Enabled = v else p.Visible = v end
            end
        end

        -- Track PlayerAdded cleanly via Maid so toggling off leaves zero leaks
        maid:give(Players.PlayerAdded:Connect(function(p)
            maid:give(p.CharacterAdded:Connect(function() end))
        end))

        local id = "WrenchHub.ESP"
        RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
            frame += 1
            local c = cam()
            if not c then return end
            local half = Config.BoxSize / 2
            local drawn = 0
            local hlCount = 0
            for _, e in ipairs(Entities.list) do
                if drawn >= o.max then break end
                local inRange = (not e.isDummy) or (e.dist <= o.npcRange)
                if inRange and (o.team or not e.friendly) and (o.dummies or not e.isDummy) then
                    local need2D = o.boxes or o.names or o.info or o.health
                    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                    local ok = true
                    if need2D then
                        local p = e.root.Position
                        if o.boxes then
                            for ix = 1, 2 do
                                for iy = 1, 2 do
                                    for iz = 1, 2 do
                                        local v = c:WorldToViewportPoint(p + Vector3.new(SIGNS[ix] * half.X, SIGNS[iy] * half.Y, SIGNS[iz] * half.Z))
                                        if v.Z <= 0 then ok = false end
                                        if v.X < minX then minX = v.X end
                                        if v.X > maxX then maxX = v.X end
                                        if v.Y < minY then minY = v.Y end
                                        if v.Y > maxY then maxY = v.Y end
                                    end
                                end
                            end
                        else
                            local vt = c:WorldToViewportPoint(p + Vector3.new(0, half.Y, 0))
                            local vb = c:WorldToViewportPoint(p - Vector3.new(0, half.Y, 0))
                            if vt.Z <= 0 or vb.Z <= 0 then
                                ok = false
                            else
                                local h = math.max(vb.Y - vt.Y, 12)
                                local w = h * 0.6
                                minX, maxX = vt.X - w / 2, vt.X + w / 2
                                minY, maxY = vt.Y, vb.Y
                            end
                        end
                    end
                    if ok and ((not need2D) or (maxX > minX and maxY > minY)) then
                        local r = pool[e.model]
                        if not r then r = newRec() pool[e.model] = r end
                        r.seen = frame
                        drawn += 1
                        setVis(r, true)
                        local col = entColor(e, o.color, o.mark)

                        if need2D then
                            local w, h = maxX - minX, maxY - minY
                            r.box.Visible, r.outline.Visible = o.boxes, o.boxes
                            if o.boxes then
                                r.box.Position = UDim2.fromOffset(minX, minY)
                                r.box.Size = UDim2.fromOffset(w, h)
                                r.outline.Position, r.outline.Size = r.box.Position, r.box.Size
                                r.stroke.Color = col
                            end

                            r.name.Visible = o.names
                            if o.names then
                                if r.lastName ~= e.name then r.name.Text = e.name r.lastName = e.name end
                                r.name.TextColor3 = col
                                r.name.Position = UDim2.fromOffset(minX + w / 2, minY - 2)
                            end

                            r.info.Visible = o.info
                            if o.info then
                                local infoTxt = string.format("%d HP  %dm", math.ceil(e.hum.Health), math.floor(e.dist))
                                if r.lastInfo ~= infoTxt then r.info.Text = infoTxt r.lastInfo = infoTxt end
                                r.info.TextColor3 = col
                                r.info.Position = UDim2.fromOffset(minX + w / 2, maxY + 2)
                            end

                            r.hbg.Visible = o.health
                            if o.health then
                                local pct = math.clamp(e.hum.Health / math.max(e.hum.MaxHealth, 1), 0, 1)
                                r.hbg.Position = UDim2.fromOffset(minX - 6, minY)
                                r.hbg.Size = UDim2.fromOffset(3, h)
                                r.hfill.Size = UDim2.fromScale(1, pct)
                                r.hfill.BackgroundColor3 = Color3.fromRGB(245, 65, 65):Lerp(T.good, pct)
                            end
                        else
                            r.box.Visible, r.outline.Visible, r.name.Visible, r.info.Visible, r.hbg.Visible = false, false, false, false, false
                        end

                        r.box3d.Visible = o.hitbox3d
                        if o.hitbox3d then
                            if r.box3d.Adornee ~= e.root then r.box3d.Adornee = e.root end
                            r.box3d.Color3 = col
                        elseif r.box3d.Adornee ~= nil then
                            r.box3d.Adornee = nil
                        end

                        local useHL = o.highlight and hlCount < 16
                        if useHL then
                            hlCount += 1
                            if not r.hl.Enabled then r.hl.Enabled = true end
                            if r.hl.Adornee ~= e.model then r.hl.Adornee = e.model end
                            if r.hl.FillColor ~= col then r.hl.FillColor = col end
                        else
                            if r.hl.Enabled then r.hl.Enabled = false end
                            if r.hl.Adornee ~= nil then r.hl.Adornee = nil end
                        end
                    end
                end
            end
            for model, r in pairs(pool) do
                if r.seen ~= frame then setVis(r, false) r.box3d.Adornee = nil r.hl.Adornee = nil r.hl.Enabled = false end
                if not Entities.byModel[model] then
                    for _, part in ipairs(r.parts) do part:Destroy() end
                    pool[model] = nil
                end
            end
        end)
        maid:give(function() RunService:UnbindFromRenderStep(id) end)
    end,
})

-- RENDER : Tracers ------------------------------------------------------------
PRender.add({
    name = "Tracers",
    settings = function(ui)
        ui.Cycle("origin", "Origin", { "Bottom", "Center", "Mouse" }, "Bottom")
        ui.Cycle("anchor", "Aim at", { "Body", "Head" }, "Body")
        ui.Cycle("color", "Color", { "Team", "Red", "Cyan", "White" }, "Team")
        ui.Slider("thick", "Thickness", 1, 4, 1.5, 0.5, "%.1f")
        ui.Slider("range", "Range", 50, 500, 300, 10, "%.0f")
        ui.Toggle("team", "Teammates", false)
        ui.Toggle("dummies", "Dummies", false)
        ui.Toggle("mark", "Mark fight target", true)
    end,
    enable = function(m, maid)
        local o = m.opt
        local root = make("Frame", { Name = "Tracers", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, OverlayL)
        maid:give(root)
        maid:give(Entities.acquire())
        local pool, frame = {}, 0
        local id = "WrenchHub.Tracers"
        RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
            frame += 1
            local c = cam()
            if not c then return end
            local vp = c.ViewportSize
            local center = Vector2.new(vp.X / 2, vp.Y / 2)
            local origin = center
            if o.origin == "Bottom" then origin = Vector2.new(vp.X / 2, vp.Y)
            elseif o.origin == "Mouse" then origin = UserInputService:GetMouseLocation() end
            for _, e in ipairs(Entities.list) do
                if e.dist <= o.range and (o.team or not e.friendly) and (o.dummies or not e.isDummy) then
                    local part = (o.anchor == "Head" and e.model:FindFirstChild("Head")) or e.root
                    local wp = part.Position
                    local v = c:WorldToViewportPoint(wp)
                    local pt
                    if v.Z > 0 then
                        pt = Vector2.new(v.X, v.Y)
                    else
                        local rel = c.CFrame:PointToObjectSpace(wp)
                        local dir = Vector2.new(rel.X, -rel.Y)
                        if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
                        dir = dir.Unit
                        local hx, hy = vp.X / 2 - 20, vp.Y / 2 - 20
                        local k = math.min(hx / math.max(math.abs(dir.X), 1e-3), hy / math.max(math.abs(dir.Y), 1e-3))
                        pt = center + dir * k
                    end
                    local d = pt - origin
                    local len = d.Magnitude
                    if len > 2 then
                        local line = pool[e.model]
                        if not line then
                            line = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0.15 }, root)
                            pool[e.model] = line
                        end
                        line.Visible = true
                        line.Size = UDim2.fromOffset(len, o.thick)
                        line.Position = UDim2.fromOffset(origin.X + d.X / 2, origin.Y + d.Y / 2)
                        line.Rotation = math.deg(math.atan2(d.Y, d.X))
                        line.BackgroundColor3 = entColor(e, o.color, o.mark)
                        line:SetAttribute("seen", frame)
                    end
                end
            end
            for model, line in pairs(pool) do
                if line:GetAttribute("seen") ~= frame then line.Visible = false end
                if not Entities.byModel[model] then line:Destroy() pool[model] = nil end
            end
        end)
        maid:give(function() RunService:UnbindFromRenderStep(id) end)
    end,
})

-- RENDER : Target Info (1.5s ranged aim hold, Glassmorphism card) -------------
PRender.add({
    name = "Target Info",
    settings = function(ui)
        ui.Slider("range", "Fight range", 8, 30, 18, 1, "%.0f")
        ui.Slider("aimRange", "Aim range", 30, 300, 220, 10, "%.0f")
        ui.Slider("aimFov", "Aim FOV", 5, 60, 30, 1, "%.0f")
        ui.Slider("hide", "Hide delay (s)", 1, 8, 3, 0.5, "%.1f")
        ui.Toggle("aim", "Far aim detect", true)
        ui.Toggle("aimRangedOnly", "Ranged weapon only", false)
        ui.Toggle("dummies", "Dummies and NPCs", true)
        ui.Toggle("display", "Use display name", true)
        ui.Slider("trans", "Transparency", 0, 0.9, 0.72, 0.05, "%.2f")
    end,
    enable = function(m, maid)
        local o = m.opt
        if not Card then Card = buildCard() end
        local C = Card
        maid:give(Entities.acquire())
        local hpMem = setmetatable({}, { __mode = "k" })
        local cur, myHp, scanT = nil, nil, 0
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude

        local function newCur(e)
            return {
                model = e.model, hum = e.hum, root = e.root,
                name = (o.display and e.player and e.player.DisplayName) or e.name,
                player = e.player, isDummy = e.isDummy,
                soft = false, lastHard = 0, expiry = 0, deadAt = nil,
            }
        end

        local id = "WrenchHub.TargetInfo"
        RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
            local now = os.clock()
            local c = cam()
            if not c then return end
            local myChar = LP.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local look, origin = c.CFrame.LookVector, c.CFrame.Position
            local holdingRanged = (not o.aimRangedOnly) or isRangedWeapon(heldName(myChar))

            local hit, hitD, aim, aimAng = nil, math.huge, nil, math.huge
            for _, e in ipairs(Entities.list) do
                local hp = e.hum.Health
                local prev = hpMem[e.hum]
                hpMem[e.hum] = hp
                if myRoot and not e.friendly and (o.dummies or not e.isDummy) then
                    local d = e.dist
                    if prev and hp < prev - 0.01 and d <= o.range then
                        local to = e.root.Position - myRoot.Position
                        if d <= 7 or (to.Magnitude > 0 and to.Unit:Dot(look) > 0.35) then
                            if d < hitD then hit, hitD = e, d end
                        end
                    elseif o.aim and holdingRanged and d <= o.aimRange then
                        local headPart = e.head
                        local aimPos = headPart and headPart.Position or (e.root.Position + Vector3.new(0, 1.5, 0))
                        local to = aimPos - origin
                        if to.Magnitude > 0 then
                            local ang = math.deg(math.acos(math.clamp(look:Dot(to.Unit), -1, 1)))
                            if ang <= (o.aimFov / 2) and ang < aimAng then
                                rp.FilterDescendantsInstances = { myChar, e.model, c }
                                local hitRes = workspace:Raycast(origin, aimPos - origin, rp)
                                if not hitRes or not hitRes.Instance.CanCollide or hitRes.Instance.Transparency >= 0.9 then
                                    aim, aimAng = e, ang
                                end
                            end
                        end
                    end
                end
            end

            local myHpNow = myHum and myHum.Health
            if myHpNow and myHp and myHpNow < myHp - 0.01 and not hit and myRoot then
                local best, bd = nil, 14
                for _, e in ipairs(Entities.list) do
                    if not e.friendly and not e.isDummy and e.dist <= bd then
                        local to = myRoot.Position - e.root.Position
                        if to.Magnitude > 0 and e.root.CFrame.LookVector:Dot(to.Unit) > 0.5 then best, bd = e, e.dist end
                    end
                end
                hit = best
            end
            myHp = myHpNow

            local forced = false
            local L = Targeting.last
            if L and now - L.t < 0.5 then
                local fe = Entities.byModel[L.model]
                if fe and not fe.friendly then hit, forced = fe, true end
            end

            if hit then
                if (not cur) or forced or cur.model == hit.model or cur.soft or now - cur.lastHard > 0.8 then
                    if not cur or cur.model ~= hit.model then
                        cur = newCur(hit)
                        C.bind(cur)
                    end
                    cur.soft, cur.lastHard, cur.expiry, cur.deadAt = false, now, now + o.hide, nil
                end
            elseif aim then
                if (not cur) or cur.soft then
                    if not cur or cur.model ~= aim.model then
                        cur = newCur(aim)
                        cur.soft = true
                        C.bind(cur)
                    end
                    cur.expiry = now + 1.5 -- hold 1.5s after leaving aim
                end
            end

            if cur then
                local e = Entities.byModel[cur.model]
                if cur.hum.Health <= 0 and not cur.deadAt then
                    cur.deadAt = now
                    cur.expiry = now + 1.2
                end
                local maxDist = cur.soft and (o.aimRange * 1.2) or (o.range * 1.5)
                if (not e and not cur.deadAt) or now > cur.expiry or (e and e.dist > maxDist) then
                    cur = nil
                end
            end

            TargetState.model = cur and cur.model or nil
            if cur then
                C.show.to(1)
                local e = Entities.byModel[cur.model]
                C.update(cur, e and e.dist or nil, now)
                C.card.BackgroundTransparency = o.trans
                if now - scanT > 0.2 then
                    scanT = now
                    local armor, held = readLoadout(cur.model, cur.isDummy)
                    local enchImg = enchantImage(cur.model)
                    C.setLoadout(armor, held, enchImg, cur.model)
                end
            else
                C.show.to(0)
            end
        end)
        maid:give(function()
            RunService:UnbindFromRenderStep(id)
            TargetState.model = nil
            C.show.to(0)
        end)
    end,
})

-- RENDER : Block ESP (020_ID_13717_LogicBlock: Bed, LuckyBlock, Traps, Ore) --
PRender.add({
    name = "Block ESP",
    settings = function(ui)
        ui.Slider("range", "Range", 30, 500, 220, 10, "%.0f")
        ui.Toggle("beds", "Beds", true)
        ui.Toggle("lucky", "Lucky Blocks", true)
        ui.Toggle("traps", "Traps", true)
        ui.Toggle("ores", "Iron Ore", false)
    end,
    enable = function(m, maid)
        local o = m.opt
        local hlFolder = make("Folder", { Name = "WrenchHub_BlockESP" }, OverlayL)
        maid:give(hlFolder)
        local tracked = {}
        local BLOCK_DEFS = {
            { tag = "bed", opt = "beds", col = Color3.fromRGB(235, 65, 65) },
            { tag = "LuckyBlock", opt = "lucky", col = Color3.fromRGB(245, 200, 45) },
            { tag = "tesla-trap", opt = "traps", col = Color3.fromRGB(165, 85, 245) },
            { tag = "beehive", opt = "traps", col = Color3.fromRGB(245, 165, 45) },
            { tag = "iron_ore_mesh_block", opt = "ores", col = Color3.fromRGB(205, 210, 220) },
        }

        local function addObj(inst, def)
            if tracked[inst] or not inst:IsDescendantOf(workspace) then return end
            local hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0.1
            hl.FillColor = def.col
            hl.OutlineColor = def.col
            hl.Adornee = inst
            hl.Enabled = false
            hl.Parent = hlFolder
            tracked[inst] = { hl = hl, def = def }
        end

        for _, def in ipairs(BLOCK_DEFS) do
            for _, inst in ipairs(CollectionService:GetTagged(def.tag)) do addObj(inst, def) end
            maid:give(CollectionService:GetInstanceAddedSignal(def.tag):Connect(function(inst) addObj(inst, def) end))
            maid:give(CollectionService:GetInstanceRemovedSignal(def.tag):Connect(function(inst)
                local rec = tracked[inst]
                if rec then rec.hl:Destroy() tracked[inst] = nil end
            end))
        end

        local acc = 0
        maid:give(RunService.Heartbeat:Connect(function(dt)
            acc += dt
            if acc < 0.25 then return end
            acc = 0
            local ch = LP.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local myPos = root and root.Position
            local activeCount = 0
            for inst, rec in pairs(tracked) do
                if not inst.Parent then
                    rec.hl:Destroy()
                    tracked[inst] = nil
                else
                    local show = o[rec.def.opt] and activeCount < 20
                    if show and myPos then
                        local pos = inst:IsA("BasePart") and inst.Position or inst:GetPivot().Position
                        if (pos - myPos).Magnitude > o.range then show = false end
                    end
                    if show then activeCount += 1 end
                    if rec.hl.Enabled ~= show then rec.hl.Enabled = show end
                end
            end
        end))
    end,
})

-- RENDER : Fullbright ---------------------------------------------------------
PRender.add({
    name = "Fullbright",
    enable = function(m, maid)
        local saved = { Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
        local function apply()
            Lighting.Brightness = 2
            Lighting.FogEnd = 1e5
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        end
        apply()
        maid:give(RunService.Heartbeat:Connect(apply))
        maid:give(function()
            for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
        end)
    end,
})

-- RENDER : FPS Boost (FPSBooster.lua + MemoryFixer.lua) -----------------------
local BlockColors = {
    grass = Color3.fromRGB(88, 152, 60),
    spirit_grass = Color3.fromRGB(104, 148, 168),
    void_grass = Color3.fromRGB(96, 72, 128),
    moss_block = Color3.fromRGB(76, 124, 60),
    dirt = Color3.fromRGB(122, 88, 60),
    void_dirt = Color3.fromRGB(72, 56, 88),
    void_growth = Color3.fromRGB(88, 64, 112),
    sand = Color3.fromRGB(219, 205, 155),
    red_sand = Color3.fromRGB(184, 108, 68),
    snow = Color3.fromRGB(238, 244, 248),
    ice = Color3.fromRGB(172, 208, 232),
    clay = Color3.fromRGB(160, 160, 172),
    stone = Color3.fromRGB(126, 126, 126),
    cobblestone = Color3.fromRGB(112, 112, 112),
    stone_brick = Color3.fromRGB(122, 122, 122),
    stone_brick_builder = Color3.fromRGB(122, 122, 122),
    stone_pillar = Color3.fromRGB(130, 130, 130),
    stone_slab = Color3.fromRGB(130, 130, 130),
    stone_tiles = Color3.fromRGB(118, 118, 118),
    slate_brick = Color3.fromRGB(84, 88, 96),
    slate_tiles = Color3.fromRGB(78, 82, 90),
    andesite = Color3.fromRGB(136, 136, 136),
    andesite_polished = Color3.fromRGB(148, 148, 148),
    diorite = Color3.fromRGB(206, 206, 206),
    diorite_polished = Color3.fromRGB(216, 216, 216),
    granite = Color3.fromRGB(154, 106, 88),
    granite_polished = Color3.fromRGB(166, 116, 96),
    marble = Color3.fromRGB(226, 226, 222),
    marble_pillar = Color3.fromRGB(232, 232, 228),
    obsidian = Color3.fromRGB(38, 32, 52),
    volatile_stone = Color3.fromRGB(96, 88, 96),
    void_block = Color3.fromRGB(48, 36, 68),
    sandstone = Color3.fromRGB(216, 202, 152),
    sandstone_polished = Color3.fromRGB(222, 210, 162),
    sandstone_smooth = Color3.fromRGB(226, 214, 168),
    red_sandstone = Color3.fromRGB(178, 104, 62),
    red_sandstone_polished = Color3.fromRGB(184, 112, 70),
    red_sandstone_smooth = Color3.fromRGB(188, 118, 76),
    oak_log = Color3.fromRGB(106, 82, 50),
    birch_log = Color3.fromRGB(198, 188, 158),
    spruce_log = Color3.fromRGB(78, 58, 34),
    maple_log = Color3.fromRGB(120, 76, 48),
    hickory_log = Color3.fromRGB(112, 88, 56),
    wood_plank_oak = Color3.fromRGB(162, 130, 78),
    wood_plank_oak_builder = Color3.fromRGB(162, 130, 78),
    wood_plank_birch = Color3.fromRGB(214, 200, 160),
    wood_plank_spruce = Color3.fromRGB(104, 78, 48),
    wood_plank_maple = Color3.fromRGB(150, 96, 62),
    wood_plank_hickory = Color3.fromRGB(140, 112, 74),
    bookshelf = Color3.fromRGB(152, 122, 74),
    cherry_foliage = Color3.fromRGB(226, 154, 190),
    spirit_foliage = Color3.fromRGB(120, 168, 176),
    brick = Color3.fromRGB(150, 96, 80),
    galactite_brick = Color3.fromRGB(96, 108, 156),
    galactite = Color3.fromRGB(88, 100, 148),
    ceramic = Color3.fromRGB(196, 176, 152),
    iron_block = Color3.fromRGB(206, 206, 206),
    iron_ore_mesh_block = Color3.fromRGB(178, 168, 158),
    steel_block = Color3.fromRGB(160, 166, 172),
    guilded_iron = Color3.fromRGB(202, 178, 118),
    gold_block = Color3.fromRGB(238, 202, 82),
    copper_block = Color3.fromRGB(190, 114, 76),
    diamond_block = Color3.fromRGB(108, 216, 214),
    emerald_block = Color3.fromRGB(74, 190, 108),
    clay_white = Color3.fromRGB(226, 222, 214),
    clay_black = Color3.fromRGB(48, 44, 44),
    clay_gray = Color3.fromRGB(126, 122, 118),
    clay_red = Color3.fromRGB(166, 74, 62),
    clay_orange = Color3.fromRGB(198, 122, 58),
    clay_yellow = Color3.fromRGB(214, 184, 76),
    clay_green = Color3.fromRGB(108, 158, 72),
    clay_dark_green = Color3.fromRGB(76, 112, 56),
    clay_light_green = Color3.fromRGB(140, 190, 100),
    clay_blue = Color3.fromRGB(88, 118, 178),
    clay_purple = Color3.fromRGB(126, 88, 158),
    clay_pink = Color3.fromRGB(212, 142, 168),
    clay_tan = Color3.fromRGB(196, 166, 126),
    clay_light_brown = Color3.fromRGB(164, 128, 90),
    clay_dark_brown = Color3.fromRGB(110, 82, 58),
    glass = Color3.fromRGB(196, 220, 232),
    magic_glass = Color3.fromRGB(178, 200, 232),
    concrete_green = Color3.fromRGB(84, 140, 72),
    slime_block = Color3.fromRGB(126, 194, 104),
    melon = Color3.fromRGB(112, 158, 62),
    wool_builder = Color3.fromRGB(228, 228, 228),
}
local LagEffects = {
    "base_weather_particle_controller",
    "drill_tablet_controller",
    "paint_shotgun_effects_controller",
    "carrot_cannon_effects_controller",
    "RbxCharacterSounds",
    "dodo_bird_animation_controller",
}

PRender.add({
    name = "FPS Boost",
    settings = function(ui)
        ui.Toggle("lights", "Remove lights", true)
        ui.Toggle("explosions", "Remove explosions", true)
        ui.Toggle("effects", "Remove particles", true)
        ui.Toggle("blocks", "Simplify blocks", true)
        ui.Toggle("potato", "Potato mode", false)
        ui.Toggle("memfix", "Disable lag conns", true)
        ui.Toggle("hideNametags", "Hide game nametags", false)
        ui.Toggle("killEffects", "Disable kill effects", true)
    end,
    enable = function(m, maid)
        local o = m.opt
        local savedProps = {}
        local function saveProp(inst, prop, newVal)
            local ok, curVal = pcall(function() return inst[prop] end)
            if ok and curVal ~= newVal then
                if not savedProps[inst] then savedProps[inst] = {} end
                if savedProps[inst][prop] == nil then savedProps[inst][prop] = curVal end
                pcall(function() inst[prop] = newVal end)
            end
        end

        local mapFolder = workspace:FindFirstChild("Map")
        local function optimizeInst(inst)
            if inst:IsA("Light") and o.lights then
                saveProp(inst, "Enabled", false)
            elseif inst:IsA("Explosion") and o.explosions then
                saveProp(inst, "Visible", false)
            elseif (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")) and o.effects then
                if not inst:GetAttribute("WrenchHubSelf") then
                    saveProp(inst, "Enabled", false)
                end
            elseif o.blocks and mapFolder and inst:IsDescendantOf(mapFolder) then
                if inst:IsA("BasePart") then
                    saveProp(inst, "Reflectance", 0)
                    saveProp(inst, "CastShadow", false)
                    if o.potato and inst:IsA("MeshPart") then
                        saveProp(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
                    end
                    local flatCol = BlockColors[inst.Name]
                    if flatCol then
                        saveProp(inst, "MaterialVariant", "")
                        saveProp(inst, "Material", Enum.Material.SmoothPlastic)
                        saveProp(inst, "Color", flatCol)
                    end
                elseif (inst:IsA("Texture") or inst:IsA("Decal")) and inst.Parent and BlockColors[inst.Parent.Name] then
                    saveProp(inst, "Transparency", 1)
                end
            end
            if o.hideNametags and inst:IsA("BillboardGui") and not inst:IsDescendantOf(Gui) then
                local p = inst.Parent
                if p and (p.Name == "Head" or p.Name == "HumanoidRootPart" or (p.Parent and p.Parent:FindFirstChildOfClass("Humanoid"))) then
                    saveProp(inst, "Enabled", false)
                end
            end
        end

        for _, d in ipairs(workspace:GetDescendants()) do optimizeInst(d) end
        maid:give(workspace.DescendantAdded:Connect(optimizeInst))

        local disabledConns = {}
        if o.memfix and type(getconnections) == "function" then
            local signals = { RunService.Heartbeat, RunService.PreSimulation, RunService.RenderStepped, RunService.Stepped }
            for _, sig in ipairs(signals) do
                local ok, conns = pcall(getconnections, sig)
                if ok and conns then
                    for _, conn in ipairs(conns) do
                        if type(conn.Function) == "function" then
                            local iok, src = pcall(function() return debug.getinfo(conn.Function).source end)
                            if iok and type(src) == "string" then
                                local ls = src:lower():gsub("-", "_")
                                for _, targetName in ipairs(LagEffects) do
                                    if ls:find(targetName:lower():gsub("-", "_"), 1, true) then
                                        pcall(function() conn:Disable() end)
                                        disabledConns[#disabledConns + 1] = conn
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local savedKillEffects, savedViz = {}, {}
        if o.killEffects and type(_G.bedwars) == "table" then
            pcall(function()
                local kec = _G.bedwars.KillEffectController
                if kec and type(kec.killEffects) == "table" then
                    for k, v in pairs(kec.killEffects) do
                        if not tostring(k):find("Custom") then
                            savedKillEffects[k] = v
                            kec.killEffects[k] = { new = function() return { onKill = function() end, isPlayDefaultKillEffect = function() return true end } end }
                        end
                    end
                end
                local viz = _G.bedwars.VisualizerUtils
                if type(viz) == "table" then
                    for k, v in pairs(viz) do savedViz[k] = v viz[k] = function() end end
                end
            end)
        end

        maid:give(function()
            for inst, props in pairs(savedProps) do
                if inst and inst.Parent then
                    for p, v in pairs(props) do pcall(function() inst[p] = v end) end
                end
            end
            for _, conn in ipairs(disabledConns) do pcall(function() conn:Enable() end) end
            if type(_G.bedwars) == "table" then
                pcall(function()
                    local kec = _G.bedwars.KillEffectController
                    if kec and type(kec.killEffects) == "table" then
                        for k, v in pairs(savedKillEffects) do kec.killEffects[k] = v end
                    end
                    local viz = _G.bedwars.VisualizerUtils
                    if type(viz) == "table" then
                        for k, v in pairs(savedViz) do viz[k] = v end
                    end
                end)
            end
        end)
    end,
})

--------------------------------------------------------------------------------
-- HUD helpers & modules
--------------------------------------------------------------------------------
local function makeDraggable(frame)
    frame.InputBegan:Connect(function(i)
        if isPress(i) then
            local start, base = i.Position, frame.Position
            dragFn = function(inp)
                local d = inp.Position - start
                frame.Position = UDim2.new(base.X.Scale, base.X.Offset + d.X, base.Y.Scale, base.Y.Offset + d.Y)
            end
        end
    end)
end

PHud.add({
    name = "Stats",
    settings = function(ui)
        ui.Toggle("fps", "FPS", true)
        ui.Toggle("ping", "Ping", true)
        ui.Toggle("mem", "Memory", true)
    end,
    enable = function(m, maid)
        local o = m.opt
        local f = make("Frame", { Position = UDim2.new(1, -166, 0, 225), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Active = true }, HudL)
        maid:give(f)
        corner(f, 8)
        make("UIStroke", { Color = T.white, Thickness = 1.5, Transparency = 0.2 }, f)
        local label = text(f, "", 13, T.white, Left, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 1, -12))
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextTruncate = Enum.TextTruncate.None
        makeDraggable(f)
        local frames, acc = 0, 0
        maid:give(RunService.RenderStepped:Connect(function(dt)
            frames += 1
            acc += dt
            if acc < 0.5 then return end
            local fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
            local lines = {}
            if o.fps then lines[#lines + 1] = "FPS  " .. fps end
            if o.ping then
                local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                if ok and v then lines[#lines + 1] = string.format("PING %dms", math.floor(v + 0.5)) end
            end
            if o.mem then lines[#lines + 1] = string.format("MEM  %dMB", math.floor(StatsService:GetTotalMemoryUsageMb() + 0.5)) end
            label.Text = table.concat(lines, "\n")
            f.Size = UDim2.fromOffset(150, math.max(#lines, 1) * 16 + 12)
        end))
    end,
})

PHud.add({
    name = "Keystrokes",
    enable = function(m, maid)
        local root = make("Frame", { Position = UDim2.new(0, 16, 1, -118), Size = UDim2.fromOffset(112, 96), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, HudL)
        maid:give(root)
        local defs = {
            { Enum.KeyCode.W, "W", 40, 0, 32, 32 },
            { Enum.KeyCode.A, "A", 0, 36, 32, 32 },
            { Enum.KeyCode.S, "S", 40, 36, 32, 32 },
            { Enum.KeyCode.D, "D", 80, 36, 32, 32 },
            { Enum.KeyCode.Space, "SPACE", 0, 72, 112, 24 },
        }
        local anims, prev = {}, {}
        for i, d in ipairs(defs) do
            local f = make("Frame", { Position = UDim2.fromOffset(d[3], d[4]), Size = UDim2.fromOffset(d[5], d[6]), BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, root)
            corner(f, 6)
            make("UIStroke", { Color = T.white, Thickness = 1.5, Transparency = 0.3 }, f)
            text(f, d[2], 13, T.white, Center)
            anims[i] = Anim.new(0, 28, function(v) f.BackgroundColor3 = T.bg:Lerp(T.accent, v) end)
            prev[i] = false
        end
        makeDraggable(root)
        maid:give(RunService.RenderStepped:Connect(function()
            for i, d in ipairs(defs) do
                local down = UserInputService:IsKeyDown(d[1])
                if down ~= prev[i] then
                    prev[i] = down
                    anims[i].to(down and 1 or 0)
                end
            end
        end))
    end,
})

PHud.add({
    name = "Mod Overlay",
    enable = function(m, maid)
        local label = text(HudL, "", 14, T.white, Right, UDim2.new(1, -16, 0, 216), UDim2.fromOffset(220, 150))
        label.AnchorPoint = Vector2.new(1, 1)
        label.TextYAlignment = Enum.TextYAlignment.Bottom
        label.TextTruncate = Enum.TextTruncate.None
        label.TextStrokeTransparency = 0.5
        label.Active = true
        makeDraggable(label)
        maid:give(label)
        local acc = 0
        maid:give(RunService.RenderStepped:Connect(function(dt)
            acc += dt
            if acc < 0.25 then return end
            acc = 0
            local names = {}
            for _, mod in ipairs(Modules) do
                if mod.enabled and mod ~= m then names[#names + 1] = mod.name:upper() end
            end
            table.sort(names, function(a, b) return #a > #b end)
            label.Text = table.concat(names, "\n")
        end))
    end,
})

--------------------------------------------------------------------------------
-- MOVEMENT : NoSlow & Velocity / Speed
--------------------------------------------------------------------------------
PMovement.add({
    name = "NoSlow",
    settings = function(ui)
        ui.Slider("minSpeed", "Min walkspeed", 16, 26, 20, 1, "%.0f")
    end,
    enable = function(m, maid)
        local o = m.opt
        maid:give(RunService.Heartbeat:Connect(function()
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.WalkSpeed < o.minSpeed then
                hum.WalkSpeed = o.minSpeed
            end
        end))
    end,
})

PMovement.add({
    name = "Velocity / Speed",
    settings = function(ui)
        ui.Toggle("velEnabled", "Anti-Knockback", true)
        ui.Slider("horizMult", "Horiz mult", 0, 1, 0, 0.1, "%.1f")
        ui.Slider("vertMult", "Vert mult", 0, 1, 0, 0.1, "%.1f")
        ui.Toggle("speedEnabled", "Speed", true)
        ui.Slider("speedVal", "Speed", 16, 45, 24, 1, "%.0f")
        ui.Toggle("antifall", "Anti-Fall", true)
        ui.Slider("fallY", "Fall Y limit", -120, 0, -40, 5, "%.0f")
    end,
    enable = function(m, maid)
        local o = m.opt
        local lastHp, safePos = nil, nil
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude

        maid:give(RunService.Heartbeat:Connect(function(dt)
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.Health <= 0 then
                lastHp = nil
                return
            end

            if hum.FloorMaterial ~= Enum.Material.Air then
                safePos = root.CFrame
            end

            local hp = hum.Health
            if lastHp and hp < lastHp - 0.1 and o.velEnabled then
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(vel.X * o.horizMult, vel.Y * o.vertMult, vel.Z * o.horizMult)
            end
            lastHp = hp

            if o.speedEnabled then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0.01 then
                    local extra = math.max(0, o.speedVal - hum.WalkSpeed)
                    if extra > 0 then
                        local step = moveDir.Unit * extra * dt
                        rp.FilterDescendantsInstances = { ch }
                        if not workspace:Raycast(root.Position, step, rp) then
                            root.CFrame = root.CFrame + step
                        end
                    end
                end
            end

            if o.antifall and root.Position.Y < o.fallY and safePos then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = safePos + Vector3.new(0, 3, 0)
            end
        end))
    end,
})

--------------------------------------------------------------------------------
-- MISC (Notifications, JSON Config, Unload)
--------------------------------------------------------------------------------
PMisc.add({
    name = "Notifications",
    default = true,
    settings = function(ui)
        ui.Slider("duration", "Duration (s)", 1, 8, 3, 0.5, "%.1f", function(v) State.notifyDuration = v end)
    end,
    enable = function() State.notify = true end,
    disable = function() State.notify = false end,
})

local autoSaveSerial, autoLoaded = 0, false
local function saveConfig(silent)
    if type(writefile) ~= "function" then
        if not silent then Notify("Config", "No writefile", 3, true) end
        return
    end
    local data = {}
    for _, m in ipairs(Modules) do
        if m.name ~= "Unload" and m.name ~= "Save Config" and m.name ~= "Load Config" then
            data[m.name] = { enabled = m.enabled, opt = m.opt, key = m.key and m.key.Name or nil }
        end
    end
    if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("pistonware") then
        pcall(makefolder, "pistonware")
    end
    local ok = pcall(writefile, Config.ConfigFile, HttpService:JSONEncode(data))
    if not silent then Notify("Config", ok and "Saved" or "Save failed", 2, true) end
end

scheduleAutoSave = function()
    if not autoLoaded then return end
    autoSaveSerial += 1
    local ser = autoSaveSerial
    task.delay(0.8, function()
        if ser == autoSaveSerial and env.__WrenchHub then
            saveConfig(true)
        end
    end)
end

local function loadConfig(silent)
    if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(Config.ConfigFile) then
        if not silent then Notify("Config", "No config file", 3, true) end
        return
    end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(Config.ConfigFile)) end)
    if not ok or type(decoded) ~= "table" then
        if not silent then Notify("Config", "Invalid JSON", 3, true) end
        return
    end
    for _, m in ipairs(Modules) do
        local entry = decoded[m.name]
        if entry then
            if type(entry.opt) == "table" then
                for k, v in pairs(entry.opt) do
                    m.opt[k] = v
                    if m._syncers and m._syncers[k] then pcall(m._syncers[k], v) end
                end
            end
            if entry.key and Enum.KeyCode[entry.key] then
                m.key = Enum.KeyCode[entry.key]
                if m._syncBind then pcall(m._syncBind) end
            end
            if entry.enabled ~= nil then m.set(entry.enabled, true) end
        end
    end
    if not silent then Notify("Config", "Loaded", 2, true) end
end

PMisc.add({ name = "Save Config", action = function() saveConfig(false) end })
PMisc.add({ name = "Load Config", action = function() loadConfig(false) end })

local function Unload()
    pcall(saveConfig, true)
    for i = #Modules, 1, -1 do pcall(Modules[i].set, false, true) end
    pcall(function() RunService:UnbindFromRenderStep("WrenchHub.Core") end)
    CoreMaid:clean()
    Gui:Destroy()
    env.__WrenchHub = nil
end

CoreMaid:give(Players.PlayerRemoving:Connect(function(p)
    if p == LP then pcall(saveConfig, true) end
end))
pcall(function()
    game:BindToClose(function() pcall(saveConfig, true) end)
end)

PMisc.add({ name = "Unload", action = Unload })

--------------------------------------------------------------------------------
-- Input + core loop
--------------------------------------------------------------------------------
CoreMaid:give(UserInputService.InputChanged:Connect(function(input)
    if dragFn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        dragFn(input)
    end
end))
CoreMaid:give(UserInputService.InputEnded:Connect(function(input)
    if isPress(input) then dragFn = nil end
end))
CoreMaid:give(UserInputService.InputBegan:Connect(function(input, gpe)
    if capturing then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local k, cb = input.KeyCode, capturing
            capturing = nil
            if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace or k == Config.MenuKey then cb(nil) else cb(k) end
        end
        return
    end
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Config.MenuKey then
        setMenu(not menuOpen)
        return
    end
    for _, m in ipairs(Modules) do
        if m.key and m.key == input.KeyCode then m.set(not m.enabled) end
    end
end))

RunService:BindToRenderStep("WrenchHub.Core", Enum.RenderPriority.First.Value, function(dt)
    dt = math.min(dt, 0.1)
    if Entities.refs > 0 then Entities.rebuild() end
    stepAnims(dt)
    tickToasts()
end)

env.__WrenchHub = { Unload = Unload, Notify = Notify }
pcall(loadConfig, true)
autoLoaded = true
Notify("Hub", "Loaded. Press RightShift", 3)
print("[WrenchHub] loaded. RightShift opens the menu.")
