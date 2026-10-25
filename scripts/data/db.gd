class_name DB
## Tabelas de dados do jogo. Ajuste os números aqui para balancear.

# ======================================================================
# PERSONAGENS  (id = número do arquivo assets/chars/Player/pipo-nekoninXXX.png)
#   weapon : arma inicial
#   price  : moedas para desbloquear (0 = grátis)
#   perk   : bônus de atributos (somados aos atributos base do jogador)
#   req    : DESAFIO (opcional). O personagem só pode ser comprado depois de
#            cumprir o desafio (como no Megabonk). Tipos: kills, boss_kills, wins,
#            stage, level, survive (segundos), runs, potions, elem_kills, synergy.
# ======================================================================
const CHARACTERS := {
	13: {"name": "Feiticeiro", "weapon": "fire", "price": 0, "perk": {}, "desc": "O mago original. Equilibrado."},
	2: {"name": "Laranjinha", "weapon": "fire", "price": 60, "perk": {"speed": 0.08}, "desc": "+8% velocidade."},
	21: {"name": "Abóbora", "weapon": "fire2", "price": 90, "req": {"type": "synergy", "elem": "fire"}, "perk": {"max_hp": 25.0}, "desc": "+25 vida máxima."},
	32: {"name": "Chapéu de Palha", "weapon": "fire", "price": 150, "req": {"type": "runs", "value": 5}, "perk": {"luck": 0.10}, "desc": "+10% sorte."},
	15: {"name": "Lorde Demônio", "weapon": "fire2", "price": 300, "req": {"type": "wins", "value": 1}, "perk": {"damage": 0.20, "area": 0.15}, "desc": "+20% dano, +15% área."},

	4: {"name": "Branquinho", "weapon": "holy", "price": 80, "perk": {"regen": 0.3}, "desc": "+0.3 vida/s."},
	25: {"name": "Lacinho", "weapon": "holy2", "price": 150, "perk": {"magnet": 20.0}, "desc": "+20 alcance de coleta."},
	11: {"name": "Vovó", "weapon": "holy", "price": 180, "perk": {"xp_gain": 0.12}, "desc": "+12% experiência."},
	19: {"name": "Anjo", "weapon": "holy", "price": 150, "req": {"type": "elem_kills", "elem": "holy", "value": 300}, "perk": {"max_hp": 20.0, "regen": 0.5}, "desc": "+20 vida, +0.5 vida/s."},
	26: {"name": "Anjinha", "weapon": "holy2", "price": 200, "req": {"type": "synergy", "elem": "holy"}, "perk": {"attack_speed": 0.15, "luck": 0.10}, "desc": "+15% vel. ataque, +10% sorte."},

	3: {"name": "Cinzento", "weapon": "dark", "price": 60, "perk": {"crit_chance": 0.05}, "desc": "+5% crítico."},
	10: {"name": "Detetive", "weapon": "dark", "price": 120, "req": {"type": "boss_kills", "value": 3}, "perk": {"crit_chance": 0.08, "crit_mult": 0.25}, "desc": "+8% crítico, +25% dano crítico."},
	20: {"name": "Morcego", "weapon": "dark2", "price": 120, "req": {"type": "stage", "value": 2}, "perk": {"speed": 0.12, "regen": 0.2}, "desc": "+12% velocidade, +0.2 vida/s."},
	27: {"name": "Diabinha", "weapon": "dark2", "price": 200, "req": {"type": "elem_kills", "elem": "dark", "value": 400}, "perk": {"damage": 0.15, "crit_chance": 0.08}, "desc": "+15% dano, +8% crítico."},

	5: {"name": "Siamês", "weapon": "ice", "price": 80, "perk": {"armor": 3.0}, "desc": "+3 armadura."},
	9: {"name": "Nerd", "weapon": "ice", "price": 140, "perk": {"xp_gain": 0.10}, "desc": "+10% experiência."},
	24: {"name": "Rosinha", "weapon": "ice2", "price": 200, "perk": {"area": 0.12}, "desc": "+12% área."},
	12: {"name": "Mergulhador", "weapon": "ice2", "price": 120, "req": {"type": "elem_kills", "elem": "ice", "value": 300}, "perk": {"projectiles": 1}, "desc": "+1 projétil."},

	6: {"name": "Malhado", "weapon": "thunder", "price": 70, "perk": {"speed": 0.06}, "desc": "+6% velocidade."},
	29: {"name": "Operário", "weapon": "thunder", "price": 100, "req": {"type": "kills", "value": 1500}, "perk": {"armor": 5.0}, "desc": "+5 armadura."},
	31: {"name": "Leãozinho", "weapon": "thunder2", "price": 120, "req": {"type": "survive", "value": 300}, "perk": {"damage": 0.12}, "desc": "+12% dano."},
	14: {"name": "Faraó", "weapon": "thunder2", "price": 180, "req": {"type": "synergy", "elem": "thunder"}, "perk": {"attack_speed": 0.20}, "desc": "+20% vel. ataque."},

	1: {"name": "Creminho", "weapon": "acid", "price": 50, "perk": {"max_hp": 10.0}, "desc": "+10 vida máxima."},
	8: {"name": "Azulado", "weapon": "acid2", "price": 100, "perk": {"magnet": 25.0}, "desc": "+25 alcance de coleta."},
	7: {"name": "Zumbi", "weapon": "acid", "price": 100, "req": {"type": "elem_kills", "elem": "acid", "value": 300}, "perk": {"regen": 0.8}, "desc": "+0.8 vida/s."},
	22: {"name": "Melancia", "weapon": "acid", "price": 100, "req": {"type": "potions", "value": 25}, "perk": {"area": 0.20}, "desc": "+20% área."},
	23: {"name": "Kiwi", "weapon": "acid2", "price": 300, "perk": {"luck": 0.15}, "desc": "+15% sorte."},

	16: {"name": "Ursinho", "weapon": "wood", "price": 120, "perk": {"max_hp": 15.0}, "desc": "+15 vida máxima."},
	17: {"name": "Urso Pardo", "weapon": "wood2", "price": 160, "perk": {"armor": 4.0}, "desc": "+4 armadura."},
	18: {"name": "Panda", "weapon": "wood", "price": 120, "req": {"type": "level", "value": 20}, "perk": {"max_hp": 30.0, "armor": 2.0}, "desc": "+30 vida, +2 armadura."},
	28: {"name": "Folhagem", "weapon": "wood", "price": 360, "perk": {"regen": 0.6, "area": 0.10}, "desc": "+0.6 vida/s, +10% área."},
	30: {"name": "Cerejeira", "weapon": "wood2", "price": 220, "req": {"type": "synergy", "elem": "wood"}, "perk": {"projectiles": 1, "regen": 0.5}, "desc": "+1 projétil, +0.5 vida/s."},
}

