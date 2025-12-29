import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/movie_service.dart';
import '../services/achievement_service.dart';
import '../services/collection_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final MovieService _movieService = MovieService();
  final AchievementService _achievementService = AchievementService();
  final CollectionService _collectionService = CollectionService();

  bool _isLoading = true;
  List<Achievement> _achievements = [];

  // Define static achievements definitions
  final List<Achievement> _allAchievements = [
    const Achievement(
      id: 'first_movie',
      title: 'First Discovery',
      description: 'Add your first movie to the home screen.',
      iconData: Icons.movie_filter_rounded,
      maxProgress: 1,
    ),
    const Achievement(
      id: 'movie_buff',
      title: 'Movie Buff',
      description: 'Save 5 movies to your library.',
      iconData: Icons.local_movies_rounded,
      maxProgress: 5,
    ),
    const Achievement(
      id: 'cinephile',
      title: 'Cinephile',
      description: 'Build a library of 20 movies.',
      iconData: Icons.theaters_rounded,
      maxProgress: 20,
    ),
    const Achievement(
      id: 'collector_novice',
      title: 'Collector',
      description: 'Create your first collection.',
      iconData: Icons.folder_rounded,
      maxProgress: 1,
    ),
    const Achievement(
      id: 'curator',
      title: 'Curator',
      description: 'Create 5 different collections.',
      iconData: Icons.bookmarks_rounded,
      maxProgress: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncAchievements();
  }

  Future<void> _syncAchievements() async {
    try {
      // 1. Get current unlocked status from DB
      final unlockedIds = await _achievementService.getUnlockedAchievementIds();

      // 2. Fetch user stats
      final movies = await _movieService.getAllMovies();
      final collections = await _collectionService.getCollections();

      final int movieCount = movies.length;
      final int collectionCount = collections.length;

      final List<Achievement> updatedList = [];
      final Set<String> newlyUnlocked = {};

      for (var achievement in _allAchievements) {
        bool isUnlocked = unlockedIds.contains(achievement.id);
        int currentProgress = 0;

        // Calculate progress based on achievement ID
        switch (achievement.id) {
          case 'first_movie':
            currentProgress = movieCount;
            break;
          case 'movie_buff':
            currentProgress = movieCount;
            break;
          case 'cinephile':
            currentProgress = movieCount;
            break;
          case 'collector_novice':
            currentProgress = collectionCount;
            break;
          case 'curator':
            currentProgress = collectionCount;
            break;
          default:
            currentProgress = 0;
        }

        // Cap progress at max
        if (currentProgress > achievement.maxProgress) {
          currentProgress = achievement.maxProgress;
        }

        // Check unlock condition
        if (!isUnlocked && currentProgress >= achievement.maxProgress) {
          isUnlocked = true;
          newlyUnlocked.add(achievement.id);
        }

        updatedList.add(achievement.copyWith(
          isUnlocked: isUnlocked,
          currentProgress: currentProgress,
        ));
      }

      // 3. Persist new unlocks to DB
      for (final id in newlyUnlocked) {
        await _achievementService.unlockAchievement(id);
      }

      if (mounted) {
        setState(() {
          _achievements = updatedList;
          _isLoading = false;
        });

        if (newlyUnlocked.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text("New achievement unlocked!"),
               backgroundColor: Colors.black,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      }
    } catch (e) {
      debugPrint("Error syncing achievements: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Achievements",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSummaryHeader(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildAchievementCard(_achievements[index]),
                        );
                      },
                      childCount: _achievements.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;
    // Calculate progress with safety checks
    final double rawProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;
    // Ensure progress is valid (0.0 to 1.0)
    final double progress = rawProgress.clamp(0.0, 1.0);
    // Explicitly handle type for int conversion
    final int percentage = (progress * 100).toInt();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: Colors.black,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$percentage%",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$unlockedCount of $totalCount Unlocked",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;

    // Safety check for calculation
    double progressPercent = 0.0;
    if (achievement.maxProgress > 0) {
      progressPercent = achievement.currentProgress / achievement.maxProgress;
    }
    // Clamp to ensure valid range for LinearProgressIndicator
    progressPercent = progressPercent.clamp(0.0, 1.0);

    final Color primaryColor = isUnlocked ? Colors.black : Colors.grey.shade300;
    final Color iconColor = isUnlocked ? Colors.amber.shade600 : Colors.grey.shade400;
    final Color textColor = isUnlocked ? Colors.black87 : Colors.grey.shade400;
    final Color descriptionColor = isUnlocked ? Colors.grey.shade600 : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUnlocked ? Colors.grey.shade200 : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.iconData,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (isUnlocked)
                           Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 20)
                        else
                           Icon(Icons.lock_rounded, color: Colors.grey.shade300, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: descriptionColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey.shade100,
                      color: Colors.amber.shade400,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${achievement.currentProgress}/${achievement.maxProgress}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
