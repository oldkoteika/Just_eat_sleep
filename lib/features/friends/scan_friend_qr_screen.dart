import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../shared/models/friend.dart';

class ScanFriendQrScreen extends StatefulWidget {
  final bool startWithGallery;
  /// ID уже добавленных друзей — при совпадении показываем "Уже в друзьях".
  final Set<String> existingFriendIds;

  const ScanFriendQrScreen({
    super.key,
    this.startWithGallery = false,
    this.existingFriendIds = const {},
  });

  @override
  State<ScanFriendQrScreen> createState() => _ScanFriendQrScreenState();
}

class _ScanFriendQrScreenState extends State<ScanFriendQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final ImagePicker _imagePicker = ImagePicker();
  bool _isHandlingResult = false;

  @override
  void initState() {
    super.initState();
    if (widget.startWithGallery) {
      // Небольшая задержка, чтобы экран успел построиться перед открытием галереи
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickFromGallery();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_isHandlingResult) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    _isHandlingResult = true;

    final friend = Friend.tryParseFromQrString(rawValue);
    if (!mounted) return;

    if (friend == null) {
      _isHandlingResult = false;
      await _showErrorDialog(
        'Не удалось распознать данные друга.\n'
        'Убедитесь, что QR-код был сгенерирован в приложении Жми Ешь Спи '
        'и не старше ${Friend.qrMaxAgeDays} дней.',
      );
      return;
    }

    if (widget.existingFriendIds.contains(friend.id)) {
      _isHandlingResult = false;
      await _showErrorDialog('Этот пользователь уже в друзьях.');
      return;
    }

    await _controller.stop();
    if (!mounted) return;

    Navigator.of(context).pop(friend);
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        return;
      }

      if (!mounted) return;

      await _controller.analyzeImage(file.path);
    } on Exception catch (_) {
      if (!mounted) return;
      await _showErrorDialog(
        'Не удалось распознать QR-код на изображении.\n'
        'Попробуйте выбрать другое фото.',
      );
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка QR-кода'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ок'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? CupertinoColors.white : CupertinoColors.label;
    final sectionBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Сканировать QR друга'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: _controller,
                    fit: BoxFit.cover,
                    onDetect: _handleBarcodeCapture,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Наведите камеру на QR-код друга '
                    'или выберите изображение с QR-кодом из галереи.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _pickFromGallery,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.photo_on_rectangle,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Выбрать из галереи',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

