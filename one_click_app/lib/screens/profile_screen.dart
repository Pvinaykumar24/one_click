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
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(context, ref),
            const SizedBox(height: 24),
            _buildStatsGrid(ref),
            const SizedBox(height: 32),
            _buildMenuSection(
              title: 'Academic Hub',
              items: [
                _buildMenuItem(
                  context,
                  Icons.edit_note,
                  'Edit Academic Profile',
                  onTap: () => _showEditProfileModal(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.description_outlined,
                  'Transcript Request',
                  onTap: () => _showTranscriptDialog(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.school_outlined,
                  'Degree Progress Audit',
                  onTap: () => _showDegreeAuditDialog(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.calendar_month_outlined,
                  'Manage Class Timetable',
                  onTap: () => context.push('/schedule'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMenuSection(
              title: 'Settings & Security',
              items: [
                _buildMenuItem(
                  context,
                  Icons.notifications_outlined,
                  'Notifications & Reminders',
                  onTap: () => _showNotificationSettingsDialog(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.security_outlined,
                  'Privacy & Security',
                  onTap: () => _showSecurityDialog(context, ref),
                ),
                _buildMenuItem(
                  context,
                  Icons.help_outline,
                  'Help & Support',
                  onTap: () => _showSupportDialog(context),
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'About One Click',
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
                    'Wipe All User Data (Preserves Admin)',
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

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Student Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          tooltip: 'Edit Profile',
          onPressed: () => _showEditProfileModal(context, ref),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final displayName = user?.displayName ?? 'Student User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final onboardingState = ref.watch(onboardingProvider).valueOrNull;
    final userData = onboardingState?.userData ?? {};

    final college = userData['college'] ?? 'University Student';
    final semester = userData['semester'] ?? 1;
    final department = userData['department'] ?? 'CSE';
    final degree = userData['degree'] ?? 'B.Tech';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : const Icon(
                      Icons.person,
                      size: 56,
                      color: AppColors.primary,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          college,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge('Semester $semester', AppColors.neonYellow),
            const SizedBox(width: 8),
            _buildBadge(degree, AppColors.primary),
            const SizedBox(width: 8),
            _buildBadge(department, AppColors.neonCyan),
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
    final cgpa = ref.read(cgpaProvider.notifier).calculateCurrentCGPA().toStringAsFixed(2);

    return Row(
      children: [
        _buildStatCard(
          'Attendance',
          '${attendanceNotifier.getOverallPercentage().toStringAsFixed(1)}%',
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard('CGPA', cgpa, AppColors.neonYellow),
        const SizedBox(width: 12),
        _buildStatCard(
          'Wallet',
          '₹${moneyState.totalBalance.toStringAsFixed(0)}',
          AppColors.neonCyan,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
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
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
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

  void _showEditProfileModal(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.read(onboardingProvider).valueOrNull;
    final userData = onboardingState?.userData ?? {};

    final collegeController = TextEditingController(text: userData['college'] ?? '');
    String selectedDept = userData['department'] ?? 'CSE';
    String selectedDegree = userData['degree'] ?? 'B.Tech';
    int selectedSem = userData['semester'] ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Academic Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('COLLEGE / UNIVERSITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: collegeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _modalInputDecoration('e.g. IIITDM Kancheepuram'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEGREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: ['B.Tech', 'M.Tech', 'Dual Degree', 'Ph.D'].contains(selectedDegree) ? selectedDegree : 'B.Tech',
                                decoration: _modalInputDecoration('Degree'),
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white),
                                items: ['B.Tech', 'M.Tech', 'Dual Degree', 'Ph.D']
                                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedDegree = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SEMESTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: selectedSem,
                                decoration: _modalInputDecoration('Sem'),
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white),
                                items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('Semester ${i + 1}'))),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedSem = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['CSE', 'ECE', 'ME', 'CIVIL', 'EEE'].contains(selectedDept) ? selectedDept : 'CSE',
                      decoration: _modalInputDecoration('Dept'),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: ['CSE', 'ECE', 'ME', 'CIVIL', 'EEE']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDept = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await ref.read(onboardingProvider.notifier).updateUserData({
                            'college': collegeController.text.trim(),
                            'degree': selectedDegree,
                            'semester': selectedSem,
                            'department': selectedDept,
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _modalInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  void _showTranscriptDialog(BuildContext context, WidgetRef ref) {
    final cgpa = ref.read(cgpaProvider.notifier).calculateCurrentCGPA().toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Academic Transcript', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current CGPA: $cgpa', style: const TextStyle(color: AppColors.neonYellow, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Status: Verified Student Record', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('An official digital transcript export with course codes and semester GPAs can be generated for university verification.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _showDegreeAuditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Row(
          children: [
            Icon(Icons.school, color: AppColors.neonCyan),
            SizedBox(width: 10),
            Text('Degree Progress Audit', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed: 48 / 160 Total Credits', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 12),
            LinearProgressIndicator(value: 48 / 160, color: AppColors.neonCyan, backgroundColor: Color(0xFF1E293B)),
            SizedBox(height: 16),
            Text('• Core Courses: 36 Credits\n• Electives: 8 Credits\n• Science & Humanities: 4 Credits', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Security & Account', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as: ${user?.email ?? "Student"}', style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Authentication: Google Single Sign-On (SSO)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Data Protection: Encrypted Local & Cloud Sync', style: const TextStyle(color: AppColors.success, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.neonYellow),
            SizedBox(width: 10),
            Text('Help & Support', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('One Click Student Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            Text('If you encounter any issues with timetable sync or mess menus, contact your campus administrator or support.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
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
              'This will PERMANENTLY delete all student user data from Firestore while preserving your Admin account.',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              '• Attendance records\n• GPA history\n• Timetables\n• Finances\n• Notifications',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              _executeWipe(context, ref);
            },
            child: const Text('Wipe User Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All student Firestore data wiped successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
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
      children: const [
        Text('Providing one-click academic solutions for university students.'),
      ],
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
            title: const Row(
              children: [
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
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await LocalNotificationsService.sendTestNotification();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification sent! Check your system notification bar 🔔')),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                    label: const Text('Test System Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
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
