import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../services/timetable_service.dart';
import 'dart:ui';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final displayName = user?.displayName ?? 'Student';
    final photoUrl = user?.photoUrl;

    final onboardingState = ref.watch(onboardingProvider).valueOrNull;
    final userData = onboardingState?.userData ?? {};
    final collegeName = userData['college']?.toString().toUpperCase() ?? 'ENGINEERING DEPT';
    final notifications = ref.watch(notificationProvider).valueOrNull ?? [];
    final unread = notifications.where((n) => !n.isRead).length;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), offset: Offset(2, 2), blurRadius: 0)],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: AppColors.primary))
                        : const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collegeName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary)),
                      Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Search button
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.border.withValues(alpha: 0.5), offset: Offset(2, 2), blurRadius: 0)],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showSearchOverlay(context),
                      icon: const Icon(Icons.search, size: 22),
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notification button
                  Stack(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                          boxShadow: [BoxShadow(color: AppColors.border.withValues(alpha: 0.5), offset: Offset(2, 2), blurRadius: 0)],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showNotificationPanel(context, ref),
                          icon: const Icon(Icons.notifications, size: 22),
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 4, top: 4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.neonPink,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                              boxShadow: [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.5), offset: Offset(2, 2), blurRadius: 0)],
                            ),
                            alignment: Alignment.center,
                            child: Text('$unread', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final searchItems = [
              {'title': 'Timetable', 'route': '/schedule', 'icon': Icons.calendar_today},
              {'title': 'Attendance', 'route': '/attendance', 'icon': Icons.fact_check},
              {'title': 'CGPA Calculator', 'route': '/cgpa', 'icon': Icons.school},
              {'title': 'Mess Menu', 'route': '/mess', 'icon': Icons.restaurant},
              {'title': 'Money Manager', 'route': '/finance', 'icon': Icons.account_balance_wallet},
              {'title': 'Assignments', 'route': '/assignments', 'icon': Icons.assignment},
              {'title': 'Profile', 'route': '/profile', 'icon': Icons.person},
              {'title': 'Academic Calendar', 'route': '/academic-calendar', 'icon': Icons.calendar_month},
            ];

            final filtered = query.isEmpty
                ? searchItems
                : searchItems.where((item) => (item['title'] as String).toLowerCase().contains(query.toLowerCase())).toList();

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search features...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 12),
                    ...filtered.map((item) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                      ),
                      title: Text(item['title'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(item['route'] as String);
                      },
                    )),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No results found', style: TextStyle(color: AppColors.textSecondary)),
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

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    ref.read(notificationProvider.notifier).refresh(ref.read(timetableProvider.notifier).getNextClass(DateTime.now()));
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      TextButton(
                        onPressed: () {
                          ref.read(notificationProvider.notifier).markAllRead();
                          Navigator.pop(context);
                        },
                        child: const Text('Mark All Read', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final notifs = ref.watch(notificationProvider).valueOrNull ?? [];
                      if (notifs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_outlined,
                                    size: 52,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "You're all caught up! Academic alerts, attendance notices, and meal updates will appear here when they arrive.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifs.length,
                        itemBuilder: (context, index) {
                          var n = notifs[index];
                          IconData icon;
                          Color color;
                          switch (n.type) {
                            case 'class': icon = Icons.school; color = AppColors.primary; break;
                            case 'meal': icon = Icons.restaurant; color = AppColors.neonYellow; break;
                            case 'attendance': icon = Icons.warning; color = AppColors.error; break;
                            case 'academic': icon = Icons.calendar_month; color = AppColors.neonCyan; break;
                            default: icon = Icons.info; color = AppColors.textSecondary;
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.transparent : color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border(left: BorderSide(color: n.isRead ? Colors.transparent : color, width: 3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold, color: AppColors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(_timeAgo(n.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime timestamp) {
    Duration diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}