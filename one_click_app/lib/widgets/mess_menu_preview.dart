import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/mess_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessMenuPreview extends ConsumerWidget {
  const MessMenuPreview({super.key});

  // ─── Meal timing helpers ────────────────────────────────────────────────────

  static const _mealTimes = {
    'Breakfast': [7.5, 9.5],
    'Lunch': [12.5, 14.25],
    'Snacks': [17.0, 18.0],
    'Dinner': [19.5, 21.0],
  };

  static const _mealOrder = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  String _getMealTime(String name) {
    if (name == 'Breakfast') return '7:00 – 9:30AM';
    if (name == 'Lunch') return '12:00 – 2:15 PM';
    if (name == 'Snacks') return '5:00 – 6:00 PM';
    return '7:00 – 9:30 PM';
  }

  IconData _getMealIcon(String name) {
    if (name == 'Breakfast') return Icons.wb_twilight;
    if (name == 'Lunch') return Icons.wb_sunny;
    if (name == 'Snacks') return Icons.cookie;
    return Icons.nightlight;
  }

  Color _getMealColor(String name) {
    if (name == 'Breakfast') return AppColors.neonCyan;
    if (name == 'Lunch') return AppColors.neonYellow;
    if (name == 'Snacks') return AppColors.neonPink;
    return AppColors.primary;
  }

  /// Returns (mealName, isLive). Picks the currently serving meal,
  /// or the next upcoming one, wrapping to next day's Breakfast after Dinner.
  (String mealName, bool isLive) _resolveCurrentMeal(double now) {
    for (final meal in _mealOrder) {
      final times = _mealTimes[meal]!;
      if (now >= times[0] && now < times[1]) {
        return (meal, true);
      }
    }

    for (final meal in _mealOrder) {
      final times = _mealTimes[meal]!;
      if (now < times[0]) {
        return (meal, false);
      }
    }

    return ('Breakfast', false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messAsync = ref.watch(messProvider);

    return messAsync.when(
      loading: () => _buildLoadingSkeleton(),
      error: (e, _) {
        final fallbackList = MessDefaultTemplate.buildMenus(true);
        final Map<String, MessMenu> fallbackMenu = {for (var m in fallbackList) m.day: m};
        final fallbackState = MessState(
          weeklyMenu: fallbackMenu,
          isAdmin: false,
          isEvenWeek: true,
          fromCache: true,
          lastUpdated: DateTime.now(),
        );
        return _buildMenuContent(context, fallbackState);
      },
      data: (messState) {
        if (messState.weeklyMenu.isEmpty) {
          final fallbackList = MessDefaultTemplate.buildMenus(messState.isEvenWeek);
          final Map<String, MessMenu> fallbackMenu = {for (var m in fallbackList) m.day: m};
          return _buildMenuContent(context, messState.copyWith(weeklyMenu: fallbackMenu));
        }
        return _buildMenuContent(context, messState);
      },
    );
  }

  Widget _buildMenuContent(BuildContext context, MessState messState) {
    final now = DateTime.now();
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final todayName = dayNames[now.weekday - 1];
    final double currentTime = now.hour + now.minute / 60.0;

    final (resolvedMeal, isLive) = _resolveCurrentMeal(currentTime);

    final dayMenu = messState.weeklyMenu[todayName];
    final weekLabel = messState.isEvenWeek ? 'Even Week Menu' : 'Odd Week Menu';

    late List<String> mealItems;
    if (dayMenu != null) {
      final firestoreMeal = dayMenu.meals.firstWhere(
        (m) => m.name == resolvedMeal,
        orElse: () => dayMenu.meals.isNotEmpty
            ? dayMenu.meals[0]
            : MessMeal(name: resolvedMeal, items: []),
      );
      mealItems = firestoreMeal.items;
    } else {
      mealItems = ['—'];
    }

    final mealIcon = _getMealIcon(resolvedMeal);
    final mealColor = _getMealColor(resolvedMeal);
    final mealTime = _getMealTime(resolvedMeal);
    final mealItemsText = mealItems.join(', ');

    return GestureDetector(
      onTap: () => context.push('/mess'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F131C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E2638), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        color: mealColor,
                        size: 22,
                        shadows: [Shadow(color: mealColor, blurRadius: 10)],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mess Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(isLive),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Meal card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mealColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(color: mealColor, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: mealColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(mealIcon, color: mealColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLive
                                ? '$resolvedMeal — Serving Now'
                                : 'Up Next: $resolvedMeal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: mealColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mealItemsText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(mealTime, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(weekLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),

            // ── All meals quick strip ────────────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMealStripRow(currentTime),
            ),

            // ── "View Full Menu" button ──────────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/mess'),
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('View Full Day Menu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton while loading ──────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }

  /// Status badge — LIVE (green pulse) or UPCOMING (blue)
  Widget _buildStatusBadge(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            _PulseDot(color: AppColors.success),
            const SizedBox(width: 5),
          ],
          Text(
            isLive ? 'LIVE' : 'UPCOMING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLive ? AppColors.success : AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick row showing all 4 meal slots with their open/closed status
  Widget _buildMealStripRow(double currentTime) {
    return Row(
      children: _mealOrder.map((meal) {
        final times = _mealTimes[meal]!;
        final isLive = currentTime >= times[0] && currentTime < times[1];
        final isPast = currentTime >= times[1];
        final color = _getMealColor(meal);
        final icon = _getMealIcon(meal);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isLive
                  ? color.withValues(alpha: 0.15)
                  : isPast
                      ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                      : const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLive ? color.withValues(alpha: 0.5) : const Color(0xFF1E293B),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isLive
                      ? color
                      : isPast
                          ? AppColors.textDisabled
                          : AppColors.textSecondary,
                ),
                const SizedBox(height: 3),
                Text(
                  meal.substring(0, meal.length > 5 ? 5 : meal.length),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                    color: isLive
                        ? color
                        : isPast
                            ? AppColors.textDisabled
                            : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Animated pulsing dot for the LIVE indicator
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color, blurRadius: 4)],
        ),
      ),
    );
  }
}
