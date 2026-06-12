import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animate_do/animate_do.dart';
import '../models/quest.dart';
import '../utils/prefs.dart';
import 'home_screen.dart';
import 'camera_screen.dart';

class WinScreen extends StatefulWidget {
  final Quest quest;
  final List<CollectedItem> collectedItems;
  final int stars;

  const WinScreen({
    super.key,
    required this.quest,
    required this.collectedItems,
    required this.stars,
  });

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  final AudioPlayer _cheerPlayer = AudioPlayer();
  late AnimationController _trophyController;
  late Animation<double> _trophyAnim;
  String _userName = '';

  static const List<Color> _cardColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF6BCB77),
    Color(0xFFA855F7),
  ];

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 6));

    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _trophyAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.elasticOut),
    );

    _startCelebration();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await AppPrefs.getName();
    if (mounted) setState(() => _userName = name ?? 'Explorer');
  }

  Future<void> _startCelebration() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _confettiController.play();
    _trophyController.forward();
    await _cheerPlayer.setVolume(1.0);
    await _cheerPlayer.play(AssetSource('sounds/cheer.mp3'));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cheerPlayer.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    _cheerPlayer.stop();
    final name = await AppPrefs.getName();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(userName: name ?? 'Explorer'),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
          (route) => false,
    );
  }

  Future<void> _playAgain() async {
    _cheerPlayer.stop();
    // Reset this quest progress
    await AppPrefs.resetQuest(widget.quest.id);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CameraScreen(quest: widget.quest),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F4FF), Color(0xFFB8E8FF)],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            ..._buildBgCircles(),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Trophy animation
                    ScaleTransition(
                      scale: _trophyAnim,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D).withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFE66D),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE66D).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆',
                              style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'Quest Complete!',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A6B9E),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Text(
                        'Amazing work, $_userName! 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFF4A9BC2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stars earned
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFE66D),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(
                              3,
                                  (i) => Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  i < widget.stars ? '⭐' : '☆',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.stars} stars earned!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF996600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quest badge
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.quest.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.quest.color.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(widget.quest.emoji,
                                style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.quest.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  'All ${widget.quest.totalItems} items found!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6BCB77),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '✓ Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Collection title
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Collection 📦',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A6B9E),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Collection grid
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: widget.collectedItems.length,
                        itemBuilder: (context, i) {
                          final item = widget.collectedItems[i];
                          final color = _cardColors[i % _cardColors.length];
                          return BounceInUp(
                            delay: Duration(milliseconds: 100 * i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(item.imagePath),
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color
                                          .withOpacity(0.8)
                                          .withRed(
                                          (color.red * 0.7).toInt()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Play Again button
                    FadeInUp(
                      delay: const Duration(milliseconds: 1000),
                      child: GestureDetector(
                        onTap: _playAgain,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: widget.quest.color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.quest.color.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Play Again! 🔄',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Home button
                    FadeInUp(
                      delay: const Duration(milliseconds: 1100),
                      child: GestureDetector(
                        onTap: _goHome,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF4ECDC4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            '🏠 Back to Home',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A6B9E),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                shouldLoop: false,
                colors: _cardColors,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBgCircles() {
    return [
      Positioned(
        top: -40,
        right: -40,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.quest.color.withOpacity(0.08),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4ECDC4).withOpacity(0.07),
          ),
        ),
      ),
      Positioned(
        top: 200,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFE66D).withOpacity(0.1),
          ),
        ),
      ),
    ];
  }
}