## Ordem de exibição na tela de personagens.
static func character_order() -> Array:
	var ids: Array = CHARACTERS.keys()
	ids.sort_custom(func(a, b):
		var pa: int = CHARACTERS[a]["price"]
		var pb: int = CHARACTERS[b]["price"]
		return pa < pb if pa != pb else a < b)
	return ids

static func char_texture_path(id: int) -> String:
	return "res://assets/chars/Player/pipo-nekonin%03d.png" % id


# ======================================================================
# ARMAS
# ======================================================================
const MAX_WEAPONS := 3          # máximo de poderes por partida
const WEAPON_MAX_LEVEL := 10

## Cada poder vem de uma POÇÃO (tema da jam: "Animais Fofos e Alquimia").
## São 7 elementos com 2 poderes cada. Ter os dois poderes do mesmo elemento ativa a SINERGIA.
## potion_cell = (coluna, linha) do frasco em "assets/potions/Potions - Full, Corked.png" (16x24 cada):
## a linha é a cor (elemento) e a coluna é o formato do frasco.
const POTION_SHEET := "res://assets/potions/Potions - Full, Corked.png"
const POTION_SIZE := Vector2i(16, 24)
const SYNERGY_BONUS := 0.25      # +25% de dano nos dois poderes do mesmo elemento

