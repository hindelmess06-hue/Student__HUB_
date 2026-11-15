import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  int _cat = 0; // 0 = All, 1..n = categories, last = Following

  static final List<String> _labels = [
    'All',
    ...ClubCategory.values.map((c) => c.label),
    'Following',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    var clubs = app.clubs;
    final followingTab = _cat == _labels.length - 1;
    if (followingTab) {
      clubs = clubs.where((c) => app.followedClubs.contains(c.id)).toList();
    } else if (_cat > 0) {
      final cat = ClubCategory.values[_cat - 1];
      clubs = clubs.where((c) => c.category == cat).toList();
    }

    return Column(
      children: [
        ScreenHeader(
          title: 'Clubs',
          subtitle: '${app.followedClubs.length} followed · ${app.clubs.length} total',
        ),
        FilterChips(
          labels: _labels,
          selected: _cat,
          onSelected: (i) => setState(() => _cat = i),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: clubs.isEmpty
              ? EmptyState(
                  icon: Icons.groups_rounded,
                  title: followingTab
                      ? "You're not following any club yet"
                      : 'No clubs here',
                  subtitle: followingTab
                      ? 'Follow a club to get its updates and events first.'
                      : 'Try another category.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: clubs.length,
                  itemBuilder: (_, i) => FadeSlideIn(
                    index: i,
                    child: ClubGridCard(club: clubs[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
