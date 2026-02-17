import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/auth/user_storage.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/avatar_with_initials.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateHome;

  const ProfileScreen({
    super.key,
    this.onNavigateHome,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const double _avatarSize = 110; // 100 + 10%

  bool _isEditing = false;
  String _profileId = '';
  String _surname = '';
  String _name = '';
  String _patronymic = '';
  String? _avatarPath;
  String _appVersion = '—';
  late TextEditingController _surnameController;
  late TextEditingController _nameController;
  late TextEditingController _patronymicController;
  final ImagePicker _imagePicker = ImagePicker();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _checkingBiometric = true;

  @override
  void initState() {
    super.initState();
    _profileId = _generateProfileId();
    _surnameController = TextEditingController(text: _surname);
    _nameController = TextEditingController(text: _name);
    _patronymicController = TextEditingController(text: _patronymic);
    _loadUser();
    _loadAppVersion();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final enabled = await AuthStorage.isBiometricEnabled();
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      final available = canCheck && supported && biometrics.isNotEmpty;
      if (mounted) {
        setState(() {
          _biometricEnabled = enabled;
          _biometricAvailable = available;
          _checkingBiometric = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
          _biometricEnabled = false;
          _checkingBiometric = false;
        });
      }
    }
  }

  Future<void> _enableBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Подтвердите биометрию для быстрого входа в приложение',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!mounted) return;
      if (authenticated) {
        await AuthStorage.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вход по биометрии включён'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Profile: ошибка включения биометрии $e');
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось включить биометрию: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _disableBiometric() async {
    await AuthStorage.setBiometricEnabled(false);
    if (mounted) {
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  /// Загружает сохранённого пользователя из UserStorage (UUID и ФИО для QR).
  Future<void> _loadUser() async {
    final user = await UserStorage.getCurrentUser();
    if (user == null || !mounted) return;
    final parts = user.name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    setState(() {
      _profileId = user.id;
      _surname = parts.length >= 3 ? parts[0] : (parts.length >= 2 ? parts[0] : '');
      _name = parts.length >= 2 ? parts[1] : (parts.length >= 1 ? parts[0] : '');
      _patronymic = parts.length >= 3 ? parts[2] : '';
      _avatarPath = user.avatarPath;
      _surnameController.text = _surname;
      _nameController.text = _name;
      _patronymicController.text = _patronymic;
    });
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  String get _fullName {
    return [_surname, _name, _patronymic].where((s) => s.isNotEmpty).join(' ');
  }

  /// JSON-данные для QR-кода профиля (добавление в друзья):
  /// - id: UUID пользователя
  /// - name: ФИО
  /// - avatarUrl: путь к аватару (опционально)
  /// - ts: временная метка (мс) для проверки актуальности при сканировании
  String get _qrData {
    final payload = <String, dynamic>{
      'id': _profileId,
      'name': _fullName.isEmpty ? 'Пользователь Жми Ешь Спи' : _fullName,
      'avatarUrl': _avatarPath,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(payload);
  }

  String _generateProfileId() {
    final random = Random();
    String four() =>
        random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');

    // Простейший UUID v4-формат: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return '${four()}${four()}-'
        '${four()}-'
        '${four()}-'
        '${four()}-'
        '${four()}${four()}${four()}';
  }

  String get _initials {
    final parts = [_surname, _name, _patronymic].where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1 && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  void _startEditing() {
    _surnameController.text = _surname;
    _nameController.text = _name;
    _patronymicController.text = _patronymic;
    setState(() => _isEditing = true);
  }

  Future<void> _saveAndExitEditing() async {
    final surname = _surnameController.text.trim();
    final name = _nameController.text.trim();
    final patronymic = _patronymicController.text.trim();
    setState(() {
      _surname = surname;
      _name = name;
      _patronymic = patronymic;
      _isEditing = false;
    });
    final fullName = [surname, name, patronymic].where((s) => s.isNotEmpty).join(' ');
    final user = User(
      id: _profileId,
      name: fullName.isEmpty ? 'Пользователь Жми Ешь Спи' : fullName,
      avatarPath: _avatarPath,
      createdAt: DateTime.now(),
    );
    await UserStorage.saveCurrentUser(user);
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      setState(() => _avatarPath = file.path);
    }
  }

  bool _getCurrentThemeBool(ThemeMode mode, bool isDark) {
    if (mode == ThemeMode.system) return isDark;
    return mode == ThemeMode.dark;
  }

  void _openQrView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final cardBg = isDark ? CupertinoColors.black : CupertinoColors.white;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _QrViewSheet(
        qrData: _qrData,
        sectionBg: sectionBg,
        textColor: textColor,
        cardBg: cardBg,
        isDark: isDark,
        onShareText: () => Share.share(
          _qrData,
          subject: 'Мой QR-код Жми Ешь Спи',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final secondaryTextColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;
    final inputBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final sectionBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;

    return AppScaffold(
      title: 'Профиль',
      onHomePressed: widget.onNavigateHome,
      rightIcon: _isEditing ? CupertinoIcons.checkmark : CupertinoIcons.pencil,
      onAddPressed: _isEditing ? _saveAndExitEditing : _startEditing,
      body: ListView(
        padding: EdgeInsets.only(
          top: AppScaffold.kTopBarHeight + AppScaffold.kContentTopGap,
          bottom: kBottomNavContentHeight + MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
        ),
        children: [
          const SizedBox(height: 24),
          // Аватар (+10% размера); в режиме редактирования — тап открывает камеру, иконка камеры снизу сбоку
          Center(
            child: _buildProfileAvatar(sectionBg, isDark),
          ),
          const SizedBox(height: 20),
          // Блок ФИО
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isEditing ? _buildFioForm(isDark, inputBg, textColor) : _buildFioView(textColor, secondaryTextColor),
          ),
          const SizedBox(height: 20),
          // Переключатель темы
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                      color: textColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Тема',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                CupertinoSwitch(
                  value: _getCurrentThemeBool(currentThemeMode, isDark),
                  onChanged: (bool value) {
                    final newThemeMode = value ? ThemeMode.dark : ThemeMode.light;
                    ref.read(themeModeProvider.notifier).setTheme(newThemeMode);
                  },
                ),
              ],
            ),
          ),
          if (!_checkingBiometric && _biometricAvailable) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.lock_rotation_open,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вход по биометрии',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _biometricEnabled,
                    onChanged: (bool value) {
                      if (value) {
                        _enableBiometric();
                      } else {
                        _disableBiometric();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          if (kIsWeb && !_checkingBiometric) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.lock_rotation_open,
                    color: secondaryTextColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вход по биометрии (Face ID / Touch ID) доступен в мобильном приложении на Android и iOS.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // QR-код (тап — просмотр; в просмотре есть «Поделиться»)
          GestureDetector(
            onTap: _openQrView,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Мой QR-код',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? CupertinoColors.black : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // О приложении
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'О приложении',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Жми Ешь Спи помогает планировать тренировки вместе с друзьями: создавайте события, '
                  'добавляйте друзей по QR-коду, приглашайте их на тренировки и синхронизируйте расписание с календарём устройства.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ФИО, аватар и список друзей хранятся на устройстве. Для доставки приглашений на совместные тренировки используется облачная синхронизация; '
                  'личные события остаются только у вас. Мы не передаём ваши данные третьим лицам.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Версия',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      _appVersion,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Color sectionBg, bool isDark) {
    final avatar = _avatarPath != null && File(_avatarPath!).existsSync()
        ? ClipOval(
            child: Image.file(
              File(_avatarPath!),
              width: _avatarSize,
              height: _avatarSize,
              fit: BoxFit.cover,
            ),
          )
        : AvatarWithInitials(initials: _initials, size: _avatarSize);

    if (!_isEditing) {
      return avatar;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickImageFromCamera,
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: sectionBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? CupertinoColors.systemBackground : CupertinoColors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: isDark ? CupertinoColors.white : CupertinoColors.label,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFioView(Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FioLabel('Фамилия', secondaryTextColor),
        const SizedBox(height: 4),
        Text(
          _surname.isEmpty ? '—' : _surname,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
        const SizedBox(height: 16),
        _FioLabel('Имя', secondaryTextColor),
        const SizedBox(height: 4),
        Text(
          _name.isEmpty ? '—' : _name,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
        const SizedBox(height: 16),
        _FioLabel('Отчество', secondaryTextColor),
        const SizedBox(height: 4),
        Text(
          _patronymic.isEmpty ? '—' : _patronymic,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ],
    );
  }

  Widget _buildFioForm(bool isDark, Color inputBg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FioLabel('Фамилия', textColor.withValues(alpha: 0.6)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _surnameController,
          placeholder: 'Введите фамилию',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          style: TextStyle(fontSize: 16, color: textColor),
          onSubmitted: (_) => _saveAndExitEditing(),
        ),
        const SizedBox(height: 16),
        _FioLabel('Имя', textColor.withValues(alpha: 0.6)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Введите имя',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          style: TextStyle(fontSize: 16, color: textColor),
          onSubmitted: (_) => _saveAndExitEditing(),
        ),
        const SizedBox(height: 16),
        _FioLabel('Отчество', textColor.withValues(alpha: 0.6)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _patronymicController,
          placeholder: 'Введите отчество',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          style: TextStyle(fontSize: 16, color: textColor),
          onSubmitted: (_) => _saveAndExitEditing(),
        ),
      ],
    );
  }
}

class _FioLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _FioLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _QrViewSheet extends StatefulWidget {
  final String qrData;
  final Color sectionBg;
  final Color textColor;
  final Color cardBg;
  final bool isDark;
  final VoidCallback? onShareText;

  const _QrViewSheet({
    required this.qrData,
    required this.sectionBg,
    required this.textColor,
    required this.cardBg,
    required this.isDark,
    this.onShareText,
  });

  @override
  State<_QrViewSheet> createState() => _QrViewSheetState();
}

class _QrViewSheetState extends State<_QrViewSheet> {
  final GlobalKey _qrBoundaryKey = GlobalKey();

  Future<void> _shareAsImage() async {
    final boundary = _qrBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !mounted) return;
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/zhes_qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Мой QR-код Жми Ешь Спи',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать изображение: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = widget.qrData;
    final sectionBg = widget.sectionBg;
    final textColor = widget.textColor;
    final cardBg = widget.cardBg;
    final isDark = widget.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sectionBg,
                    shape: BoxShape.circle,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(CupertinoIcons.xmark, color: textColor, size: 18),
                  ),
                ),
                Text(
                  'Мой QR-код',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            key: _qrBoundaryKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (widget.onShareText != null)
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: widget.onShareText,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text, color: textColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Текст',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.onShareText != null) const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _shareAsImage,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.photo, color: CupertinoColors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Картинкой',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
