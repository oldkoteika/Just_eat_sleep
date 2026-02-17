import 'package:flutter/cupertino.dart';

/// Аватар с инициалами в стиле карточки друга (iOS).
/// Круг 100×100, фон activeBlue 20%, инициалы по центру.
class AvatarWithInitials extends StatelessWidget {
  final String initials;
  final double size;

  const AvatarWithInitials({
    super.key,
    required this.initials,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.activeBlue,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
