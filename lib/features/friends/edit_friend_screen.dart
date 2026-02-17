import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/models/friend.dart';
import '../../shared/widgets/avatar_with_initials.dart';

class EditFriendScreen extends StatefulWidget {
  final Friend friend;

  const EditFriendScreen({
    super.key,
    required this.friend,
  });

  @override
  State<EditFriendScreen> createState() => _EditFriendScreenState();
}

class _EditFriendScreenState extends State<EditFriendScreen> {
  late TextEditingController _surnameController;
  late TextEditingController _nameController;
  late TextEditingController _patronymicController;
  late String _initials;
  String? _avatarPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Разбираем текущее ФИО друга по пробелам:
    // 0 — фамилия, 1 — имя, 2 — отчество (если есть)
    final parts = widget.friend.name.split(' ').where((p) => p.isNotEmpty).toList();
    final surname = parts.isNotEmpty ? parts[0] : '';
    final name = parts.length > 1 ? parts[1] : '';
    final patronymic = parts.length > 2 ? parts.sublist(2).join(' ') : '';

    _surnameController = TextEditingController(text: surname);
    _nameController = TextEditingController(text: name);
    _patronymicController = TextEditingController(text: patronymic);

    _initials = widget.friend.initials;
    _avatarPath = widget.friend.avatarUrl;
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _save() {
    final surname = _surnameController.text.trim();
    final name = _nameController.text.trim();
    final patronymic = _patronymicController.text.trim();

    // Собираем ФИО как в профиле: только непустые части через пробел
    final fullName = [surname, name, patronymic]
        .where((s) => s.isNotEmpty)
        .join(' ');

    if (fullName.isEmpty) {
      return;
    }

    final updatedFriend = Friend(
      id: widget.friend.id,
      name: fullName,
      avatarUrl: _avatarPath ?? widget.friend.avatarUrl,
      addedAt: widget.friend.addedAt,
      status: widget.friend.status,
    );

    Navigator.of(context).pop(updatedFriend);
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      setState(() {
        _avatarPath = file.path;
      });
    }
  }

  Widget _buildFriendAvatar(bool isDark, Color backgroundColor) {
    const double avatarSize = 110;

    final Widget avatar = _avatarPath != null && File(_avatarPath!).existsSync()
        ? ClipOval(
            child: Image.file(
              File(_avatarPath!),
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
            ),
          )
        : AvatarWithInitials(
            initials: _initials,
            size: avatarSize,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickImageFromCamera,
      child: SizedBox(
        width: avatarSize,
        height: avatarSize,
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
                    color: isDark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.systemBackground
                          : CupertinoColors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemBackground.darkColor
        : CupertinoColors.systemBackground;
    final sectionBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final inputBg = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.systemGrey4.darkColor
                    : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _close,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey6,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                      ),
                    ),
                  ),
                  Text(
                    'Редактирование',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _save,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.check_mark,
                        size: 18,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildFriendAvatar(isDark, backgroundColor),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildFioForm(isDark, inputBg, textColor),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          onSubmitted: (_) => _save(),
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
          onSubmitted: (_) => _save(),
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
          onSubmitted: (_) => _save(),
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
        decoration: TextDecoration.none,
      ),
    );
  }
}


