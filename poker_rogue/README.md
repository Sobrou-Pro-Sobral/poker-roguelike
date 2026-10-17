# Poker Rogue

Jogo Flutter single-player de Texas Hold'em contra um adversário simples, com cinco mesas, dois bosses, recompensas e quatro upgrades.

## Requisitos

- Flutter estável com Dart compatível com o `pubspec.yaml`.
- Android SDK e um emulador ou celular Android para executar o aplicativo.
- Conexão com a internet durante a partida para acessar a Deck of Cards API.

## Instalação

Na raiz do projeto:

```bash
flutter pub get
```

## Executar no Android

Conecte um dispositivo ou inicie um emulador e execute:

```bash
flutter devices
flutter run
```

O projeto prioriza celulares Android em orientação vertical. A interface também pode ser executada no Chrome durante o desenvolvimento:

```bash
flutter run -d chrome
```

## Testes e análise

Os testes de domínio não dependem da internet. Execute:

```bash
dart format lib test
flutter analyze
flutter test
```

## Gerar APK de release

Com o Android SDK configurado:

```bash
flutter build apk --release
```

O APK será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

## API

As cartas são criadas e distribuídas pela [Deck of Cards API](https://deckofcardsapi.com/). O avaliador de mãos, as apostas, a liquidação do pote e a progressão da run permanecem no código Dart do aplicativo.
