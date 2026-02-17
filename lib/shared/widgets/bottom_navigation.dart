import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum AppScreen {
  home,
  calendar,
  friends,
  profile,
}

/// Высота нижней навигации без SafeArea (60 + padding 8*2).
/// Для отступа прокрутки использовать: kBottomNavContentHeight + MediaQuery.padding.bottom
const double kBottomNavContentHeight = 76;

class AppBottomNavigation extends StatelessWidget {
  final AppScreen currentScreen;
  final Function(AppScreen) onScreenChanged;

  const AppBottomNavigation({
    super.key,
    required this.currentScreen,
    required this.onScreenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = CupertinoColors.activeBlue;
    final unselectedColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;
    final navBackgroundColor = (isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6)
        .withOpacity(0.92);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: navBackgroundColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.separator.darkColor
                  : CupertinoColors.separator,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: CupertinoIcons.house_fill,
                label: 'Главная',
                isSelected: currentScreen == AppScreen.home,
                onTap: () => onScreenChanged(AppScreen.home),
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
              ),
              _NavItem(
                icon: CupertinoIcons.calendar,
                label: 'Тренировки',
                isSelected: currentScreen == AppScreen.calendar,
                onTap: () => onScreenChanged(AppScreen.calendar),
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
              ),
              _NavItem(
                icon: CupertinoIcons.person_2_fill,
                label: 'Мои друзья',
                isSelected: currentScreen == AppScreen.friends,
                onTap: () => onScreenChanged(AppScreen.friends),
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
              ),
              _NavItem(
                icon: CupertinoIcons.person_fill,
                label: 'Профиль',
                isSelected: currentScreen == AppScreen.profile,
                onTap: () => onScreenChanged(AppScreen.profile),
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
