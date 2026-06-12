import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/quest.dart';
import '../utils/prefs.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Quest> _quests = const [
    Quest(
      id: 'flowers',
      title: 'Flower Hunt',
      emoji: '🌸',
      description: 'Find 5 flowers around you!',
      instruction:
      'Point your camera at flowers — real, fake, or in pictures!',
      targetLabels: [
        'flower', 'rose', 'tulip', 'daisy', 'plant', 'blossom',
        'petal', 'sunflower', 'orchid', 'lily',
      ],
      color: Color(0xFFFF6B9D),
    ),
    Quest(
      id: 'animals',
      title: 'Animal Safari',
      emoji: '🐾',
      description: 'Find 5 animals around you!',
      instruction:
      'Point at real animals, toys, books or pictures with animals!',
      targetLabels: [
        'cat', 'dog', 'bird', 'fish', 'animal', 'pet', 'puppy',
        'kitten', 'rabbit', 'hamster', 'parrot', 'turtle',
      ],
      color: Color(0xFF6BCB77),
    ),
    Quest(
      id: 'food',
      title: 'Food Quest',
      emoji: '🍎',
      description: 'Find 5 food items around you!',
      instruction:
      'Point your camera at any food — fruits, snacks, or meals!',
      targetLabels: [
        'food', 'fruit', 'apple', 'banana', 'bread', 'vegetable',
        'snack', 'meal', 'drink', 'juice', 'cookie', 'cake',
      ],
      color: Color(0xFFFF9F43),
    ),
    Quest(
      id: 'vehicles',
      title: 'Vehicle Hunt',
      emoji: '🚗',
      description: 'Find 5 vehicles around you!',
      instruction: 'Point at cars, bikes, buses — toys or real ones!',
      targetLabels: [
        'car', 'vehicle', 'truck', 'bus', 'bicycle', 'bike',
        'motorcycle', 'van', 'taxi', 'wheel', 'transport',
      ],
      color: Color(0xFF4ECDC4),
    ),
    Quest(
      id: 'nature',
      title: 'Nature Walk',
      emoji: '🌿',
      description: 'Find 5 things from nature!',
      instruction:
      'Look for leaves, rocks, trees, sky or water around you!',
      targetLabels: [
        'tree', 'leaf', 'rock', 'stone', 'sky', 'cloud', 'grass',
        'nature', 'wood', 'branch', 'garden', 'outdoor',
      ],
      color: Color(0xFF48CAE4),
    ),
    Quest(
      id: 'household',
      title: 'Home Explorer',
      emoji: '🏠',
      description: 'Find 5 things in your home!',
      instruction:
      'Look around your house — furniture, gadgets, anything!',
      targetLabels: [
        'furniture', 'chair', 'table', 'lamp', 'book', 'phone',
        'bottle', 'cup', 'bag', 'clock', 'pillow', 'remote',
      ],
      color: Color(0xFFA855F7),
    ),
  ];

  Map<String, String> _questStatuses = {};
  Map<String, int> _questProgress = {};
  Map<String, int> _questStars = {};
  int _totalStars = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final statuses = <String, String>{};
    final progresses = <String, int>{};
    final stars = <String, int>{};

    for (final quest in _quests) {
      statuses[quest.id] = await AppPrefs.getQuestStatus(quest.id);
      progresses[quest.id] = await AppPrefs.getQuestProgress(quest.id);
      stars[quest.id] = await AppPrefs.getQuestStars(quest.id);
    }

    final totalStars = await AppPrefs.getTotalStars();

    if (mounted) {
      setState(() {
        _questStatuses = statuses;
        _questProgress = progresses;
        _questStars = stars;
        _totalStars = totalStars;
        _loading = false;
      });
    }
  }

  int get _completedCount =>
      _questStatuses.values.where((s) => s == 'completed').length;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
        child: SafeArea(
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4ECDC4),
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => FadeInUp(
                      delay: Duration(milliseconds: 100 * i),
                      child: _buildQuestCard(_quests[i]),
                    ),
                    childCount: _quests.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: FadeInDown(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A9BC2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.userName}! 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A6B9E),
                  ),
                ),
              ],
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: FadeInUp(
        delay: const Duration(milliseconds: 100),
        child: Row(
          children: [
            Expanded(
              child: _statCard(
                '⭐',
                '$_totalStars',
                'Total Stars',
                const Color(0xFFFFE66D),
                const Color(0xFF996600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                '✅',
                '$_completedCount / ${_quests.length}',
                'Quests Done',
                const Color(0xFF6BCB77),
                const Color(0xFF2D6A31),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                '🔥',
                '${_quests.length - _completedCount}',
                'Remaining',
                const Color(0xFFFF6B6B),
                const Color(0xFF8B0000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji,
      String value,
      String label,
      Color bg,
      Color textColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg, width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final status = _questStatuses[quest.id] ?? 'notstarted';
    final progress = _questProgress[quest.id] ?? 0;
    final stars = _questStars[quest.id] ?? 0;
    final isCompleted = status == 'completed';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CameraScreen(quest: quest),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        _loadProgress();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF6BCB77)
                : quest.color.withOpacity(0.3),
            width: isCompleted ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: quest.color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: quest.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        quest.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Description
                  Text(
                    quest.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Status section
                  if (isCompleted) ...[
                    Row(
                      children: List.generate(
                        3,
                            (i) => Text(
                          i < stars ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFF6BCB77).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Play Again ▶',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D6A31),
                          ),
                        ),
                      ),
                    ),
                  ] else if (status == 'inprogress') ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress / quest.totalItems,
                        backgroundColor: Colors.grey.shade200,
                        color: quest.color,
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$progress / ${quest.totalItems} found',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: quest.color,
                      ),
                    ),
                  ] else ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: quest.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Start Quest →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: quest.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Completed tick badge
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6BCB77),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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