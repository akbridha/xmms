import 'dart:async';

import 'package:flutter/material.dart';

/// Small utility to show a top-right slide-in notification using an OverlayEntry.
class TopRightNotification {
  /// Show a small toast-style notification at the top-right of the screen.
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopRightToast(
        title: title,
        subtitle: subtitle,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _TopRightToast extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopRightToast({
    Key? key,
    required this.title,
    this.subtitle,
    required this.duration,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_TopRightToast> createState() => _TopRightToastState();
}

class _TopRightToastState extends State<_TopRightToast>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _colorController;
  late final Animation<Color?> _colorAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _colorAnimation = ColorTween(
      begin: Colors.indigoAccent,
      end: Colors.deepOrangeAccent,
    ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));

    // update visual color each frame
    _colorController.addListener(() => setState(() {}));
    _colorController.repeat(reverse: true);

    _slideController.forward();

    _timer = Timer(widget.duration, () => dismiss());
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    _colorController.stop();
    try {
      await _slideController.reverse();
    } catch (_) {}
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.92;

    return Positioned(
      top: 12,
      right: 12,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: dismiss,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: _colorAnimation.value ?? Colors.indigoAccent,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: dismiss,
                      child: const Icon(Icons.close, color: Colors.white54, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
