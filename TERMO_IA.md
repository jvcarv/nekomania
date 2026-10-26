# Termo de Uso de Inteligência Artificial

## 1. Uso de Inteligência Artificial

A equipe [Nome da equipe] declara que foi feito o uso de ferramentas de inteligência artificial (IA) no desenvolvimento do jogo **Nekomania**, **somente no código e em textos**. Nenhuma arte, sprite, textura, interface, música, efeito sonoro ou dublagem foi gerado por IA: todos vêm de pacotes de terceiros com licença permitida ou são autorais (ver `CREDITOS.md`).

A lista completa, arquivo por arquivo, está em `IA_TRANSPARENCIA.md`. Os commits feitos com auxílio de IA têm a linha `Co-Authored-By: Claude` (`git log --grep "Co-Authored-By: Claude"`).

## 2. Ferramentas utilizadas

| Ferramenta | Finalidade | Etapa ou funcionalidade do projeto |
|------------|------------|------------------------------------|
| Claude (Anthropic), no app Claude / Cowork | Escrita, depuração e balanceamento de código GDScript | Praticamente todo `scripts/` (jogador, inimigos, chefões, 14 poderes, mapa procedural, spawns, XP, moedas/desbloqueios, desafios, áudio, interface: menus, HUD, level-up, pausa, compêndio) e as cenas em `scenes/` |
| Claude (Anthropic) | Textos de interface e de dados | Nomes/descrições padrão de personagens, poções, poderes, inimigos e chefões (`scripts/data/db.gd`, `data/nomes.json` — editáveis pela equipe), textos de menus e documentação (`LEIA-ME_DEV.md`, `IA_TRANSPARENCIA.md`) |
| Claude (Anthropic) | Organização de assets (sem criar arte/som) | Escolha de tiles e sons dos pacotes CC0, ampliação 3x (pixel a pixel) dos sprites de UI, montagem procedural do mapa com tiles existentes |

## 3. Declaração

Declaramos que as informações apresentadas neste documento são verdadeiras e que o uso de ferramentas de inteligência artificial foi informado de forma transparente.
