import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData iconData;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconData,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.maxProgress = 1,
  });

  Achievement copyWith({
    bool? isUnlocked,
    int? currentProgress,
    int? maxProgress,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconData: iconData,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      maxProgress: maxProgress ?? this.maxProgress,
    );
  }
}
