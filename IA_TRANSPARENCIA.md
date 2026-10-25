# Transparência sobre uso de IA

Este arquivo lista **tudo o que foi produzido por IA** (Claude, da Anthropic) neste projeto,
para conferência com as regras da game jam. Os commits feitos com IA têm a linha
`Co-Authored-By: Claude` na mensagem, então `git log --grep "Co-Authored-By: Claude"` mostra todos.

## 1. Imagens geradas por IA (desenhadas por código escrito pela IA)

Estes arquivos **não são arte humana** e devem ser substituídos se a jam proibir arte gerada:

| Arquivo | O que é | Tamanho esperado para substituir |
|---|---|---|
| `assets/generated/coin.png` | Moeda girando | 8 quadros de 16x16 lado a lado (128x16) |
| `assets/generated/xp_gems.png` | Gemas de XP (azul, verde, vermelha) | 3 quadros de 10x12 lado a lado (30x12) |
| `assets/generated/heart.png` | Coração (cura) | 12x10 |
| `assets/generated/portal.png` | Portal roxo girando | 8 quadros de 48x48 lado a lado (384x48) |

Basta trocar o PNG mantendo o mesmo nome e tamanho (ou ajustar os tamanhos em `scripts/sprite_lib.gd` e `scripts/world/pickup.gd`).

## 2. Imagens processadas por IA (sem arte nova)

- `assets/generated/ui/*.png`: cópias **ampliadas 3x** (pixel a pixel, sem alteração de desenho) dos sprites do pacote de UI de Crusenho (`assets/UI`). Não há arte nova, só redimensionamento.

## 3. Visuais procedurais (criados em tempo de execução por código da IA)

Não são arquivos de imagem, mas o que aparece na tela é gerado por código escrito pela IA:

- `scripts/world/ground.gdshader`: textura do chão (grama/terra, manchas, florzinhas).
- `scripts/ui/menu_ground.gdshader`: fundo dos menus.
- Círculo verde da poça ácida (`scripts/weapons/acid_pool.gd`), raio em zigue-zague (`w_thunder.gd`), seta do portal (`scripts/ui/hud.gd`), barras de vida/XP (`scripts/ui/pixel_bar.gd` — usa a moldura do pacote de UI + retângulos de cor), números de dano.
- Avisos de ataque dos chefões (círculo/linha vermelha — `scripts/telegraph.gd`), minimapa (`scripts/ui/minimap.gd`), partículas de clima (quadradinhos coloridos — `scripts/world/weather.gd`) e a tela escura de transição entre mundos (`scripts/ui/stage_transition.gd`).
- Cores de estado dos inimigos (laranja = queimando, azul = congelando, amarelo = eletrizado, verde = envenenado): são só tingimentos do sprite original, feitos por código (`scripts/enemy.gd`).
- Distribuição procedural das árvores (`scripts/world/map_generator.gd`) — as árvores em si são do pacote humano.

## 4. Código e dados escritos por IA

- Todo o código em `scripts/` (o `scripts/player.gd` foi reescrito a partir do original da equipe; a versão original está em `old/player_antigo.gd`).
- Todas as cenas em `scenes/` (`game.tscn`, `player.tscn`, `enemy.tscn`, `scenes/ui/*`).
- Alterações em `project.godot` (autoload, entradas, resolução, fonte).
- Números de balanceamento, curva de XP e preços (`scripts/data/db.gd`).

## 5. Textos escritos por IA

- Título provisório "NEKO ARCANO" e subtítulo do menu.
- Nomes e descrições dos personagens, das poções, dos poderes, das melhorias e dos estágios/chefões (`scripts/data/db.gd`).
- Todos os textos da interface (menus, HUD, avisos).
- `LEIA-ME_DEV.md`, este arquivo e `CREDITOS.md`.

## O que NÃO foi feito por IA

- Todos os sprites em `assets/chars`, `assets/spells`, `assets/map`, `assets/UI` e `assets/potions` (pacotes de artistas — ver `CREDITOS.md`).
- A fonte Silkscreen (`assets/fonts`, de Jason Kottke, licença OFL).
- O código e as cenas originais da equipe, guardados em `old/`.
