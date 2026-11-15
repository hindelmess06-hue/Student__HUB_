import 'package:flutter/material.dart';

/// Icons can't be stored in a database, so content stores a short key
/// ("library", "gym"...) and this registry turns it back into an icon.
const Map<String, IconData> kIconRegistry = {
  'library': Icons.local_library_rounded,
  'restaurant': Icons.restaurant_rounded,
  'badge': Icons.badge_rounded,
  'support': Icons.support_agent_rounded,
  'health': Icons.health_and_safety_rounded,
  'gym': Icons.fitness_center_rounded,
  'groups': Icons.groups_rounded,
  'shield': Icons.shield_rounded,
  'pool': Icons.pool_rounded,
  'bus': Icons.directions_bus_rounded,
  'store': Icons.storefront_rounded,
  'print': Icons.print_rounded,
  'lab': Icons.science_rounded,
  'computer': Icons.computer_rounded,
  'book': Icons.menu_book_rounded,
  'basketball': Icons.sports_basketball_rounded,
  'place': Icons.place_rounded,
  'code': Icons.code_rounded,
  'robot': Icons.smart_toy_rounded,
  'music': Icons.music_note_rounded,
  'forum': Icons.forum_rounded,
  'camera': Icons.camera_alt_rounded,
  'soccer': Icons.sports_soccer_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'volunteer': Icons.volunteer_activism_rounded,
};

/// Icons offered when an admin creates a new campus area.
const List<String> kFacilityIconKeys = [
  'library',
  'restaurant',
  'gym',
  'pool',
  'basketball',
  'lab',
  'computer',
  'print',
  'store',
  'bus',
  'health',
  'book',
  'place',
];

IconData iconFor(String? key) => kIconRegistry[key] ?? Icons.place_rounded;
