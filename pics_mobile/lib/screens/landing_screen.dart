import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gearController;
  late final TextEditingController _nrpController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _nrpController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _gearController.dispose();
    _nrpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final nrp = _nrpController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (nrp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NRP tidak boleh kosong')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.login(
        nrp: nrp,
        password: password,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        // Save logged-in user to global state
        AppConfig.setLoggedInUser(response.data!);

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        // Show error message from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: _gearController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: _gearController.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(220, 220),
                                  painter: _GearPainter(
                                    toothCount: 12,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              ClipOval(
                                child: Image.asset(
                                  'logo-sm.png',
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nrpController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'NRP',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  const _GearPainter({required this.toothCount, required this.color});

  final int toothCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 * 0.94;
    final innerR = outerR * 0.78;
    final holeR = outerR * 0.56;

    final segmentAngle = 2 * math.pi / toothCount;
    final toothHalf = segmentAngle * 0.22;

    final path = Path()..fillType = PathFillType.evenOdd;

    for (int i = 0; i < toothCount; i++) {
      final baseAngle = segmentAngle * i - math.pi / 2;
      final t0 = baseAngle - toothHalf;
      final t1 = baseAngle + toothHalf;
      final nextT0 = baseAngle + segmentAngle - toothHalf;

      if (i == 0) {
        path.moveTo(
          center.dx + innerR * math.cos(t0),
          center.dy + innerR * math.sin(t0),
        );
      }

      // Rise to tooth tip
      path.lineTo(
        center.dx + outerR * math.cos(t0),
        center.dy + outerR * math.sin(t0),
      );

      // Tooth tip arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerR),
        t0,
        2 * toothHalf,
        false,
      );

      // Fall to root
      path.lineTo(
        center.dx + innerR * math.cos(t1),
        center.dy + innerR * math.sin(t1),
      );

      // Valley arc to next tooth
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerR),
        t1,
        nextT0 - t1,
        false,
      );
    }

    path.close();

    // Hollow center
    path.addOval(Rect.fromCircle(center: center, radius: holeR));

    // Subtle drop shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GearPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.toothCount != toothCount;
}
