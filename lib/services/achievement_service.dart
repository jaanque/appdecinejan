import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AchievementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches the IDs of all achievements unlocked by the current user.
  Future<List<String>> getUnlockedAchievementIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((row) => row['achievement_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return [];
    }
  }

  /// Unlocks an achievement for the current user if it hasn't been unlocked yet.
  Future<void> unlockAchievement(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // The unique constraint in the DB handles duplicates safely (ignoring them would be ideal,
      // but 'upsert' with 'onConflict' is the standard way).
      // Since we just want to ensure it exists:
      await _supabase.from('user_achievements').upsert(
        {
          'user_id': userId,
          'achievement_id': achievementId,
        },
        onConflict: 'user_id, achievement_id',
      );

      debugPrint('Achievement unlocked: $achievementId');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }
}
