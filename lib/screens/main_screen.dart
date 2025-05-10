import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/main_provider.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final String customerName;
  const MainScreen({super.key, required this.customerName});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Trigger loading customer name from Hive if not already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainProvider.notifier).loadCustomerName(widget.customerName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerName = ref.watch(mainProvider);

    final screens = [
      HomeScreen(username: customerName),
      const WorkoutScreen(),
      ProfileScreen(customerName: customerName),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isActive: _selectedIndex == 0,
            onTap: () => _onItemTapped(0),
          ),
          _NavBarItem(
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Workout',
            isActive: _selectedIndex == 1,
            onTap: () => _onItemTapped(1),
          ),
          _NavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            isActive: _selectedIndex == 2,
            onTap: () => _onItemTapped(2),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 30,
              color: isActive ? Colors.white : const Color(0xFFAEB9E1),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFFAEB9E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
