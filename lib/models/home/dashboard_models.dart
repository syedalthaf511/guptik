import 'package:flutter/material.dart';

class DashboardSection {
  final IconData icon;
  final String title;
  final int? badge;
  bool isSelected;
  final List<SubSection>? subSections;
  bool isExpanded;

  DashboardSection({
    required this.icon,
    required this.title,
    this.badge,
    this.isSelected = false,
    this.subSections,
    this.isExpanded = false,
  });
}

class SubSection {
  final String title;
  final IconData? icon;
  bool isSelected;

  SubSection({required this.title, this.icon, this.isSelected = false});
}