# Aurora (codinome provisório)

RPG de mundo aberto para Roblox. Identidade, nomes e criaturas próprios.

## Estado

| Etapa | Situação |
|---|---|
| 0. Fundação (estrutura, rede, salvamento) | Escrita, **ainda não testada no Studio** |
| 1. Combate mínimo (campo, inimigos, ataque, vida, fôlego, XP, nível) | Escrita, **ainda não testada no Studio** |
| 2. Atributos e classes | Fórmulas prontas; falta interface de distribuição e classes |
| 3 a 7 | Não iniciadas |

## Como abrir no Studio

1. Instale o [Rojo](https://rojo.space) (plugin do Studio + programa de linha de comando).
2. Nesta pasta: `rojo serve`
3. No Studio, abra um place vazio (modelo Baseplate), clique em **Rojo → Connect** e depois em **Play**.

O mundo de teste é gerado por código ao iniciar o servidor.

## Controles

| Ação | Teclado | Controle | Celular |
|---|---|---|---|
| Atacar | Clique esquerdo | R2 | Botão "Atacar" |
| Correr | Shift | L3 | Botão "Correr" |

## Estrutura

```
src/shared/Data        Conteúdo: atributos, inimigos, regiões
src/shared/Formulas    Todas as contas de balanceamento
src/shared/Net         RemoteEvents
src/server/Services    Um módulo por sistema; o servidor decide tudo
src/client/Controllers Entrada e interface; o cliente só pede e exibe
```

Para criar um inimigo: nova entrada em `Data/Enemies` e um grupo em `Data/Regions`.
Para rebalancear: `Formulas.luau`.

## O que verificar no primeiro playtest

- Output sem erros ao iniciar.
- Inimigos apoiados no chão (se flutuarem ou afundarem, ajustar `HipHeight` em `EnemyService`).
- Animação de golpe tocando (exige avatar R15).
- Sair e voltar mantém nível e XP (exige place publicado com acesso de API aos DataStores).
