# Transparência sobre uso de IA

Resumo oficial para a jam: `TERMO_IA.md`. Este arquivo lista **tudo o que foi produzido por IA** (Claude, da Anthropic) neste projeto,
para conferência com as regras da game jam. Os commits feitos com IA têm a linha
`Co-Authored-By: Claude` na mensagem, então `git log --grep "Co-Authored-By: Claude"` mostra todos.

## 1. Imagens, músicas e sons gerados por IA

**Nenhum.** As músicas são de Uendel Felipe Picoli Olivo (autorais) e os efeitos sonoros são do Ninja Adventure (CC0) — a IA só escolheu quais arquivos usar e em qual evento tocar (`scripts/autoload/sound.gd`).

Sobre imagens: A moeda, as gemas de XP, o coração e o portal que a IA tinha desenhado
foram substituídos por sprites do pacote **Ninja Adventure** (Pixel-boy & AAA, CC0):
`Items/Treasure/Coin2.png`, cristais azuis do `TilesetNature.png` (clareados por código), `Items/Potion/Heart.png` e
`FX/Magic/Circle/SpriteSheetWhite.png` (tingido de roxo). A pasta `assets/generated/`
agora só tem as cópias ampliadas da UI (item 2).

## 2. Imagens processadas por IA (sem arte nova)

- `assets/generated/ui/*.png`: cópias **ampliadas 3x** (pixel a pixel, sem alteração de desenho) dos sprites do pacote de UI de Crusenho (`assets/UI`). Não há arte nova, só redimensionamento.

## 3. Visuais procedurais (criados em tempo de execução por código da IA)

Não são arquivos de imagem, mas o que aparece na tela é gerado por código escrito pela IA:

- Montagem do mapa: o código da IA escolhe **onde** colocar cada tile do chão, das manchas, das árvores e dos enfeites (`scripts/world/map_generator.gd`, `scripts/ui/menu_background.gd`). Os tiles e árvores em si são arte humana do Ninja Adventure (CC0). Alguns biomas usam um tingimento de cor por código (ex.: Floresta Maldita mais roxa).
- Clima: as partículas usam os sprites de `FX/Particle` do Ninja Adventure; o código só controla quantidade, direção e cor.
- Círculo verde da poça ácida (`scripts/weapons/acid_pool.gd`), raio em zigue-zague (`w_thunder.gd`), seta do portal (`scripts/ui/hud.gd`), barras de vida/XP (`scripts/ui/pixel_bar.gd` — usa a moldura do pacote de UI + retângulos de cor), números de dano.
- Avisos de ataque dos chefões (círculo/linha vermelha — `scripts/telegraph.gd`), minimapa (`scripts/ui/minimap.gd`) e a tela escura de transição entre mundos (`scripts/ui/stage_transition.gd`).
- Contorno amarelo da carta selecionada no level-up e o fundo do quadro de animação do Compêndio (`scripts/ui/level_up_menu.gd`, `scripts/ui/compendium.gd`).
- Cores de estado dos inimigos (laranja = queimando, azul = congelando, amarelo = eletrizado, verde = envenenado): são só tingimentos do sprite original, feitos por código (`scripts/enemy.gd`).

## 4. Código e dados escritos por IA

- Todo o código em `scripts/` (o `scripts/player.gd` foi reescrito a partir do original da equipe; a versão original está em `old/player_antigo.gd`).
- Todas as cenas em `scenes/` (`game.tscn`, `player.tscn`, `enemy.tscn`, `scenes/ui/*`).
- O formato do arquivo `data/nomes.json`.
- Alterações em `project.godot` (autoload, entradas, resolução, fonte).
- Números de balanceamento, curva de XP e preços (`scripts/data/db.gd`).

## 5. Textos co-autorados com IA

- Nome do jogo, "Nekomania": definido pela equipe.
- Nomes e descrições exibidos dos gatos, inimigos e chefões (`data/nomes.json`): escritos pela equipe, que trocou todos os nomes de inimigos e chefões, 22 dos 32 nomes de gatos e as descrições com piadas. Os nomes restantes vieram de sugestões da IA que a equipe manteve.
- Nomes de poções, poderes, melhorias e biomas (`scripts/data/db.gd`): sugeridos pela IA e aprovados pela equipe.
- Textos do Compêndio, da tabela de atributos e da interface (menus, HUD, avisos): escritos pela IA e revisados pela equipe.
- `LEIA-ME_DEV.md`, este arquivo, `CREDITOS.md` e `TERMO_IA.md`: rascunhos da IA, editados e completados pela equipe.

## O que NÃO foi feito por IA

- Todos os sprites em `assets/chars`, `assets/spells`, `assets/map` (inclui o Ninja Adventure), `assets/UI` e `assets/potions` (pacotes de artistas — ver `CREDITOS.md`).
- A fonte Silkscreen (`assets/fonts`, de Jason Kottke, licença OFL).
- O código e as cenas originais da equipe, guardados em `old/`.
