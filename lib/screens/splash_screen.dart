import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/prefs.dart';
import 'name_entry_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo scale animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  // Continuous floating animation
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  // Shimmer / glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // Rotating ring
  late AnimationController _ringController;

  final List<_FloatingEmoji> _emojis = [];

  @override
  void initState() {
    super.initState();

    // Logo bounce in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();

    // Float up/down
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Rotating ring
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Generate floating emojis
    _emojis.addAll(_generateEmojis());

    // Navigate after 3.2 seconds
    Future.delayed(const Duration(milliseconds: 3200), _checkAndNavigate);
  }

  List<_FloatingEmoji> _generateEmojis() {
    final rng = Random();
    final list = [
      '🌸', '🐾', '🍎', '🚗', '🌿', '🏠',
      '⭐', '🎉', '🌈', '🦋', '🌻', '🎈',
    ];
    return List.generate(12, (i) {
      return _FloatingEmoji(
        emoji: list[i % list.length],
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 20 + rng.nextDouble() * 22,
        speed: 1200 + rng.nextInt(800),
        offset: rng.nextDouble() * 2000,
      );
    });
  }

  Future<void> _checkAndNavigate() async {
    final name = await AppPrefs.getName();
    if (!mounted) return;

    if (name == null || name.isEmpty) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const NameEntryScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(userName: name),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2041),
              Color(0xFF1A3A6B),
              Color(0xFF0D5C8A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating emoji particles ─────────────────────────────────
            ..._emojis.map((e) => _buildFloatingEmoji(e, size)),

            // ── Big soft background glow ─────────────────────────────────
            Positioned(
              top: size.height * 0.2,
              left: size.width * 0.1,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4)
                            .withOpacity(_glowAnim.value * 0.25),
                        blurRadius: 120,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo area
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_floatAnim, _logoScale, _glowAnim]),
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer rotating ring
                              RotationTransition(
                                turns: _ringController,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF4ECDC4)
                                          .withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _DashedCirclePainter(
                                      color: const Color(0xFF4ECDC4)
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),

                              // Middle ring
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                              ),

                              // Glow behind logo
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4ECDC4)
                                          .withOpacity(_glowAnim.value * 0.6),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),

                              // Main logo circle
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4ECDC4),
                                      const Color(0xFF2BB5AC),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4ECDC4)
                                          .withOpacity(0.5),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '🔍',
                                    style: TextStyle(fontSize: 56),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // App name with letter spacing
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 600),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFF4ECDC4)],
                      ).createShader(bounds),
                      child: const Text(
                        'SPROUT',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '✨  Little minds. Big adventures.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Quest preview pills
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: _buildQuestPills(),
                  ),

                  const SizedBox(height: 48),

                  // Animated loading bar
                  FadeInUp(
                    delay: const Duration(milliseconds: 1100),
                    child: _buildLoadingBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingEmoji(_FloatingEmoji e, Size size) {
    return Positioned(
      left: e.x * size.width,
      top: e.y * size.height,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final offset = sin(
            (_floatController.value * 2 * pi) + e.offset,
          ) *
              12;
          return Transform.translate(
            offset: Offset(0, offset),
            child: Opacity(
              opacity: 0.18,
              child: Text(
                e.emoji,
                style: TextStyle(fontSize: e.size),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestPills() {
    final quests = [
      ('🌸', 'Flowers'),
      ('🐾', 'Animals'),
      ('🚗', 'Vehicles'),
      ('🍎', 'Food'),
      ('🌿', 'Nature'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: quests.length,
        itemBuilder: (_, i) {
          return BounceInLeft(
            delay: Duration(milliseconds: 900 + (i * 100)),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(quests[i].$1,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    quests[i].$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2800),
      builder: (_, value, __) {
        return Column(
          children: [
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4ECDC4),
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value < 0.4
                  ? 'Loading adventures...'
                  : value < 0.8
                  ? 'Preparing quests...'
                  : 'Almost ready! 🚀',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Floating emoji data model ──────────────────────────────────────────────────
class _FloatingEmoji {
  final String emoji;
  final double x;
  final double y;
  final double size;
  final int speed;
  final double offset;

  const _FloatingEmoji({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
  });
}

// ── Dashed circle painter ──────────────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 20;
    const dashLength = 0.15;
    const gapLength = 0.16;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashLength + gapLength) * pi;
      final sweepAngle = dashLength * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}