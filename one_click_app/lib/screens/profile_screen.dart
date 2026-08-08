import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/onboarding_service.dart';
import '../services/cgpa_service.dart';
import '../services/attendance_service.dart';
import '../services/money_manager_service.dart';
import '../services/admin_service.dart';
import '../core/notifications/local_notifications_service.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/grid_background.dart';
import 'academic_calendar_screen.dart';
import 'assignment_hub_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeoMotionBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(context, ref),
                const SizedBox(height: 24),
                _buildStatsGrid(ref),
                const SizedBox(height: 24),
                _buildMenuSection(
                  title: 'Academic Tools & Records',
                  items: [
                    _buildMenuItem(
                      context,
                      Icons.description_outlined,
                      'Digital Transcript Export',
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
                      Icons.assignment_outlined,
                      'Assignment Hub',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssignmentHubScreen()),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      Icons.calendar_month_outlined,
                      'Academic Calendar',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AcademicCalendarScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMenuSection(
                  title: 'App Settings & Preferences',
                  items: [
                    _buildMenuItem(
                      context,
                      Icons.notifications_outlined,
                      'Notification Reminders',
                      onTap: () => _showNotificationSettingsDialog(context, ref),
                    ),
                    _buildMenuItem(
                      context,
                      Icons.security_outlined,
                      'Security & Privacy',
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
                const SizedBox(height: 24),
                if (user?.email == 'vinaykumar020406@gmail.com' || user?.email == 'pvinaykumar2006@gmail.com') ...[
                  _buildAdminPanel(context, ref),
                  const SizedBox(height: 20),
                ],
                _buildSignOutButton(ref),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neoYellow,
                  border: Border.all(color: Colors.black, width: 2.5),
                ),
                clipBehavior: Clip.hardEdge,
                child: photoUrl != null
                    ? Image.network(photoUrl, fit: BoxFit.cover)
                    : const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.black,
                      ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditProfileModal(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            college,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge('Semester $semester', AppColors.neoYellow),
              const SizedBox(width: 8),
              _buildBadge(degree, AppColors.neoPink),
              const SizedBox(width: 8),
              _buildBadge(department, AppColors.neoCyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color == AppColors.neoPink ? Colors.white : Colors.black,
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
          AppColors.neoPink,
        ),
        const SizedBox(width: 12),
        _buildStatCard('CGPA', cgpa, AppColors.neoYellow),
        const SizedBox(width: 12),
        _buildStatCard(
          'Wallet',
          '₹${moneyState.totalBalance.toStringAsFixed(0)}',
          AppColors.neoCyan,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color == AppColors.neoPink ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color == AppColors.neoPink ? Colors.white : Colors.black,
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
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
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
          color: AppColors.neoYellow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black, size: 22),
      onTap: onTap,
    );
  }

  Widget _buildAdminPanel(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neoOrange,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.admin_panel_settings, color: Colors.black, size: 22),
              SizedBox(width: 8),
              Text(
                'ADMIN MAINTENANCE',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neoPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () => _confirmWipe(context, ref),
              icon: const Icon(Icons.cleaning_services, color: Colors.white, size: 18),
              label: const Text('Wipe All Student Data', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).signOut(),
        icon: const Icon(Icons.logout, size: 20, color: Colors.white),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neoPink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2.5),
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
      backgroundColor: Colors.white,
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('COLLEGE / UNIVERSITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: collegeController,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: _modalInputDecoration('e.g. IIITDM Kancheepuram'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEGREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: ['B.Tech', 'M.Tech', 'Dual Degree', 'Ph.D'].contains(selectedDegree) ? selectedDegree : 'B.Tech',
                                decoration: _modalInputDecoration('Degree'),
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                              const Text('SEMESTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: selectedSem,
                                decoration: _modalInputDecoration('Sem'),
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

                    const Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['CSE', 'ECE', 'ME', 'CIVIL', 'EEE'].contains(selectedDept) ? selectedDept : 'CSE',
                      decoration: _modalInputDecoration('Dept'),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                          backgroundColor: AppColors.neoYellow,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
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
                        child: const Text('Save Profile Changes ⚡', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
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
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
    );
  }

  void _showTranscriptDialog(BuildContext context, WidgetRef ref) {
    final cgpa = ref.read(cgpaProvider.notifier).calculateCurrentCGPA().toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2.5)),
        title: const Row(
          children: [
            Icon(Icons.description, color: Colors.black),
            SizedBox(width: 10),
            Text('Academic Transcript', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current CGPA: $cgpa', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Status: Verified Student Record', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Official digital transcript export with course codes and semester GPAs.', style: TextStyle(color: Colors.black87, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showDegreeAuditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2.5)),
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.black),
            SizedBox(width: 10),
            Text('Degree Progress Audit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed: 48 / 160 Total Credits', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
            SizedBox(height: 12),
            LinearProgressIndicator(value: 48 / 160, color: AppColors.neoYellow, backgroundColor: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            Text('• Core Courses: 36 Credits\n• Electives: 8 Credits\n• Science & Humanities: 4 Credits', style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2.5)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.black),
            SizedBox(width: 10),
            Text('Security & Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as: ${user?.email ?? "Student"}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Authentication: Google Single Sign-On (SSO)', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Data Protection: Encrypted Local & Cloud Sync', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2.5)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.black),
            SizedBox(width: 10),
            Text('Help & Support', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('One Click Student Support', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
            SizedBox(height: 8),
            Text('If you encounter any issues with timetable sync or mess menus, contact your campus administrator.', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _confirmWipe(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black, width: 2.5)),
        title: const Text(
          'CRITICAL ACTION',
          style: TextStyle(color: AppColors.neoPink, fontWeight: FontWeight.w900),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will PERMANENTLY delete all student user data from Firestore while preserving your Admin account.',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '• Attendance records\n• GPA history\n• Timetables\n• Finances\n• Notifications',
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoPink),
            onPressed: () async {
              Navigator.pop(context);
              _executeWipe(context, ref);
            },
            child: const Text('Wipe User Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );

    try {
      await ref.read(adminProvider.notifier).wipeAllUserData();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All student Firestore data wiped successfully.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wipe failed: $e'),
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
        color: Colors.black,
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.black, size: 24),
                SizedBox(width: 12),
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
                    color: AppColors.neoYellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
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
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Receive offline class alerts',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                        activeThumbColor: Colors.black,
                        activeTrackColor: AppColors.neoLime,
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
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
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
                        selectedColor: AppColors.neoPink,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: Colors.black),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
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
                    icon: const Icon(Icons.notifications_active, color: AppColors.neoYellow, size: 18),
                    label: const Text('Test System Notifications ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
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
