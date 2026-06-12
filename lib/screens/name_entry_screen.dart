import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/prefs.dart';
import 'home_screen.dart';

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() => _isValid = value.trim().length >= 2);
  }

  Future<void> _saveName() async {
    if (!_isValid) return;
    final name = _nameController.text.trim();
    await AppPrefs.saveName(name);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(userName: name),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFECD2), Color(0xFFFFB347)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Waving hand
                BounceInDown(
                  child: const Text('👋',
                      style: TextStyle(fontSize: 80)),
                ),

                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'Hey Explorer!',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7B2D00),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    "What's your name?",
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF7B2D00).withOpacity(0.7),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Name input
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      onChanged: _onNameChanged,
                      onSubmitted: (_) => _saveName(),
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your name...',
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          child: Text('🧒',
                              style: TextStyle(fontSize: 24)),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Let's Go button
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: _isValid ? _saveName : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _isValid
                            ? const Color(0xFFFF6B6B)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isValid
                            ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B)
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isValid ? "Let's Go! 🚀" : "Type your name first",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _isValid
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Bottom hint
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Text(
                    'Your name is saved on this device only 🔒',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF7B2D00).withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}