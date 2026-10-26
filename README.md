# Neko Arcano

Jogo feito para a **IFPF Game Jam** — tema **"Cute Animals and Alchemy"**.

Gatinhos alquimistas bebem poções para ganhar poderes elementais e sobreviver às hordas
da floresta encantada. Um *roguelite* de sobrevivência no estilo Megabonk / Vampire Survivors:
os poderes atacam sozinhos, você só se move, coleta cristais de XP e escolhe melhorias.

## Jogar

- **Navegador:** [link do itch.io — preencher]
- **Windows (64-bit):** baixe o `.zip` em [Releases / itch.io — preencher], extraia e abra `NekoArcano.exe`.

### Controles

| Ação | Teclado | Controle |
|---|---|---|
| Mover | WASD / setas | Analógico esquerdo |
| Escolher carta no level-up | 1, 2, 3 ou A/D + Enter | D-pad + A |
| Pausar | ESC / P | Start |

## Como funciona

- 7 elementos (fogo, sagrado, sombrio, gelo, trovão, ácido, madeira), 2 poderes por elemento, cada um vindo de uma **poção**. Até 5 poderes por partida; os 2 do mesmo elemento ativam **sinergia**.
- 3 estágios em biomas sorteados, cada um com um **chefão** com ataques próprios.
- Moedas desbloqueiam **32 gatinhos**, alguns só depois de cumprir **desafios**.
- **Compêndio** com todos os gatos, inimigos e chefões e suas animações.

## Documentos da jam

- [`CREDITOS.md`](CREDITOS.md) — todos os assets externos e suas licenças.
- [`TERMO_IA.md`](TERMO_IA.md) — uso de IA (somente código e textos; nenhuma arte ou som gerado por IA).
- [`IA_TRANSPARENCIA.md`](IA_TRANSPARENCIA.md) — detalhamento arquivo por arquivo.
- [`LEIA-ME_DEV.md`](LEIA-ME_DEV.md) — guia do código.

## Rodar pelo código-fonte

Abra a pasta no **Godot 4.7** e aperte F5. A cena principal é `scenes/ui/main_menu.tscn`.
