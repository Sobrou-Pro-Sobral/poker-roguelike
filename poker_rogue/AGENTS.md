# Poker Roguelike

## Objetivo

Este é um trabalho de ensino médio. O objetivo é criar um jogo single-player de Texas Hold'em com elementos simples de roguelike.

Prioridades:
1. simplicidade de implementação;
2. código fácil de entender e explicar;
3. funcionamento correto;
4. visual fiel ao wireframe;
5. evitar arquitetura complexa ou dependências desnecessárias.

Não transformar o projeto em uma arquitetura profissional exageradamente complexa.

## Stack

- Flutter
- Dart
- Deck of Cards API
- Avaliador de mãos de poker em Dart equivalente ao PokerHandEvaluator
- HTTP apenas quando necessário
- Sem backend próprio
- Sem banco de dados
- Sem Flame
- Sem Riverpod, a menos que seja realmente necessário

## Plataforma

* O aplicativo será desenvolvido exclusivamente para Android.
* Usar Flutter e Dart.
* Priorizar celulares em orientação vertical (portrait).
* Não implementar suporte específico para web, desktop ou iOS.
* Não criar layouts para tablets ou telas grandes, salvo se isso não exigir esforço adicional.
* A interface deve funcionar em diferentes tamanhos de celulares Android.
* Priorizar áreas de toque confortáveis, texto legível e botões posicionados para uso com uma mão.
* Evitar elementos importantes próximos às bordas do sistema, respeitando as áreas seguras da tela.

## Design mobile

* Interface predominantemente branca.
* Vermelho e preto como cores principais.
* Cartas minimalistas com fundo branco, bordas finas e símbolos grandes.
* Mesa organizada verticalmente, com cartas comunitárias no centro.
* Cartas do jogador e ações principais na metade inferior da tela.
* Pote, stacks e informações da rodada devem ser legíveis sem exigir zoom.
* Evitar rolagem durante uma mão de poker, sempre que possível.
* Adaptar espaçamentos e dimensões ao espaço disponível, sem distorcer as cartas.

## Testes e execução

* A plataforma de destino é Android.
* Executar `flutter analyze` e `flutter test`.
* Verificar o aplicativo em um emulador Android ou dispositivo físico.
* Não gastar tempo configurando builds para outras plataformas.
* Manter a configuração Android gerada pelo Flutter, alterando-a apenas quando necessário.


Referências visuais em:
- assets/design/poker_wireframe.png
- assets/design/poker_cards_reference.jpg

Direção visual:
- interface predominantemente branca;
- preto e vermelho como cores principais;
- muito espaço em branco;
- bordas finas;
- tipografia limpa e minimalista;
- cartas simples, com outline preto ou vermelho;
- inspiração geral em aplicativos modernos de poker minimalistas;
- não copiar literalmente interfaces de terceiros.

## Escopo inicial

Implementar primeiro:
1. estrutura inicial do aplicativo;
2. criação e embaralhamento do deck;
3. pré-flop;
4. flop;
5. turn;
6. river;
7. avaliação da mão;
8. fluxo básico da partida.

Elementos roguelike:
- upgrades simples;
- bosses simples;
- progressão entre mesas.

## Regras de desenvolvimento

- Prefira soluções simples.
- Não adicionar bibliotecas sem necessidade.
- Não criar abstrações prematuras.
- Não implementar sistemas futuros antes de serem necessários.
- Manter os arquivos pequenos e compreensíveis.
- Usar nomes claros em inglês no código.
- Interface pode usar textos em inglês para seguir o wireframe.
- Rodar `flutter analyze` e testes depois de alterações relevantes.
- Não alterar partes não relacionadas à tarefa.

## API

Usar a Deck of Cards API:
https://deckofcardsapi.com/

O deck deve ser criado e as cartas devem ser obtidas pela API.

A aplicação deve tratar erros de rede de forma simples e mostrar uma tela/estado de erro compreensível.

## Importante

Não implementar neste momento:
- multiplayer;
- login;
- backend;
- sistema complexo de economia;
- matchmaking;
- inteligência artificial avançada;
- física;
- animações complexas.