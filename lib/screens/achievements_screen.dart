import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/movie_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final MovieService _movieService = MovieService();
  bool _isLoading = true;
  List<Achievement> _achievements = [];

  // Define static achievements definitions
  final List<Achievement> _allAchievements = [
    const Achievement(
      id: 'first_movie',
      title: 'First Discovery',
      description: 'Add your first movie to the home screen.',
      iconData: Icons.movie_filter_rounded,
    ),
    // Future achievements can be added here
  ];

  @override
  void initState() {
    super.initState();
    _checkAchievements();
  }

  Future<void> _checkAchievements() async {
    try {
      // Fetch user's saved movies to determine progress
      final movies = await _movieService.getAllMovies();
      final int movieCount = movies.length;

      final List<Achievement> updatedList = [];

      for (var achievement in _allAchievements) {
        bool unlocked = false;

        // Logic for each achievement
        if (achievement.id == 'first_movie') {
          unlocked = movieCount >= 1;
        }

        updatedList.add(achievement.copyWith(isUnlocked: unlocked));
      }

      if (mounted) {
        setState(() {
          _achievements = updatedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking achievements: $e");
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
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _achievements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildAchievementCard(_achievements[index]);
              },
            ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
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
      child: Row(
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
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
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
          if (isUnlocked)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 24),
            ),
        ],
      ),
    );
  }
}