const ELEMENTS := {
	"fire": {"name": "Fogo", "color": Color(1.0, 0.55, 0.2)},
	"holy": {"name": "Sagrado", "color": Color(1.0, 0.92, 0.55)},
	"dark": {"name": "Sombrio", "color": Color(0.75, 0.3, 0.85)},
	"ice": {"name": "Gelo", "color": Color(0.5, 0.85, 1.0)},
	"thunder": {"name": "Trovão", "color": Color(1.0, 0.85, 0.35)},
	"acid": {"name": "Ácido", "color": Color(0.45, 0.95, 0.35)},
	"wood": {"name": "Madeira", "color": Color(0.75, 0.5, 0.3)},
}

const WEAPONS := {
	# ---------------- Fogo
	"fire": {"elem": "fire", "potion": "Poção Flamejante", "name": "Bola de Fogo", "script": "res://scripts/weapons/w_fire.gd",
		"desc": "Bolas de fogo no inimigo mais próximo. Explodem a partir do nível 4.", "potion_cell": Vector2i(0, 3)},
	"fire2": {"elem": "fire", "potion": "Tônico Dracônico", "name": "Sopro de Fogo", "script": "res://scripts/weapons/w_fire2.gd",
		"desc": "Um sopro em cone, de curto alcance, que deixa inimigos queimando.", "potion_cell": Vector2i(4, 3)},
	# ---------------- Sagrado
	"holy": {"elem": "holy", "potion": "Poção Celestial", "name": "Luz Sagrada", "script": "res://scripts/weapons/w_holy.gd",
		"desc": "Pilares de luz caem sobre inimigos próximos.", "potion_cell": Vector2i(1, 14)},
	"holy2": {"elem": "holy", "potion": "Água Benta", "name": "Lanças de Luz", "script": "res://scripts/weapons/w_holy2.gd",
		"desc": "Lanças perfurantes disparadas em várias direções.", "potion_cell": Vector2i(5, 14)},
	# ---------------- Sombrio
	"dark": {"elem": "dark", "potion": "Poção Sombria", "name": "Caveira Sombria", "script": "res://scripts/weapons/w_dark.gd",
		"desc": "Caveiras teleguiadas perseguem os inimigos.", "potion_cell": Vector2i(6, 4)},
	"dark2": {"elem": "dark", "potion": "Elixir do Vazio", "name": "Nova Sombria", "script": "res://scripts/weapons/w_dark2.gd",
		"desc": "Explosão sombria ao seu redor que empurra inimigos e rouba vida.", "potion_cell": Vector2i(9, 4)},
	# ---------------- Gelo
	"ice": {"elem": "ice", "potion": "Poção Gélida", "name": "Estilhaço de Gelo", "script": "res://scripts/weapons/w_ice.gd",
		"desc": "Estilhaços perfurantes que deixam inimigos lentos.", "potion_cell": Vector2i(3, 10)},
	"ice2": {"elem": "ice", "potion": "Orvalho Glacial", "name": "Prisão de Gelo", "script": "res://scripts/weapons/w_ice2.gd",
		"desc": "Espinhos de gelo brotam sob inimigos e os congelam.", "potion_cell": Vector2i(7, 10)},
	# ---------------- Trovão
	"thunder": {"elem": "thunder", "potion": "Poção Elétrica", "name": "Raio em Cadeia", "script": "res://scripts/weapons/w_thunder.gd",
		"desc": "Um raio que salta entre vários inimigos.", "potion_cell": Vector2i(2, 9)},
	"thunder2": {"elem": "thunder", "potion": "Néctar da Tempestade", "name": "Falcão Elétrico", "script": "res://scripts/weapons/w_thunder2.gd",
		"desc": "Invoca um falcão de raios que mergulha em vários inimigos e os paralisa.", "potion_cell": Vector2i(8, 9)},
	# ---------------- Ácido
	"acid": {"elem": "acid", "potion": "Poção Corrosiva", "name": "Poça Ácida", "script": "res://scripts/weapons/w_acid.gd",
		"desc": "Cria poças borbulhantes que causam dano contínuo.", "potion_cell": Vector2i(5, 2)},
	"acid2": {"elem": "acid", "potion": "Frasco Venenoso", "name": "Frasco Arremessado", "script": "res://scripts/weapons/w_acid2.gd",
		"desc": "Arremessa frascos que estouram e envenenam.", "potion_cell": Vector2i(1, 2)},
	# ---------------- Madeira
	"wood": {"elem": "wood", "potion": "Poção da Floresta", "name": "Troncos Orbitais", "script": "res://scripts/weapons/w_wood.gd",
		"desc": "Troncos pesados giram ao seu redor esmagando inimigos.", "potion_cell": Vector2i(8, 13)},
	"wood2": {"elem": "wood", "potion": "Seiva Ancestral", "name": "Onda de Espinhos", "script": "res://scripts/weapons/w_wood2.gd",
		"desc": "Espinhos brotam em anel a partir de você.", "potion_cell": Vector2i(4, 13)},
}

