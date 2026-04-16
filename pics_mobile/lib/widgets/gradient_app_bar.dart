import 'package:flutter/material.dart';

/// Shared brand color constants — used by GradientAppBar, AppDrawer, and
/// any screen that needs to stay visually consistent with FilterHeaderCard.
const Color kAppBarStart = Color(0xFF0D2B57);
const Color kAppBarMid = Color(0xFF123C72);
const Color kAppBarEnd = Color(0xFF1B568F);
const Color kAccentTeal = Color(0xFF00BFA5);
const Color kDrawerBackground = Color(0xFF0A2347);
// Calmer / darker teal gradient for less-flashy accents
const Color kCalmTealStart = Color(0xFF00796B); // teal700
const Color kCalmTealMid = Color(0xFF00695C);   // teal800
const Color kCalmTealEnd = Color(0xFF004D40);   // teal900

/// A drop-in replacement for [AppBar] that renders the brand gradient
/// (matching [FilterHeaderCard]) as a horizontal background.
///
/// Implements [PreferredSizeWidget] so it can be used directly as the
/// `appBar` property of a [Scaffold].
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
    this.gradientColors,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  /// When set, replaces the default gradient with a solid background color.
  final Color? backgroundColor;
  /// Optional custom gradient colors for the app bar background.
  /// If null, falls back to the brand gradient (`kAppBarStart..kAppBarEnd`).
  final List<Color>? gradientColors;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: backgroundColor != null
            ? BoxDecoration(color: backgroundColor)
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradientColors ??
                      const [kAppBarStart, kAppBarMid, kAppBarEnd],
                ),
              ),
      ),
    );
  }
}
