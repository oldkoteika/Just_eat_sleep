import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Модель контакта для виджета
class ContactItem {
  final String id;
  final String name;
  final String? avatarInitials;
  final DateTime lastActivityDate;

  ContactItem({
    required this.id,
    required this.name,
    this.avatarInitials,
    required this.lastActivityDate,
  });

  String get initials {
    if (avatarInitials != null) return avatarInitials!;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}

/// Виджет последних контактов для главной страницы
class RecentContactsWidget extends StatelessWidget {
  final List<ContactItem> contacts;
  final VoidCallback onTap;
  final Function(ContactItem)? onContactTap;

  const RecentContactsWidget({
    super.key,
    required this.contacts,
    required this.onTap,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final secondaryTextColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с иконкой
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.person_2_fill,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Друзья',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Список контактов
          if (contacts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Нет контактов',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final contactsList = contacts.take(3).toList();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: contactsList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contact = entry.value;
                      final isLast = index == contactsList.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Контакт
                          GestureDetector(
                            onTap: () {
                              onContactTap?.call(contact);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Аватар с инициалами
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        contact.initials,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.activeBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Имя
                                  Expanded(
                                    child: Text(
                                      contact.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Разделитель (кроме последнего элемента)
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: secondaryTextColor.withOpacity(0.3),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