static func weapon_color(id: String) -> Color:
	return ELEMENTS[WEAPONS[id]["elem"]]["color"]

static func element_name(id: String) -> String:
	return ELEMENTS[WEAPONS[id]["elem"]]["name"]


# ======================================================================
# MELHORIAS PASSIVAS (oferecidas ao subir de nível)
#   value: valor no nível de raridade Comum (multiplicado pela raridade)
# ======================================================================
const PASSIVES := {
	"damage": {"name": "Poder", "desc": "+{v}% dano", "value": 0.08, "pct": true},
	"attack_speed": {"name": "Pressa", "desc": "+{v}% velocidade de ataque", "value": 0.08, "pct": true},
	"max_hp": {"name": "Vitalidade", "desc": "+{v} vida máxima", "value": 15.0, "pct": false},
	"speed": {"name": "Agilidade", "desc": "+{v}% velocidade de movimento", "value": 0.06, "pct": true},
	"area": {"name": "Expansão", "desc": "+{v}% área", "value": 0.08, "pct": true},
	"magnet": {"name": "Ímã", "desc": "+{v} alcance de coleta", "value": 12.0, "pct": false},
	"regen": {"name": "Regeneração", "desc": "+{v} vida por segundo", "value": 0.3, "pct": false},
	"armor": {"name": "Armadura", "desc": "+{v} armadura", "value": 2.0, "pct": false},
	"luck": {"name": "Sorte", "desc": "+{v}% sorte", "value": 0.06, "pct": true},
	"xp_gain": {"name": "Sabedoria", "desc": "+{v}% experiência", "value": 0.08, "pct": true},
	"crit_chance": {"name": "Precisão", "desc": "+{v}% chance de crítico", "value": 0.04, "pct": true},
	"projectiles": {"name": "Multiplicador", "desc": "+{v} projétil para todas as armas", "value": 1, "pct": false, "min_rarity": 2, "flat": true},
}

const RARITIES := [
	{"name": "Comum", "mult": 1.0, "weight": 60.0, "color": Color(0.85, 0.85, 0.85)},
	{"name": "Incomum", "mult": 1.4, "weight": 25.0, "color": Color(0.35, 0.9, 0.4)},
	{"name": "Raro", "mult": 1.8, "weight": 11.0, "color": Color(0.3, 0.6, 1.0)},
	{"name": "Épico", "mult": 2.5, "weight": 3.5, "color": Color(0.75, 0.35, 1.0)},
	{"name": "Lendário", "mult": 3.5, "weight": 0.5, "color": Color(1.0, 0.65, 0.1)},
]

## Sorteia uma raridade (índice) levando em conta a sorte do jogador.
static func roll_rarity(luck: float, min_rarity: int = 0) -> int:
	var total := 0.0
	var weights: Array = []
	for i in RARITIES.size():
		var w: float = RARITIES[i]["weight"]
		if i > 0:
			w *= 1.0 + luck * 2.0 * i
		if i < min_rarity:
			w = 0.0
		weights.append(w)
		total += w
	var r := randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return min_rarity


