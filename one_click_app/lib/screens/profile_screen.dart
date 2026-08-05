import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import '../services/attendance_service.dart';
import '../services/cgpa_service.dart';
import '../services/money_manager_service.dart';
import '../services/admin_service.dart';
import '../core/notifications/local_notifications_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(attendanceProvider);
    ref.watch(cgpaProvider);
    final isAdmin = ref.watch(adminProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(ref),
            const SizedBox(height: 24),
            _buildStatsGrid(ref),
            const SizedBox(height: 32),
            _buildMenuSection(
              title: 'Academic',
              items: [
                _buildMenuItem(
                  context,
                  Icons.description,
                  'Transcript Request',
                  onTap: () => _showWIP(context, 'Ordering Transcript...'),
                ),
                _buildMenuItem(
                  context,
                  Icons.school,
                  'Degree Audit',
                  onTap: () =>
                      _showWIP(context, 'Analyzing Degree Progress...'),
                ),
                _buildMenuItem(
                  context,
                  Icons.how_to_reg,
                  'Course Registration',
                  onTap: () => context.go('/schedule'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMenuSection(
              title: 'Settings',
              items: [
                _buildMenuItem(
                  context,
                  Icons.notifications,
                  'Notifications',
                  onTap: () => _showNotificationSettingsDialog(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.security,
                  'Privacy & Security',
                  onTap: () => _showWIP(context, 'Security Center'),
                ),
                _buildMenuItem(
                  context,
                  Icons.help_outline,
                  'Help & Support',
                  onTap: () => _showWIP(context, 'Contacting Support...'),
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'About App',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _buildMenuSection(
                title: 'System Maintenance',
                items: [
                  _buildMenuItem(
                    context,
                    Icons.dangerous,
                    'Wipe All User Data',
                    onTap: () => _confirmWipe(context, ref),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 48),
            _buildSignOutButton(ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showWIP(context, 'Settings'),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final displayName = user?.displayName ?? 'Student User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final onboardingState = ref.watch(onboardingProvider).valueOrNull;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(
              'Semester ${onboardingState?.userData['semester'] ?? 1}',
              AppColors.neonYellow,
            ),
            const SizedBox(width: 8),
            _buildBadge(ref.read(cgpaProvider.notifier).degreeType, AppColors.primary),
            const SizedBox(width: 8),
            _buildBadge(
              onboardingState?.userData['department'] ?? 'CSE',
              AppColors.neonCyan,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final attendanceNotifier = ref.read(attendanceProvider.notifier);
    final moneyState = ref.watch(moneyManagerProvider).valueOrNull ?? MoneyManagerState(transactions: []);
    return Row(
      children: [
        _buildStatCard(
          'Attendance',
          '${attendanceNotifier.getOverallPercentage().toStringAsFixed(1)}%',
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard('CGPA', predictedCgpa(ref), AppColors.neonYellow),
        const SizedBox(width: 12),
        _buildStatCard(
          'Wallet',
          '₹${moneyState.totalBalance.toStringAsFixed(0)}',
          AppColors.neonCyan,
        ),
      ],
    );
  }

  String predictedCgpa(WidgetRef ref) {
    final val = ref.read(cgpaProvider.notifier).predictCGPA();
    return val > 0 ? val.toStringAsFixed(2) : 'N/A';
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap ?? () => _showWIP(context, title),
    );
  }

  Widget _buildSignOutButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).signOut(),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }

  void _confirmWipe(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'CRITICAL ACTION',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will PERMANENTLY delete all user data from Firestore.',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              '• Attendance records\n• GPA history\n• Timetables\n• Finances\n• Notifications',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'This cannot be undone.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              _executeWipe(context, ref);
            },
            child: const Text(
              'Wipe All Data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeWipe(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.error),
      ),
    );

    try {
      await ref.read(adminProvider.notifier).wipeAllUserData();
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All Firestore data has been successfully wiped.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wipe failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'One Click',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.rocket_launch,
        color: AppColors.primary,
        size: 48,
      ),
      children: [
        const Text(
          'Providing one-click academic solutions for university students.',
        ),
      ],
    );
  }

  void _showWIP(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is under construction.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(notificationSettingsProvider);
          final notifier = ref.read(notificationSettingsProvider.notifier);

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF1E293B)),
            ),
            title: Row(
              children: const [
                Icon(Icons.notifications_active, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timetable Reminders',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Receive offline class alerts',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.enabled,
                        onChanged: (val) {
                          notifier.updateSettings(enabled: val);
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                if (settings.enabled) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'REMIND ME BEFORE CLASS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 15, 30, 60].map((mins) {
                      final isSelected = settings.minutesBefore == mins;
                      return ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            notifier.updateSettings(minutesBefore: mins);
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
