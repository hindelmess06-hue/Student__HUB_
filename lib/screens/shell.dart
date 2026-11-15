import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'announcements_screen.dart';
import 'campus_screen.dart';
import 'clubs_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottom: FloatingNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigate: (i) => setState(() => _index = i)),
          const AnnouncementsScreen(),
          const EventsScreen(),
          const ClubsScreen(),
          const CampusScreen(),
        ],
      ),
    );
  }
}