# ======================================================================
# INIMIGOS
#   anims: nome_da_animação -> [arquivo, fps, loop]
# ======================================================================
const ENEMIES := {
	"slime": {"name": "Slime", "hp": 9.0, "speed": 40.0, "damage": 5.0, "xp": 1, "coin": 0.05,
		"scale": 1.4, "radius": 6.0, "dir": "Slime", "attack": "Slime-Attack01"},
	"skeleton": {"name": "Esqueleto", "hp": 18.0, "speed": 48.0, "damage": 7.0, "xp": 2, "coin": 0.07,
		"scale": 1.6, "radius": 7.0, "dir": "Skeleton", "attack": "Skeleton-Attack01"},
	"archer": {"name": "Esqueleto Arqueiro", "hp": 14.0, "speed": 48.0, "damage": 6.0, "xp": 3, "coin": 0.09,
		"scale": 1.6, "radius": 7.0, "dir": "Skeleton Archer", "attack": "Skeleton Archer-Attack", "ranged": true},
	"orc": {"name": "Orc", "hp": 48.0, "speed": 40.0, "damage": 14.0, "xp": 5, "coin": 0.12,
		"scale": 1.55, "radius": 8.0, "dir": "Orc", "attack": "Orc-Attack01"},
	"werewolf": {"name": "Lobisomem", "hp": 32.0, "speed": 80.0, "damage": 12.0, "xp": 4, "coin": 0.10,
		"scale": 1.7, "radius": 7.5, "dir": "Werewolf", "attack": "Werewolf-Attack01"},
	"werebear": {"name": "Urso-Lobisomem", "hp": 100.0, "speed": 44.0, "damage": 20.0, "xp": 10, "coin": 0.2,
		"scale": 1.75, "radius": 9.0, "dir": "Werebear", "attack": "Werebear-Attack01"},
}


# ======================================================================
# ESTÁGIOS
#   spawn: [id, peso, a partir de (0..1 do tempo do estágio)]
# ======================================================================
const STAGE_TIME := 180.0   # segundos até o chefão aparecer

## Dificuldade por estágio (independe do bioma).
##   boss.attacks: "charge" (investida), "slam" (pancada em área), "volley" (rajada de projéteis), "summon" (lacaios)
const STAGES := [
	{
		"spawn": [["slime", 5.0, 0.0], ["skeleton", 4.0, 0.08], ["archer", 1.5, 0.25], ["werewolf", 2.0, 0.45], ["orc", 1.5, 0.65]],
		"swarm": ["slime", "skeleton", "werewolf"], "elite": ["skeleton", "orc", "werewolf"],
		"boss": {"type": "orc", "name": "Chefe Orc", "hp": 1800.0, "damage": 18.0, "scale": 2.8, "speed": 44.0,
			"attacks": ["slam", "charge", "summon"]},
	},
	{
		"spawn": [["skeleton", 5.0, 0.0], ["archer", 4.0, 0.0], ["orc", 4.0, 0.0], ["werewolf", 4.0, 0.1], ["slime", 2.0, 0.0], ["werebear", 1.5, 0.6]],
		"swarm": ["skeleton", "werewolf", "orc"], "elite": ["orc", "werewolf", "werebear"],
		"boss": {"type": "werewolf", "name": "Lobisomem Alfa", "hp": 7000.0, "damage": 28.0, "scale": 2.8, "speed": 64.0,
			"attacks": ["charge", "charge", "volley", "summon"]},
	},
	{
		"spawn": [["orc", 5.0, 0.0], ["werewolf", 5.0, 0.0], ["archer", 4.0, 0.0], ["skeleton", 3.0, 0.0], ["werebear", 3.0, 0.2], ["slime", 1.0, 0.0]],
		"swarm": ["werewolf", "orc", "skeleton"], "elite": ["werebear", "orc"],
		"boss": {"type": "werebear", "name": "Rei Urso", "hp": 16000.0, "damage": 36.0, "scale": 3.0, "speed": 48.0,
			"attacks": ["slam", "volley", "charge", "summon", "slam"]},
	},
]

