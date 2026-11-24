# Mapa de Propagação HF (Flutter Android)

Aplicativo Android para radioamadores visualizarem condições de propagação HF em tempo real com:
- Índices solares **SFI** e atividade geomagnética **Kp** direto do NOAA SWPC.
- Mapa interativo com cálculo automático de **Grid Maidenhead** (QTH e destino).
- Traçado de **Círculo Máximo (Great Circle)**, distância em km e azimute (rumo).
- **Linha Cinza (Terminador Solar)** calculada em tempo real (UTC).

## Como gerar o APK sem instalar nada no PC (via GitHub Actions)

1. Crie um repositório no GitHub e envie todos os arquivos deste `.zip`.
2. Acesse a aba **Actions** do repositório no GitHub.
3. Clique em **Build Android APK** e depois em **Run workflow**.
4. Ao finalizar, baixe o artefato `mapa-propagacao-hf-release` contendo o arquivo `app-release.apk`.

## Como gerar o APK localmente (com Flutter instalado)

```bash
flutter create . --platforms=android
flutter pub get
flutter build apk --release
```
O arquivo gerado ficará em `build/app/outputs/flutter-apk/app-release.apk`.
