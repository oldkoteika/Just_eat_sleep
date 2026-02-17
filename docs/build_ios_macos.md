# Сборка приложения под iPhone на MacBook

Подробная инструкция по компиляции Flutter-приложения для iPhone на компьютере Mac с macOS. Сборка под iOS возможна **только на Mac** — на Windows или Linux собрать IPA нельзя.

---

## 1. Требования

### 1.1 Оборудование и ОС
- **Компьютер:** Mac (MacBook, iMac, Mac mini, Mac Studio) с macOS.
- **Рекомендуется:** актуальная версия macOS (Sonoma 14.x или новее).

### 1.2 Необходимое ПО
- **Xcode** — последняя стабильная версия из App Store.
- **Xcode Command Line Tools** — для сборки из терминала.
- **CocoaPods** — менеджер зависимостей для iOS (часто ставится вместе с Flutter).
- **Flutter SDK** — установленный и настроенный (`flutter doctor` без критичных ошибок для iOS).

### 1.3 Учётные записи
- **Apple ID** — для установки Xcode и (опционально) для подписи и запуска на устройстве.
- **Apple Developer Program** ($99/год) — **обязателен** для публикации в App Store и для некоторых типов распространения (ad-hoc, enterprise). Для локальной установки на свой iPhone через Xcode достаточно бесплатного Apple ID.

---

## 2. Установка и настройка окружения

### 2.1 Установка Xcode
1. Откройте **App Store** на Mac.
2. Найдите **Xcode** и нажмите **Установить** / **Обновить**.
3. После установки откройте Xcode один раз и примите лицензию.
4. При необходимости установите дополнительные компоненты (например, симуляторы iOS).

### 2.2 Xcode Command Line Tools
1. В терминале выполните:
   ```bash
   xcode-select --install
   ```
2. В диалоге выберите **Установить**.
3. Убедитесь, что активная среда разработки — Xcode:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

### 2.3 CocoaPods
1. Установка (если ещё не установлен):
   ```bash
   sudo gem install cocoapods
   ```
   Или через Homebrew:
   ```bash
   brew install cocoapods
   ```
2. Проверка:
   ```bash
   pod --version
   ```

