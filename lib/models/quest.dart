import 'package:flutter/material.dart';
class Quest {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String instruction;
  final List<String> targetLabels;
  final Color color;
  final int totalItems;

  const Quest({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.instruction,
    required this.targetLabels,
    required this.color,
    this.totalItems = 5,
  });
}