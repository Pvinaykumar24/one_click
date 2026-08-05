import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/mess_service.dart';

class MessMenuScreen extends ConsumerStatefulWidget {
  const MessMenuScreen({super.key});

  @override
  ConsumerState<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends ConsumerState<MessMenuScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1;
  bool _isFullWeekView = false;
  bool _isInitializing = false;
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: messAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, st) => Center(
            child: Text(
              'Error loading menu: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (messState) => Column(
            children: [
              _buildHeader(messState),
              Expanded(
                child: messState.weeklyMenu.isEmpty
                    ? _buildEmptyState(messState)
                    : _isFullWeekView
                        ? _buildFullWeekView(messState)
                        : _buildSingleDayView(messState),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ref.watch(messProvider).valueOrNull?.weeklyMenu.isNotEmpty == true
          ? FloatingActionButton(
              mini: true,
              onPressed: () => setState(() => _isFullWeekView = !_isFullWeekView),
              backgroundColor: AppColors.primary,
              child: Icon(
                _isFullWeekView ? Icons.calendar_view_day : Icons.calendar_view_week,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  // ── Empty state shown when Firestore has no menu data yet ──────────────────

  Widget _buildEmptyState(MessState messState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Menu Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The mess menu for this week hasn\'t been set up yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            if (messState.isAdmin) ...[
              const SizedBox(height: 32),
              _isInitializing
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : ElevatedButton.icon(
                      onPressed: _initializeMenu,
                      icon: const Icon(Icons.download_for_offline_outlined),
                      label: const Text('Initialize Default Menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              const Text(
                'This will write the default template menu for both\nEven and Odd weeks. You can edit meals afterwards.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _initializeMenu() async {
    setState(() => _isInitializing = true);
    try {
      await ref.read(messProvider.notifier).initializeDefaultMenu();
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  // ── Single day view ────────────────────────────────────────────────────────

  Widget _buildSingleDayView(MessState messState) {
    final currentDayName = _daysOfWeek[_selectedDayIndex];
    final dayMenu = messState.weeklyMenu[currentDayName];

    if (dayMenu == null) {
      return Center(
        child: Text(
          'No menu for $currentDayName',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _buildMealsFromMenu(dayMenu, currentDayName, messState);
  }

  Widget _buildMealsFromMenu(MessMenu dayMenu, String currentDayName, MessState messState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ...dayMenu.meals.asMap().entries.map((entry) {
            int idx = entry.key;
            var meal = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildMealSection(
                icon: _getMealIcon(meal.name),
                title: meal.name,
                time: _getMealTime(meal.name),
                isServingNow: _isServingNow(meal.name),
                mealName: meal.items.join(', '),
                kcal: '${meal.items.length * 150} kcal',
                protein: '${meal.items.length * 5}g Protein',
                imgUrl: meal.imageUrl,
                opacity: 1.0,
                onEdit: messState.isAdmin
                    ? () => _editMeal(currentDayName, idx, meal)
                    : null,
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Full week view ─────────────────────────────────────────────────────────

  Widget _buildFullWeekView(MessState messState) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _daysOfWeek.length,
      itemBuilder: (context, index) {
        final dayName = _daysOfWeek[index];
        final dayMenu = messState.weeklyMenu[dayName];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonCyan,
                ),
              ),
            ),
            if (dayMenu == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No menu data',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...dayMenu.meals.map(
                (meal) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getMealIcon(meal.name),
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              meal.items.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(color: Color(0xFF1E293B), height: 32),
          ],
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(MessState messState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _isFullWeekView ? 'Full Week Menu' : 'Mess Menu',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      messState.isEvenWeek ? 'EVEN WEEK' : 'ODD WEEK',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => ref.read(messProvider.notifier).toggleWeek(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (!_isFullWeekView && messState.weeklyMenu.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _daysOfWeek.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == _selectedDayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFF1E293B),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _daysOfWeek[index].substring(0, 3),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconData _getMealIcon(String name) {
    if (name.contains('Breakfast')) return Icons.breakfast_dining;
    if (name.contains('Lunch')) return Icons.lunch_dining;
    if (name.contains('Snacks')) return Icons.cookie;
    return Icons.dinner_dining;
  }

  String _getMealTime(String name) {
    if (name.contains('Breakfast')) return '07:30 - 09:00';
    if (name.contains('Lunch')) return '12:30 - 14:15';
    if (name.contains('Snacks')) return '17:00 - 18:00';
    return '19:30 - 21:00';
  }

  bool _isServingNow(String name) {
    final now = DateTime.now();
    final h = now.hour;
    if (now.weekday - 1 != _selectedDayIndex) return false;

    if (name.contains('Breakfast')) return h >= 7 && h < 9;
    if (name.contains('Lunch')) return h >= 12 && h < 15;
    if (name.contains('Snacks')) return h >= 17 && h < 18;
    return h >= 19 && h < 21;
  }

  void _editMeal(String day, int mealIndex, MessMeal meal) {
    final controller = TextEditingController(text: meal.items.join(', '));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Edit ${meal.name} - $day',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter items (comma separated)',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newItems = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              await ref.read(messProvider.notifier).updateMeal(day, mealIndex, newItems);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection({
    required IconData icon,
    required String title,
    required String time,
    required bool isServingNow,
    required String mealName,
    required String kcal,
    required String protein,
    required String imgUrl,
    required double opacity,
    VoidCallback? onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isServingNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Serving Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                          image: imgUrl.isNotEmpty
                              ? DecorationImage(
                                  image: AssetImage(imgUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imgUrl.isEmpty
                            ? const Icon(
                                Icons.restaurant_menu,
                                color: AppColors.textSecondary,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildBadge(kcal),
                                const SizedBox(width: 8),
                                _buildBadge(protein),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