### 2.4 Flutter и iOS
1. Установите Flutter по [официальной инструкции](https://docs.flutter.dev/get-started/install/macos).
2. Проверьте окружение:
   ```bash
   flutter doctor
   ```
3. Должны быть галочки для **Flutter**, **Xcode** и **CocoaPods**. При наличии предупреждений выполните предложенные команды (например, `flutter doctor --android-licenses` не относится к iOS, но общие предупреждения лучше закрыть).

---

## 3. Подготовка проекта

### 3.1 Клонирование / открытие проекта
```bash
cd /путь/к/проекту/fit_app_peer_to_peer
```

### 3.2 Зависимости
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3.3 Версия и сборка в pubspec.yaml
В корне проекта откройте `pubspec.yaml`. Строка версии:
```yaml
version: 1.0.0+1
```
- **1.0.0** — версия для пользователя (CFBundleShortVersionString в iOS).
- **1** — номер сборки (CFBundleVersion в iOS).

Для каждой новой загрузки в App Store/TestFlight номер сборки должен быть **больше** предыдущего. Пример для следующего релиза: `1.0.0+2` или `1.0.1+1`.

---

## 4. Настройка подписи и Xcode

### 4.1 Открытие проекта в Xcode
```bash
open ios/Runner.xcworkspace
```
Важно: открывать именно **Runner.xcworkspace**, а не Runner.xcodeproj.

### 4.2 Выбор целевого приложения
1. В левой панели (Navigator) выберите **Runner** (корневой проект).
2. В центральной части выберите таргет **Runner** (под проектом).

### 4.3 Вкладка «General»
- **Display Name** — имя приложения на главном экране.
- **Bundle Identifier** — уникальный идентификатор (например, `com.yourcompany.fit_app_peer_to_peer`). Должен совпадать с App ID в Apple Developer и в App Store Connect, если планируете публикацию.

### 4.4 Вкладка «Signing & Capabilities»
- Включите **Automatically manage signing**.
- В поле **Team** выберите вашу команду (Apple Developer). Если команды нет — нажмите **Add Account...** и войдите с Apple ID (для публикации нужен аккаунт Apple Developer Program).
- Убедитесь, что ошибок подписи нет (Xcode сам создаст/подтянет Provisioning Profile при необходимости).

### 4.5 Минимальная версия iOS
Во вкладке **General** или **Build Settings** проверьте **iOS Deployment Target**. Flutter поддерживает iOS 12.0 и выше; для современных проектов часто ставят iOS 13.0 или выше. Зависимости (в т.ч. из CocoaPods) могут диктовать минимум (например, iOS 13).

### 4.6 Иконка и экран запуска
- Иконка: в Xcode откройте **Runner → Assets.xcassets → AppIcon**, замените плейсхолдеры на свои изображения по [рекомендациям Apple](https://developer.apple.com/design/human-interface-guidelines/app-icons).
- Экран запуска (Launch Screen): в **Assets.xcassets** настройте **LaunchImage** при необходимости.

После изменений можно закрыть Xcode и продолжать в терминале.

---

## 5. Сборка IPA (релиз для App Store / TestFlight)

### 5.1 Базовая команда
В корне проекта выполните:
```bash
flutter build ipa
```
Эта команда:
- компилирует приложение в режиме release;
- создаёт архив в `build/ios/archive/`;
- формирует IPA в `build/ios/ipa/`.

### 5.2 Указание версии и номера сборки
Чтобы не менять `pubspec.yaml` каждый раз:
```bash
flutter build ipa --build-name=1.0.0 --build-number=2
```

### 5.3 Обфускация (опционально)
Чтобы усложнить обратную разработку Dart-кода:
```bash
flutter build ipa --obfuscate --split-debug-info=build/symbols
```
Папку `build/symbols` сохраняйте для последующей расшифровки стектрейсов.

### 5.4 Другие способы распространения (не App Store)
Если нужно собрать IPA не для App Store, а для ad-hoc или development:
```bash
flutter build ipa --export-method ad-hoc
# или
flutter build ipa --export-method development
```
Для enterprise (внутреннее распространение в компании):
```bash
flutter build ipa --export-method enterprise
```

### 5.5 Использование ExportOptions.plist
Если при первой сборке через Xcode (см. ниже) был создан файл **ExportOptions.plist**, его можно использовать для повторных сборок:
```bash
flutter build ipa --export-options-plist=path/to/ExportOptions.plist
```

### 5.6 Результат сборки
После успешного выполнения:
- **IPA:** `build/ios/ipa/fit_app_peer_to_peer.ipa` (или имя проекта из `pubspec.yaml`);
- **Архив:** `build/ios/archive/Runner.xcarchive`.

IPA можно загружать в App Store Connect (через Transporter или Xcode).

---

## 6. Альтернатива: сборка архива через Xcode

Если нужно больше контроля или автоматическая подпись не подходит:

1. Соберите архив из командной строки (без экспорта IPA):
   ```bash
   flutter build ipa --export-method app-store
   ```
   или откройте `ios/Runner.xcworkspace` в Xcode и выполните **Product → Archive**.

2. После появления архива в **Organizer** (Window → Organizer) выберите его и нажмите **Distribute App**.

3. Выберите способ распространения (App Store Connect, Ad Hoc и т.д.), пройдите шаги подписи и экспорта.

4. При экспорте Xcode создаёт папку с IPA и файлом **ExportOptions.plist**. Этот plist можно использовать в команде `flutter build ipa --export-options-plist=...` для последующих сборок из терминала.

---

## 7. Установка на свой iPhone (для теста)

### 7.1 Подключение устройства
1. Подключите iPhone кабелем к Mac.
2. На iPhone при необходимости подтвердите «Доверять этому компьютеру».
3. Разблокируйте устройство и при появлении запроса разрешите доступ.

### 7.2 Запуск в режиме release
```bash
flutter run --release
```
Выберите подключённый iPhone в списке устройств. Приложение установится и запустится в release-режиме.

### 7.3 Установка через Xcode
1. Откройте `ios/Runner.xcworkspace` в Xcode.
2. Вверху выберите ваш iPhone как целевое устройство.
3. Нажмите **Run** (▶). Xcode соберёт и установит приложение на устройство.

Для установки на устройство нужна корректная подпись (Team в Signing & Capabilities) и при необходимости регистрация устройства в Apple Developer (для бесплатного аккаунта есть ограничения по срокам действия и количеству устройств).

---

## 8. Типичные проблемы

### «No valid code signing certificates»
- В Xcode: **Signing & Capabilities** → выберите **Team** и включите **Automatically manage signing**.
- Убедитесь, что вы вошли в Apple ID: Xcode → Settings → Accounts.
- Для распространения вне своего устройства нужна подписка Apple Developer Program.

### «CocoaPods not installed» / ошибки pod
```bash
cd ios && pod install --repo-update && cd ..
```
Если не помогло — переустановите CocoaPods и снова выполните `pod install`.

### «Building for iOS, but the linked library was built for macOS»
Обычно связано с неправильной архитектурой или устаревшим pod. Обновите зависимости:
```bash
cd ios && pod update && cd ..
flutter clean && flutter pub get
```

### Архив не появляется в Organizer
- Убедитесь, что выбран режим **Any iOS Device (arm64)** или реальное устройство, а не симулятор.
- Выполните **Product → Clean Build Folder**, затем снова **Product → Archive**.

### Ошибки подписи при `flutter build ipa`
Проверьте в Xcode **Signing & Capabilities** для таргета Runner и что выбран правильный Team. При использовании **ExportOptions.plist** убедитесь, что он соответствует текущему Bundle ID и способу распространения.

---

## 9. Краткий чеклист перед релизом

- [ ] На Mac установлены Xcode, Command Line Tools, CocoaPods, Flutter.
- [ ] `flutter doctor` показывает готовность к разработке под iOS.
- [ ] В Xcode заданы Bundle Identifier, Display Name, Team и автоматическая подпись.
- [ ] В `pubspec.yaml` указаны актуальные `version` и номер сборки.
- [ ] Иконка и экран запуска настроены в Assets.xcassets.
- [ ] Выполнена команда `flutter build ipa` (при необходимости с `--build-name` и `--build-number`).
- [ ] IPA лежит в `build/ios/ipa/` и готова к загрузке в App Store Connect или к распространению выбранным способом.

Дальнейшие шаги по загрузке в App Store и публикации описаны в документе **Публикация в магазинах приложений** (`store_publishing.md`).
