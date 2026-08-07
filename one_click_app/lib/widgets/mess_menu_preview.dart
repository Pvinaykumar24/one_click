import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/mess_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessMenuPreview extends ConsumerWidget {
  const MessMenuPreview({super.key});

  static const _mealTimes = {
    'Breakfast': [7.5, 9.5],
    'Lunch': [12.5, 14.25],
    'Snacks': [17.0, 18.0],
    'Dinner': [19.5, 21.0],
  };

  static const _mealOrder = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  String _getMealTime(String name) {
    if (name == 'Breakfast') return '7:00 – 9:30 AM';
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
    if (name == 'Breakfast') return AppColors.neoCyan;
    if (name == 'Lunch') return AppColors.neoYellow;
    if (name == 'Snacks') return AppColors.neoPink;
    return AppColors.neoPurple;
  }

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
    final weekLabel = messState.isEvenWeek ? 'Even Week' : 'Odd Week';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neoPink,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Mess Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(isLive),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Meal Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mealColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Icon(mealIcon, color: Colors.black, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLive ? '$resolvedMeal — Serving Now ⚡' : 'Up Next: $resolvedMeal',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mealItemsText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$mealTime • $weekLabel',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? AppColors.neoLime : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        isLive ? 'LIVE SERVING' : 'TODAY',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}
