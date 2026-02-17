import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/auth/user_storage.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/avatar_with_initials.dart';
import 'pin_setup_screen.dart';

/// Экран первичного заполнения профиля при первом запуске.
/// После успешного сохранения переводит пользователя на настройку PIN.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const double _avatarSize = 110;

  final _surnameController = TextEditingController();
  final _nameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _avatarPath;
  bool _saving = false;

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = [
      _surnameController.text.trim(),
      _nameController.text.trim(),
      _patronymicController.text.trim(),
    ].where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1 && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      setState(() => _avatarPath = file.path);
    }
  }

  Future<void> _save() async {
    final surname = _surnameController.text.trim();
    final name = _nameController.text.trim();

    if (surname.isEmpty && name.isEmpty) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Заполните имя или фамилию'),
          content: const Text('Для продолжения нужно указать хотя бы одно обязательное поле: имя или фамилию.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final patronymic = _patronymicController.text.trim();
    final fullName = [surname, name, patronymic].where((s) => s.isNotEmpty).join(' ');
    final userId = const Uuid().v4();
    final user = User(
      id: userId,
      name: fullName,
      avatarPath: _avatarPath,
      createdAt: DateTime.now(),
    );
    await UserStorage.saveCurrentUser(user);
    await AuthStorage.setProfileCompleted();

    if (!mounted) return;

    setState(() => _saving = false);
    
    // Используем context из текущего виджета для навигации
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => const PinSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.label;
    final secondaryTextColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2;
    final inputBg = isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6;
    final sectionBg = isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6;

    return AppScaffold(
      title: 'Профиль',
      // На первом запуске не даём выйти назад в главное.
      showHomeButton: false,
      showAddButton: false,
      body: ListView(
        padding: EdgeInsets.only(
          top: AppScaffold.kTopBarHeight + AppScaffold.kContentTopGap,
          bottom: MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
        ),
        children: [
          const SizedBox(height: 24),
          Center(
            child: _buildProfileAvatar(sectionBg, isDark),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Фамилия', secondaryTextColor),
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
                ),
                const SizedBox(height: 16),
                _buildLabel('Имя', secondaryTextColor),
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
                ),
                const SizedBox(height: 16),
                _buildLabel('Отчество', secondaryTextColor),
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CupertinoActivityIndicator()
                  : const Text(
                      'Продолжить',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
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

  Widget _buildLabel(String text, Color color) {
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

