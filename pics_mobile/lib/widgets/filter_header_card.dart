import 'package:flutter/material.dart';

class FilterHeaderCard extends StatelessWidget {
  const FilterHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  static const Color foregroundColor = Colors.white;
  static const Color secondaryForegroundColor = Color(0xFFD6E4FF);
  static const Color fieldFillColor = Color(0x1AFFFFFF);
  static const Color fieldBorderColor = Color(0x3DFFFFFF);
  static const Color menuColor = Color(0xFF143A6A);

  static const TextStyle labelStyle = TextStyle(
    color: secondaryForegroundColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle valueStyle = TextStyle(
    color: foregroundColor,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static final ButtonStyle actionButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: fieldFillColor,
    side: const BorderSide(color: fieldBorderColor),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D2B57),
            Color(0xFF123C72),
            Color(0xFF1B568F),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26071A34),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -28,
              child: Container(
                width: 148,
                height: 148,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x4D8BC3FF),
                      Color(0x008BC3FF),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -44,
              left: -18,
              child: Container(
                width: 124,
                height: 124,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x332A7CE8),
                      Color(0x002A7CE8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: DefaultTextStyle(
                style: textTheme.bodyMedium?.copyWith(color: foregroundColor) ??
                    const TextStyle(color: foregroundColor),
                child: IconTheme(
                  data: const IconThemeData(color: foregroundColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x26FFFFFF),
                              ),
                            ),
                            child: Icon(icon, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleMedium?.copyWith(
                                        color: foregroundColor,
                                        fontWeight: FontWeight.w700,
                                      ) ??
                                      const TextStyle(
                                        color: foregroundColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: textTheme.bodySmall?.copyWith(
                                        color: secondaryForegroundColor,
                                        height: 1.35,
                                      ) ??
                                      const TextStyle(
                                        color: secondaryForegroundColor,
                                        height: 1.35,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterControlSurface extends StatelessWidget {
  const FilterControlSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: FilterHeaderCard.fieldFillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FilterHeaderCard.fieldBorderColor),
      ),
      child: child,
    );
  }
}