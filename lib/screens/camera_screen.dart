import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animate_do/animate_do.dart';
import '../models/quest.dart';
import '../utils/prefs.dart';
import 'win_screen.dart';

class CollectedItem {
  final String label;
  final String imagePath;
  CollectedItem({required this.label, required this.imagePath});
}

class CameraScreen extends StatefulWidget {
  final Quest quest;
  const CameraScreen({super.key, required this.quest});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isCapturing = false;
  bool _permissionDenied = false;

  late ImageLabeler _labeler;
  final List<CollectedItem> _collected = [];
  String _statusMessage = 'Point at something and tap! 📸';
  String? _lastLabel;
  String? _lastImagePath;
  bool _showToast = false;

  final AudioPlayer _snapPlayer = AudioPlayer();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _toastController;
  late Animation<double> _toastAnim;

  // ── Quest-specific labels ──────────────────────────────────────────────────
  // Each quest has ALLOWED labels — anything not in this list is rejected
  // But same label CAN be captured again as long as it's a different photo
  // We track duplicates by label+index so same object type is allowed multiple times
  static const Map<String, List<String>> _questLabels = {
    'flowers': [
      'flower',
      'rose',
      'tulip',
      'daisy',
      'plant',
      'blossom',
      'petal',
      'sunflower',
      'orchid',
      'lily',
      'bouquet',
      'flora',
      'garden',
      'bloom',
      'floral',
      'vegetation',
      'herb',
      'shrub',
    ],
    'animals': [
      'cat',
      'dog',
      'bird',
      'fish',
      'animal',
      'pet',
      'puppy',
      'kitten',
      'rabbit',
      'hamster',
      'parrot',
      'turtle',
      'wildlife',
      'mammal',
      'reptile',
      'insect',
      'butterfly',
      'bee',
      'frog',
    ],
    'food': [
      'food',
      'fruit',
      'apple',
      'banana',
      'bread',
      'vegetable',
      'snack',
      'meal',
      'drink',
      'juice',
      'cookie',
      'cake',
      'pizza',
      'rice',
      'noodle',
      'soup',
      'sandwich',
      'salad',
      'chocolate',
      'candy',
      'ice cream',
      'egg',
      'cheese',
      'milk',
      'water bottle',
    ],
    'vehicles': [
      'car',
      'vehicle',
      'truck',
      'bus',
      'bicycle',
      'bike',
      'motorcycle',
      'van',
      'taxi',
      'wheel',
      'transport',
      'automobile',
      'scooter',
      'train',
      'airplane',
      'boat',
      'ship',
      'tractor',
      'ambulance',
      'fire truck',
      'jeep',
      'suv',
      'tire',
      'engine',
    ],
    'nature': [
      'tree',
      'leaf',
      'rock',
      'stone',
      'sky',
      'cloud',
      'grass',
      'nature',
      'wood',
      'branch',
      'garden',
      'outdoor',
      'mountain',
      'river',
      'lake',
      'ocean',
      'beach',
      'sand',
      'soil',
      'mud',
      'forest',
      'jungle',
      'hill',
      'valley',
      'waterfall',
      'sunset',
      'sunrise',
      'rain',
      'snow',
      'ice',
      'wind',
      'storm',
    ],
    'household': [
      'furniture',
      'chair',
      'table',
      'lamp',
      'book',
      'bottle',
      'cup',
      'bag',
      'clock',
      'pillow',
      'remote',
      'sofa',
      'couch',
      'bed',
      'shelf',
      'drawer',
      'cabinet',
      'door',
      'window',
      'curtain',
      'carpet',
      'mat',
      'mirror',
      'frame',
      'vase',
      'candle',
      'blanket',
      'towel',
      'brush',
      'comb',
    ],
  };

