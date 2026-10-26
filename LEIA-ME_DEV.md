# Nekomania — guia rápido do código

Godot 4.7. A cena principal agora é `scenes/ui/main_menu.tscn`.

## Estrutura

| Pasta / arquivo | O que faz |
|---|---|
| `scripts/autoload/global.gd` | Autoload **Global**: moedas, personagens desbloqueados, recordes (salvos em `user://save.cfg`) e teclas (WASD/setas, ESC/P, controle). |
| `scripts/autoload/sound.gd` | Autoload **Sound**: músicas (`assets/SFX`: home = menus, phase = estágio, boss = chefão) e efeitos (`assets/audio/sfx`). `Sound.play("coin")`, `Sound.music("boss")`. Volume de música/efeitos no menu principal e na pausa (salvo em `user://settings.cfg`). |
| `scripts/data/db.gd` | **Todas as tabelas de balanceamento**: personagens, armas, melhorias, raridades, inimigos, estágios e curva de XP. |
| `scripts/sprite_lib.gd` | Monta as animações a partir das spritesheets em tempo de execução (personagens, inimigos e efeitos). |
| `scripts/game.gd` + `scenes/game.tscn` | A partida: estágios, chefão, portal, drops, level-up, pausa, fim de jogo. |
| `scripts/player.gd` | Movimento, atributos, vida, XP e armas do jogador. |
| `scripts/enemy.gd` + `scenes/enemy.tscn` | Inimigo genérico (o tipo vem de `DB.ENEMIES`). Efeitos de estado: fogo = queimando (laranja, dano contínuo), gelo = congelando (azul, lento), trovão = eletrizado (amarelo, parado), ácido = envenenado (verde, cambaleia de lado). Mira inteligente: as armas evitam inimigos que já vão morrer pelos tiros a caminho. |
| `scripts/world/spawn_director.gd` | Quando/onde/quais inimigos nascem: fluxo contínuo, hordas em anel, elites, reposicionamento. **Pressão adaptativa**: se o jogador mata rápido, o ritmo de spawn sobe (até 2,5x). |
| `scripts/world/map_generator.gd` | Mapa procedural infinito em chunks com tiles do **Ninja Adventure**: chão por bioma com manchas (marching squares), árvores e enfeites. |
| `scripts/world/pickup.gd` | XP, moedas e corações. |
| `scripts/weapons/` | `weapon.gd` (base) + 14 poderes: 2 por elemento (fogo, sagrado, sombrio, gelo, trovão, ácido, madeira). Cada um vem de uma **poção**. Máximo de 5 poderes por partida (`DB.MAX_WEAPONS`), nível máximo 10. Ter os 2 do mesmo elemento ativa a **sinergia** (+25% dano). |
| `scripts/boss_brain.gd` + `scripts/telegraph.gd` | Ataques dos chefões (investida, pancada, rajada, lacaios) com aviso visual. Chefões atravessam e derrubam árvores. |
| `scripts/ui/` | HUD, menu principal, personagens (com tabela de atributos), desafios, **compêndio** (gatos, inimigos e chefões com todas as animações), level-up, pausa, fim de jogo e tema visual. |
| `data/nomes.json` + `scripts/data/names.gd` | **Nomes e descrições editáveis** de todos os gatos, inimigos e chefões. Ver seção abaixo. |
| `assets/generated/ui/` | Cópias ampliadas 3x do tema de UI (sem arte nova). |
| `assets/map/Ninja Adventure - Asset Pack/` | Pacote CC0 usado no chão, enfeites, itens e clima. `Audio/` e `Actor/` ficam fora da exportação (ver `export_presets.cfg`). |
| `assets/fonts/` | Fonte Silkscreen (OFL). |
| `assets/potions/` | Poções de Onocentaur — ícones dos 7 poderes. |
| `old/` | Scripts/cenas antigos (ignorados pelo Godot via `.gdignore`). Pode apagar quando quiser. |

## Como uma partida funciona

1. 3 estágios (`DB.STAGES`), cada um num bioma sorteado entre 6 (`DB.BIOMES`). Cada um dura `DB.STAGE_TIME` (180 s) e depois aparece o chefão.
2. Derrotou o chefão → surge um portal (a seta roxa aponta para ele). Entrou → próximo estágio, com mapa novo e inimigos mais fortes.
3. Derrotou o chefão do estágio 3 → vitória.
4. Poções: o gato começa bebendo a poção do seu personagem. Ao subir de nível, as cartas oferecem poções (novo poder ou evolução). Elites e chefões sempre deixam cair uma poção; inimigos comuns, raramente.
5. Moedas coletadas vão para o banco ao fim da partida (ganhando ou perdendo) e desbloqueiam personagens.
6. **Desafios**: 16 personagens têm um desafio (`"req"` em `DB.CHARACTERS`) — são mais baratos, mas só podem ser comprados depois de cumprir o desafio (ex.: vencer uma partida, ativar uma sinergia, derrotar 300 inimigos com poderes Sagrados). O progresso fica em `Global` (`req_progress`, `req_text`).

## Balanceamento rápido

- Vida/dano/velocidade dos inimigos: `DB.ENEMIES`.
- Escala com o tempo: `SpawnDirector.hp_mult()` / `dmg_mult()`; quantidade: `rate` e `max_alive` em `_physics_process`.
- Quais inimigos aparecem em cada estágio (e a partir de quando): `"spawn"` em `DB.STAGES`.
- Chefões: `"boss"` em `DB.STAGES`.
- Armas: `stats_for_level()` em cada `scripts/weapons/w_*.gd`.
- Curva de XP: `DB.xp_to_next()` (sem termo cúbico) e o bônus de XP por estágio em `Game.on_enemy_killed()` (+75% por estágio).
- Preço e bônus dos personagens: `DB.CHARACTERS`.

## Trocar nomes e descrições

Edite `data/nomes.json` (abre em qualquer editor de texto, salve em UTF-8):

- `gatos`: a chave é o número do arquivo do gato (`pipo-nekoninXXX.png`). Campos `nome` e `descricao`.
- `inimigos`: `slime`, `skeleton`, `archer`, `orc`, `werewolf`, `werebear`.
- `chefoes`: `orc` (estágio 1), `werewolf` (estágio 2), `werebear` (estágio 3).

Campo vazio ou ausente = usa o padrão de `scripts/data/db.gd`. O arquivo vai junto na exportação
(`include_filter` em `export_presets.cfg`). No jogo exportado, um `nomes.json` colocado **ao lado do .exe**
tem prioridade, então dá para testar nomes novos sem exportar de novo.

Para zerar o save: chame `Global.reset_save()` (ou apague `user://save.cfg`).
