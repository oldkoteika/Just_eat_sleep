# Предупреждения сборки iOS

Кратко по каждому предупреждению и что можно сделать.

## Что уже сделано в проекте

- **Podfile**: добавлен `ios/Podfile` с `post_install`, где для всех подов выставляется `IPHONEOS_DEPLOYMENT_TARGET = 13.0`. Это убирает предупреждение **permission_handler_apple** про deployment target 9.0 и диапазон 12.0–26.2.99.
- В том же `post_install` в `GCC_PREPROCESSOR_DEFINITIONS` добавлено `PERMISSION_EVENTS=1` (для permission_handler, как в плане реализации).

Остальные предупреждения идут из нативного кода сторонних плагинов; исправить их можно только обновлением пакетов или правками в исходниках плагинов.

---

## 1. mobile_scanner (Swift)

- **Текст**: `'objc_ownership' only applies to Objective-C object or block pointer types; type here is 'CVPixelBufferRef_Nullable'`.
- **Причина**: код плагина в нативной части.
- **Что делать**: обновлять **mobile_scanner** до последней версии (`flutter pub upgrade mobile_scanner` или явно в `pubspec.yaml`). Если предупреждение остаётся — ждать фикса в репозитории плагина или игнорировать (на сборку обычно не влияет).

---

## 2. add_2_calendar (Add2CalendarPlugin)

- **Текст**: `'statusBarStyle' was deprecated in iOS 13.0`; `'keyWindow' was deprecated in iOS 13.0`.
- **Причина**: плагин использует устаревшие API.
- **Что делать**:
  - Обновить пакет: `add_2_calendar: ^3.0.1` → проверить на pub.dev наличие новой мажорной версии и обновиться.
  - Иначе — ждать обновления от автора или подавить предупреждения в Xcode (не меняя код плагина вручную, т.к. это затруднит обновления).

---

## 3. mobile_scanner (MobileScannerPlugin)

- **Текст**: `'devices(for:) was deprecated in iOS 10.0: Use AVCaptureDeviceDiscoverySession instead`; `Immutable value 'device' was never used`.
- **Причина**: нативный код плагина.
- **Что делать**: обновлять **mobile_scanner**; при необходимости открыть issue/PR в репозитории плагина с заменой на `AVCaptureDeviceDiscoverySession` и удалением неиспользуемой переменной.

---

## 4. permission_handler_apple (PhonePermissionStrategy)

- **Текст**: `'subscriberCellularProvider' is deprecated: first deprecated in iOS 12`.
- **Причина**: код из **permission_handler** (permission_handler_apple).
- **Что делать**: обновлять **permission_handler** до последней версии; при отсутствии фикса — ждать обновление от автора.

---

## 5. permission_handler_apple (deployment target)

- **Текст**: `The ios deployment target IPHONEOS_DEPLOYMENT_TARGET is set to 9.0, but the range of supported deployment target versions is 12.0 to 26.2.99`.
- **Что сделано**: в `ios/Podfile` в `post_install` для всех подов выставляется `IPHONEOS_DEPLOYMENT_TARGET = '13.0'`, что должно убрать это предупреждение после `pod install` / пересборки.

---

## 6. share_plus (FPPSharePlusPlugin)

- **Текст**: `'keyWindow' is deprecated: first deprecated in iOS 13.0`.
- **Причина**: нативный код плагина **share_plus**.
- **Что делать**: обновить **share_plus** (в `pubspec.lock` указана 10.1.4; на pub.dev может быть 12.x). После обновления пересобрать iOS.

---

## Рекомендуемые команды

```bash
flutter pub upgrade
# или точечно:
# flutter pub upgrade mobile_scanner add_2_calendar permission_handler share_plus
```

После изменения `Podfile` на macOS:

```bash
cd ios && pod install && cd ..
```

Имеет смысл периодически проверять `flutter pub outdated` и обновлять плагины, чтобы со временем часть предупреждений исчезла после обновлений авторов пакетов.