  @override
  void initState() {
    super.initState();

    _labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.40),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toastAnim = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOut,
    );

    _initCamera();
    _loadExistingProgress();
  }

  Future<void> _loadExistingProgress() async {
    final savedItems = await AppPrefs.getCollectedItems(widget.quest.id);

    if (savedItems.isNotEmpty) {
      final restored = savedItems
          .map(
            (e) => CollectedItem(
              label: e['label'] ?? '',
              imagePath: e['imagePath'] ?? '',
            ),
          )
          .where(
            (item) =>
                item.label.isNotEmpty &&
                item.imagePath.isNotEmpty &&
                // Only restore if image file still exists on device
                File(item.imagePath).existsSync(),
          )
          .toList();

      if (restored.isNotEmpty && mounted) {
        setState(() {
          _collected.addAll(restored);
          _statusMessage =
              'Welcome back! You found ${restored.length} so far! 💪';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _labeler.close();
    _snapPlayer.dispose();
    _pulseController.dispose();
    _toastController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _statusMessage = 'No camera found!');
      return;
    }

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _captureAndLabel() async {
    if (_isCapturing || !_cameraReady) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Looking... 🔍';
      _showToast = false;
    });

    try {
      await _snapPlayer.play(AssetSource('sounds/snap.mp3'));

      final photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final labels = await _labeler.processImage(inputImage);

      if (labels.isEmpty) {
        setState(() {
          _statusMessage = "Can't see that clearly. Try again! 🤔";
          _isCapturing = false;
        });
        return;
      }

      // ── Check if any detected label matches quest theme ────────────────
      final allowed = _questLabels[widget.quest.id] ?? [];
      String? matchedLabel;

      for (final label in labels) {
        final clean = label.label.toLowerCase();
        final isMatch = allowed.any(
          (target) => clean.contains(target) || target.contains(clean),
        );
        if (isMatch) {
          matchedLabel = _cleanLabel(label.label);
          break;
        }
      }

      // Reject if not related to quest theme
      if (matchedLabel == null) {
        setState(() {
          _statusMessage =
              "That's not part of ${widget.quest.title}! Try something else 😊";
          _isCapturing = false;
        });
        return;
      }

      // ── Duplicate check — same label allowed if different photo ────────
      // Count how many times this label already collected
      final sameCount = _collected
          .where(
            (item) => item.label.toLowerCase() == matchedLabel!.toLowerCase(),
          )
          .length;

      // Allow max 2 of same label — encourages variety but not too strict
      if (sameCount >= 2) {
        setState(() {
          _statusMessage =
              'Already found 2 $matchedLabel! Try a different one 😄';
          _isCapturing = false;
        });
        return;
      }

      // ── Add to collection ──────────────────────────────────────────────
      final newItem = CollectedItem(
        label: sameCount > 0
            ? '$matchedLabel ${sameCount + 1}' // Car 1, Car 2
            : matchedLabel,
        imagePath: photo.path,
      );

      setState(() {
        _collected.add(newItem);
        _lastLabel = newItem.label;
        _lastImagePath = photo.path;
        _statusMessage = 'Amazing! Found: ${newItem.label}! ⭐';
        _showToast = true;
      });

      _toastController.forward(from: 0);

      await AppPrefs.saveQuestProgress(widget.quest.id, _collected.length);
      await AppPrefs.saveQuestStatus(widget.quest.id, 'inprogress');
      // Save full collected items so they restore on resume
      await AppPrefs.saveCollectedItems(
        widget.quest.id,
        _collected
            .map((item) => {'label': item.label, 'imagePath': item.imagePath})
            .toList(),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _toastController.reverse();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _showToast = false);
          });
        }
      });

      // ── Quest complete ─────────────────────────────────────────────────
      if (_collected.length >= widget.quest.totalItems) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        const stars = 3;
        await AppPrefs.saveQuestStatus(widget.quest.id, 'completed');
        await AppPrefs.saveQuestStars(widget.quest.id, stars);
        await AppPrefs.addStars(stars);

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => WinScreen(
              quest: widget.quest,
              collectedItems: _collected,
              stars: stars,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = 'Something went wrong. Try again! 😊');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  String _cleanLabel(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) return _buildPermissionDenied();
    if (!_cameraReady) return _buildLoading();
    return _buildCameraScreen();
  }

  Widget _buildCameraScreen() {
    // Use MediaQuery for scalable sizing
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dotSize = (size.width * 0.09).clamp(32.0, 48.0);
    final btnSize = (size.width * 0.2).clamp(64.0, 90.0);
    final sideBtnSize = (size.width * 0.13).clamp(44.0, 60.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full screen camera ─────────────────────────────────────────
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // ── Top gradient ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Bottom gradient ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: sideBtnSize * 0.85,
                        height: sideBtnSize * 0.85,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          '${widget.quest.emoji} ${widget.quest.title}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_collected.length} / ${widget.quest.totalItems} found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: size.width * 0.03,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(width: sideBtnSize * 0.85),
                  ],
                ),

                SizedBox(height: size.height * 0.015),

                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.quest.totalItems, (i) {
                    final done = i < _collected.length;
                    final active = i == _collected.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: done || active ? dotSize : dotSize * 0.78,
                      height: done || active ? dotSize : dotSize * 0.78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? widget.quest.color
                            : active
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: done
                              ? widget.quest.color
                              : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? Text(
                                '⭐',
                                style: TextStyle(fontSize: dotSize * 0.4),
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    active ? 1.0 : 0.4,
                                  ),
                                  fontSize: dotSize * 0.32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Viewfinder ─────────────────────────────────────────────────
          Center(
            child: SizedBox(
              width: size.width * 0.55,
              height: size.width * 0.55,
              child: Stack(
                children: [
                  _corner(top: 0, left: 0, isTop: true, isLeft: true),
                  _corner(top: 0, right: 0, isTop: true, isLeft: false),
                  _corner(bottom: 0, left: 0, isTop: false, isLeft: true),
                  _corner(bottom: 0, right: 0, isTop: false, isLeft: false),
                  Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.quest.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.quest.color.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Toast + status ─────────────────────────────────────────────
          Positioned(
            bottom: bottomPad + btnSize + size.height * 0.06,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showToast && _lastLabel != null)
                  FadeTransition(
                    opacity: _toastAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_toastAnim),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6BCB77),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6BCB77).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_lastImagePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_lastImagePath!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                '✅ $_lastLabel added!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Status message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom buttons ─────────────────────────────────────────────
          Positioned(
            bottom: bottomPad + size.height * 0.02,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Collection preview
                GestureDetector(
                  onTap: _showCollectionSheet,
                  child: Container(
                    width: sideBtnSize,
                    height: sideBtnSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _collected.isEmpty ? '🗂️' : '${_collected.length}',
                        style: TextStyle(
                          fontSize: _collected.isEmpty
                              ? sideBtnSize * 0.4
                              : sideBtnSize * 0.35,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Capture button
                ScaleTransition(
                  scale: _isCapturing
                      ? const AlwaysStoppedAnimation(0.9)
                      : _pulseAnim,
                  child: GestureDetector(
                    onTap: _captureAndLabel,
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : widget.quest.color,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: widget.quest.color.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isCapturing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                            : Text(
                                '📸',
                                style: TextStyle(fontSize: btnSize * 0.4),
                              ),
                      ),
                    ),
                  ),
                ),

                // Hint button
                GestureDetector(
                  onTap: _showHint,
                  child: Container(
                    width: sideBtnSize,
                    height: sideBtnSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '💡',
                        style: TextStyle(fontSize: sideBtnSize * 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: widget.quest.color, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: widget.quest.color, width: 3)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: widget.quest.color, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: widget.quest.color, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(6) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(6) : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(6)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(6)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  void _showHint() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.quest.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              widget.quest.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              widget.quest.instruction,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCollectionSheet() {
    if (_collected.isEmpty) {
      setState(
        () => _statusMessage = "Nothing collected yet! Start snapping! 📸",
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collected (${_collected.length}/${widget.quest.totalItems})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _collected.length,
                itemBuilder: (_, i) {
                  final item = _collected[i];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(item.imagePath),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3557),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.quest.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            const SizedBox(height: 16),
            const Text(
              'Getting camera ready...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📷', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text(
                'Camera Permission Needed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A6B9E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please allow camera access to go on a quest!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: openAppSettings,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
