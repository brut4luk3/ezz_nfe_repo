# Firebase Multi-Env (dev/prod)

## Objetivo
Preparar dois ambientes Firebase com flavors Android:
- `dev` → Firebase `ezz-nfe-dev`
- `prod` → Firebase `ezz-nfe-prod`

## Estrutura de arquivos esperada
- `lib/firebase_options_dev.dart`
- `lib/firebase_options_prod.dart`
- `android/app/src/dev/google-services.json`
- `android/app/src/prod/google-services.json`

## Comandos (na ordem)

### 1) Gerar opções do ambiente dev
```bash
flutterfire configure --project=ezz-nfe-dev
```

Após gerar, renomear o arquivo gerado para:
```
lib/firebase_options_dev.dart
```

### 2) Gerar opções do ambiente prod
```bash
flutterfire configure --project=ezz-nfe-prod
```

Após gerar, renomear o arquivo gerado para:
```
lib/firebase_options_prod.dart
```

### 3) Posicionar os google-services.json por flavor
```
android/app/src/dev/google-services.json
android/app/src/prod/google-services.json
```

## Comandos de execução

### Dev
```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

### Prod
```bash
flutter run --flavor prod --dart-define=FLAVOR=prod
```
