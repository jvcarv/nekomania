# Neko Arcano — guia rápido do código

Godot 4.7. A cena principal agora é `scenes/ui/main_menu.tscn`.

## Estrutura

| Pasta / arquivo | O que faz |
|---|---|
| `scripts/autoload/global.gd` | Autoload **Global**: moedas, personagens desbloqueados, recordes (salvos em `user://save.cfg`) e teclas (WASD/setas, ESC/P, controle). |
| `scripts/data/db.gd` | **Todas as tabelas de balanceamento**: personagens, armas, melhorias, raridades, inimigos, estágios e curva de XP. |
| `scripts/sprite_lib.gd` | Monta as animações a partir das spritesheets em tempo de execução (personagens, inimigos e efeitos). |
| `scripts/game.gd` + `scenes/game.tscn` | A partida: estágios, chefão, portal, drops, level-up, pausa, fim de jogo. |
| `scripts/player.gd` | Movimento, atributos, vida, XP e armas do jogador. |
| `scripts/enemy.gd` + `scenes/enemy.tscn` | Inimigo genérico (o tipo vem de `DB.ENEMIES`). Arqueiros atiram, chefões invocam lacaios. |
| `scripts/world/spawn_director.gd` | Quando/onde/quais inimigos nascem: fluxo contínuo, hordas em anel, elites, reposicionamento. |
| `scripts/world/map_generator.gd` | Mapa procedural infinito em chunks (ruído → bosques e clareiras) + chão em shader. |
| `scripts/world/pickup.gd` | XP, moedas e corações. |
| `scripts/weapons/` | `weapon.gd` (base) + uma arma por elemento: fogo, sagrado, sombrio, gelo, trovão, ácido, madeira. |
| `scripts/ui/` | HUD, menu principal, personagens, level-up, pausa, fim de jogo e tema visual. |
| `assets/generated/` | Sprites gerados: moeda, gemas de XP, coração, portal e cópias 3x do tema de UI. |
| `old/` | Scripts/cenas antigos (ignorados pelo Godot via `.gdignore`). Pode apagar quando quiser. |

## Como uma partida funciona

1. 3 estágios (`DB.STAGES`). Cada um dura `DB.STAGE_TIME` (180 s) e depois aparece o chefão.
2. Derrotou o chefão → surge um portal (a seta roxa aponta para ele). Entrou → próximo estágio, com mapa novo e inimigos mais fortes.
3. Derrotou o chefão do estágio 3 → vitória.
4. Moedas coletadas vão para o banco ao fim da partida (ganhando ou perdendo) e desbloqueiam personagens.

## Balanceamento rápido

- Vida/dano/velocidade dos inimigos: `DB.ENEMIES`.
- Escala com o tempo: `SpawnDirector.hp_mult()` / `dmg_mult()`; quantidade: `rate` e `max_alive` em `_physics_process`.
- Quais inimigos aparecem em cada estágio (e a partir de quando): `"spawn"` em `DB.STAGES`.
- Chefões: `"boss"` em `DB.STAGES`.
- Armas: `stats_for_level()` em cada `scripts/weapons/w_*.gd`.
- Curva de XP: `DB.xp_to_next()`.
- Preço e bônus dos personagens: `DB.CHARACTERS`.

Para zerar o save: chame `Global.reset_save()` (ou apague `user://save.cfg`).
