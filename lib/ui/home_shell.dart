

import 'package:byin_app/ui/pages/dashboard_page.dart';
import 'package:byin_app/ui/pages/incubators_page.dart';
import 'package:byin_app/ui/pages/settings_page.dart';
import 'package:byin_app/ui/pages/templates_page.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({ super.key });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = const [
    DashboardPage(),
    IncubatorsPage(),
    TemplatesPage(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _index, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care_rounded),
            label: 'Incubator',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined), 
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Template'
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan'
          )
        ],
      ),
    );
  }
}