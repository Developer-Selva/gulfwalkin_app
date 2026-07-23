import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/token_storage.dart';
import '../../features/settings/settings_screen.dart';
import '../theme/app_colors.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybShowFeedbackPrompt());
  }

  Future<void> _maybShowFeedbackPrompt() async {
    final storage = ref.read(tokenStorageProvider);

    if (storage.isFeedbackPromptShown()) return;

    final firstLogin = storage.getFirstLoginAt();
    if (firstLogin == null) return;

    final daysSince = DateTime.now().difference(firstLogin).inDays;
    if (daysSince < 7) return;

    await storage.markFeedbackPromptShown();

    // Wait 3 seconds after home loads so it doesn't feel abrupt
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppFeedbackSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label:        'Home',
          ),
          NavigationDestination(
            icon:         Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label:        'Jobs',
          ),
          NavigationDestination(
            icon:         Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.primary),
            label:        'Applied',
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label:        'Profile',
          ),
          NavigationDestination(
            icon:         Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label:        'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
