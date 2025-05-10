import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_provider.dart';
import '../../models/home_state.dart';
import 'login_screen.dart';
import 'vital_screen.dart';
import 'membership_plans_screen.dart';
import 'payment_screen.dart';
import 'exercise_screen.dart';
import '../providers/logout_provider.dart';
import '../../providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081028),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, ref),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: () => ref.read(homeProvider.notifier).refreshData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(),
                    const SizedBox(height: 18),
                    _buildTodaysWorkoutBox(context, state),
                    const SizedBox(height: 40),
                    _buildStatsGrid(state),
                    _buildWeightStats(state),
                    _buildMembershipDetailsSection(state),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGreetingSection() {
  final firstName = username.split(' ').first;

  return Container(
    width: 350, // Matches Figma layout width
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Hey ',
              style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFFFFF),
              ),
            ),
            Text(
              '$firstName!',
              style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: const Text(
            "Ready to crush your next workout and hit those fitness goals? Let's get moving!",
            style: TextStyle(
              fontFamily: 'WorkSans',
              color: Color(0xFFFFFFFF),
              fontSize: 24,
              height: 1.2,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTodaysWorkoutBox(BuildContext context, HomeState state) {
  return Container(
    width: 362, // Match exact width
    height: 148, // Match exact height
    decoration: BoxDecoration(
      color: const Color(0xFF0B1739),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Stack(
      children: [
        // TODAY'S WORKOUT text
        const Positioned(
          left: 16,
          top: 16,
          child: SizedBox(
            width: 144,
            height: 20,
            child: Text(
              "Today's Workout",
              style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 18,
                fontWeight: FontWeight.normal,
                height: 20 / 18,
                color: Color(0xFFAEB9E1),
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        Positioned(
          left: 220,
          top: 14,
          child: Container(
            width: 120,
            height: 120,
            //child: Padding(
  //padding: const EdgeInsets.symmetric(vertical:5),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.asset(
      'assets/images/gym_home.png',
      fit: BoxFit.cover,
    ),
  ),
//),

          ),
        ),
        if (state.isLoadingWorkout)
          const Center(child: CircularProgressIndicator(color: Color(0xFF0064F4)))
        else if (state.todaysWorkout == null)
          const Positioned(
            left: 16,
            top: 46,
            child: SizedBox(
              width: 188,
              height: 20,
              child: Text(
                'No workout scheduled',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  height: 20 / 18,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: 0,
                ),
              ),
            ),
          )
        else ...[
          // Workout name
          Positioned(
            left: 16,
            top: 46,
            child: SizedBox(
              width: 188,
              height: 20,
              child: Text(
                state.todaysWorkout!.name,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  height: 20 / 18,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          // VIEW WORKOUT button
          Positioned(
            left: 16,
            top: 86,
            child: SizedBox(
              width: 162,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  if (state.todaysWorkout != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseScreen(
                          day: "Today's Workout",
                          bodyPart: state.todaysWorkout!.name,
                          exercises: state.todaysWorkout!.exercises,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0064F4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'VIEW WORKOUT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}


 Widget _buildStatsGrid(HomeState state) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 176 / 92, // Proper aspect ratio
    children: [
      _buildStatCard(
        title: 'Total Gym Days',
        value: state.isLoadingTotalDays ? '--' : '${state.totalGymDays}',
        secondaryText: '  Days',
        isLoading: state.isLoadingTotalDays,
        valueSize: 29.0,
      ),
      _buildStatCard(
        title: 'Gym Streak',
        value: state.isLoading ? '--' : '${state.gymStreak}',
        secondaryText: '  Days',
        isLoading: state.isLoading,
        valueSize: 29.0,
      ),
    ],
  );
}


  Widget _buildWeightStats(HomeState state) {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 176 / 92, // Proper aspect ratio
      children: [
        _buildStatCard(
          title: 'Target Weight',
          value: state.isLoadingWeight ? '--' : '${state.targetWeight.toStringAsFixed(1)} ',
          secondaryText: 'Kg',
          isLoading: state.isLoadingWeight,
          valueSize: 24.0,
        ),
        _buildStatCard(
          title: 'Current Weight',
          value: state.isLoadingWeight ? '--' : '${state.currentWeight.toStringAsFixed(1)} ',
          secondaryText: 'Kg',
          isLoading: state.isLoadingWeight,
          valueSize: 24.0,
        ),
      ],
    ),
  );
}


  Widget _buildMembershipDetailsSection(HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 40, bottom: 10),
          child: Text('Membership Details', style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 176 / 92,
          children: [
            _buildStatCard(
              title: 'Membership Type',
              value: state.membershipPlanName,
              isLoading: state.isLoading,
            ),
            _buildStatCard(
              title: 'FEE DUE DATE',
              value: state.feeDueDate != null
                  ? '${state.feeDueDate!.day}/${state.feeDueDate!.month}/${state.feeDueDate!.year}'
                  : '--',
              isLoading: state.isLoading,
              valueColor: _getDueDateColor(state.feeDueDate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
  required String title,
  required String value,
  required bool isLoading,
  Color valueColor = Colors.white,
  double valueSize = 24.0,
  String? secondaryText,
  String? subtitle,
}) {
  return SizedBox(
    width: 176, // Fixed card width
    height: 92, // Fixed card height
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1739),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12), // Internal padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title - Dynamic but constrained
          SizedBox(
            width: 135, // Max width
            height: 20, // Fixed height
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14, // Base size
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Value + Secondary Text
                  SizedBox(
                    width: 95, // Max width
                    height: 32, // Fixed height
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: valueColor,
                              fontWeight: FontWeight.bold,
                              fontSize: valueSize, // Will scale down if needed
                            ),
                          ),
                          if (secondaryText != null) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                secondaryText,
                                style: TextStyle(
                                  color: valueColor.withOpacity(0.8),
                                  fontSize: 14, // Base size
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Subtitle (only for fee due date)
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 150, // Slightly less than card width
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: valueColor.withOpacity(0.8),
                            fontSize: 12, // Smaller fixed size
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profileUrl = profileState.profile?.profileUrl;
    return Drawer(
      backgroundColor: const Color(0xFF0B1739),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
           DrawerHeader(
  decoration: const BoxDecoration(color: Color(0xFF080F27)),
  child: Center(
    child: ClipOval(
      child: profileUrl != null
          ? Image.network(
              profileUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover, // or BoxFit.contain if images are too zoomed
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person,
                size: 40,
                color: Colors.white54,
              ),
            )
          : const Icon(Icons.person, size: 40, color: Colors.white54),
    ),
  ),
),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.white),
            title: const Text('Membership Plans', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipPlansScreen()));
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.white),
            title: const Text('Payments', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()));
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.white),
            title: const Text('Gym Reports', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VitalScreen()));
            },
          ),
          const Divider(color: Colors.grey),
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0064F4),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
             onPressed: () async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Logout', style: TextStyle(color: Colors.white)),
      content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await ref.read(logoutProvider).logoutAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
},
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime? dueDate) {
    if (dueDate == null) return Colors.white;
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) return Colors.red;
    if (daysRemaining <= 3) return Colors.orange;
    return Colors.green;
  }
}