## Biomas: a cada partida 3 são sorteados (um por estágio).
## Arte do chão: Ninja Adventure (CC0) — ver scripts/world/map_generator.gd.
##   floor_block : origem (em tiles) do bloco do bioma no TilesetFloor
##                 (0,0) areia  (11,0) areia rosa  (0,7) grama clara  (11,7) grama escura
##                 (0,14) neve  (11,14) terra
##   trees       : número = árvore do Forest Trees Pack; [col, lin, larg, alt] = TilesetNature (Ninja)
##   decor       : [fonte, tile] (fonte 2 = TilesetFloorDetail, 3 = TilesetNature)
##   weather     : "" | "leaves" | "snow" | "petals" | "spores" | "fireflies"
const BIOMES := [
	{"name": "Floresta Serena", "weather": "fireflies", "flower": Color(1.0, 0.9, 0.5),
		"floor_block": Vector2i(0, 7), "patch_threshold": 0.3,
		"tree_tint": Color(1, 1, 1), "tree_density": 0.55,
		"trees": [1, 2, 3, 4, 5, 6, 7, 9, 12, 15, [16, 0, 2, 2], [18, 0, 2, 2], [3, 18, 3, 3]],
		"decor": [[2, Vector2i(0, 2)], [2, Vector2i(1, 2)], [2, Vector2i(2, 2)], [2, Vector2i(3, 2)],
			[3, Vector2i(0, 11)], [3, Vector2i(1, 11)], [3, Vector2i(3, 11)], [3, Vector2i(6, 11)], [3, Vector2i(1, 10)]]},
	{"name": "Bosque Outonal", "weather": "leaves", "flower": Color(0.95, 0.5, 0.2),
		"floor_block": Vector2i(0, 0), "patch_threshold": 0.25,
		"tree_tint": Color(1.2, 0.9, 0.6), "tree_density": 0.55,
		"trees": [[9, 18, 3, 3], [9, 18, 3, 3], 1, 3, 5, 8, 13, 16, [4, 0, 2, 2]],
		"decor": [[2, Vector2i(0, 0)], [2, Vector2i(4, 0)], [2, Vector2i(5, 0)], [2, Vector2i(7, 0)], [3, Vector2i(3, 11)]]},
	{"name": "Floresta Maldita", "weather": "spores", "flower": Color(0.8, 0.4, 1.0),
		"floor_block": Vector2i(11, 14), "patch_threshold": 0.3,
		"ground_tint": Color(0.82, 0.72, 0.95),
		"tree_tint": Color(0.8, 0.65, 0.95), "tree_density": 0.6,
		"trees": [13, 16, 13, 16, [4, 0, 2, 2], [4, 0, 2, 2], 8, 14],
		"decor": [[2, Vector2i(13, 0)], [2, Vector2i(14, 0)], [2, Vector2i(5, 0)], [2, Vector2i(6, 0)], [2, Vector2i(15, 0)]]},
	{"name": "Floresta Gélida", "weather": "snow", "flower": Color(0.85, 0.95, 1.0),
		"floor_block": Vector2i(0, 14), "patch_threshold": 0.3,
		"tree_tint": Color(1, 1, 1), "tree_density": 0.5,
		"trees": [[8, 0, 2, 2], [10, 0, 2, 2], [12, 0, 2, 2], [6, 18, 3, 3], 14],
		"decor": [[2, Vector2i(0, 3)], [2, Vector2i(1, 3)], [2, Vector2i(2, 3)], [2, Vector2i(3, 3)], [2, Vector2i(4, 3)]]},
	{"name": "Pântano Nebuloso", "weather": "spores", "flower": Color(0.6, 1.0, 0.4),
		"floor_block": Vector2i(11, 7), "patch_threshold": 0.15,
		"ground_tint": Color(0.85, 0.95, 0.85),
		"tree_tint": Color(0.75, 0.9, 0.75), "tree_density": 0.6,
		"trees": [[6, 0, 2, 2], [2, 0, 2, 2], 2, 10, 13, 16],
		"decor": [[2, Vector2i(0, 2)], [2, Vector2i(5, 2)], [2, Vector2i(7, 2)], [3, Vector2i(4, 11)], [3, Vector2i(5, 11)], [3, Vector2i(8, 11)]]},
	{"name": "Bosque das Cerejeiras", "weather": "petals", "flower": Color(1.0, 0.6, 0.8),
		"floor_block": Vector2i(11, 0), "patch_threshold": 0.3,
		"tree_tint": Color(1, 1, 1), "tree_density": 0.5,
		"trees": [[14, 0, 2, 2], [14, 0, 2, 2], [0, 18, 3, 3], 4, 9],
		"decor": [[2, Vector2i(2, 0)], [2, Vector2i(3, 0)], [3, Vector2i(6, 11)], [3, Vector2i(3, 11)]]},
]


# ======================================================================
# EXPERIÊNCIA
# ======================================================================
static func xp_to_next(level: int) -> int:
	return int(round(3.0 + 3.2 * level + 0.6 * level * level + 0.015 * level * level * level))
