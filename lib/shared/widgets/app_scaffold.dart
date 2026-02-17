import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onHomePressed;
  final VoidCallback? onAddPressed;
  final bool showHomeButton;
  final bool showAddButton;
  /// Иконка правой кнопки (по умолчанию CupertinoIcons.add).
  final IconData? rightIcon;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onHomePressed,
    this.onAddPressed,
    this.showHomeButton = true,
    this.showAddButton = true,
    this.rightIcon,
  });

  /// Высота верхней панели (для отступа прокрутки).
  static const double kTopBarHeight = 60;

  /// Дополнительный отступ контента под верхней панелью (чтобы не перекрывался кнопками).
  static const double kContentTopGap = 16;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.black
        : CupertinoColors.systemBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Контент на весь экран — прокручивается под верхнюю панель
            Positioned.fill(
              child: body,
            ),
            // Верхняя панель поверх контента (прозрачный фон)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: kTopBarHeight,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Левая кнопка - дом
                    if (showHomeButton)
                      _CircularButton(
                        icon: CupertinoIcons.house_fill,
                        onPressed: onHomePressed ?? () {},
                      )
                    else
                      const SizedBox(width: 48),
                    // Центральный заголовок (островок)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? CupertinoColors.systemGrey6.darkColor
                                    : CupertinoColors.systemGrey6)
                                .withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? CupertinoColors.separator.darkColor
                                  : CupertinoColors.separator,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    // Правая кнопка (плюс или кастомная, напр. редактирование)
                    if (showAddButton)
                      _CircularButton(
                        icon: rightIcon ?? CupertinoIcons.add,
                        onPressed: onAddPressed ?? () {},
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircularButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = (isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6)
        .withOpacity(0.92);
    final iconColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;

    final borderColor = isDark
        ? CupertinoColors.separator.darkColor
        : CupertinoColors.separator;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }
}
