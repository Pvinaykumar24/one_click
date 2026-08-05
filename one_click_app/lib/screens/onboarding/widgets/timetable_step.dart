import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'base_step.dart';

class TimetableStep extends StatefulWidget {
  final List<Map<String, dynamic>> slots;
  final ValueChanged<List<Map<String, dynamic>>> onSlotsChanged;
  final VoidCallback onNext;

  const TimetableStep({
    super.key,
    required this.slots,
    required this.onSlotsChanged,
    required this.onNext,
  });

  @override
  State<TimetableStep> createState() => _TimetableStepState();
}

class _TimetableStepState extends State<TimetableStep> {
  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
  final List<String> _sortedTimes = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: 'Your Schedule',
      subtitle:
          'Tap the grid or + to add your classes. This syncs with Attendance and GPA.',
      child: Column(
        children: [
          _buildTimetableGrid(),
        ],
      ),
      onNext: () {
        if (widget.slots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one class!')),
          );
          return;
        }
        widget.onNext();
      },
    );
  }

  Widget _buildTimetableGrid() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header Row
          Container(
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48),
                ..._days.map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows for each hour
          ..._sortedTimes.map((time) {
            if (time == '13:00') {
              return _buildLunchRow(time);
            }
            return _buildTimeRowDynamic(time);
          }),
          // Add Button Row
          GestureDetector(
            onTap: () => _showAddSlotDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Color(0xFF0F172A))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Add Class Slot',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLunchRow(String time) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: const Text(
                'LUNCH BREAK',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.border,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRowDynamic(String timeHour) {
    List<Widget> dayWidgets = [];
    int timeHourInt = int.parse(timeHour.split(':')[0]);

    for (int dayIdx = 1; dayIdx <= 5; dayIdx++) {
      var slotsForDayAndHour = widget.slots.where((s) {
        if (s['day'] != dayIdx) return false;
        int slotStartHour = int.parse(s['start'].split(':')[0]);
        int slotEndHour = int.parse(s['end'].split(':')[0]);
        return slotStartHour <= timeHourInt && slotEndHour > timeHourInt;
      }).toList();

      if (slotsForDayAndHour.isNotEmpty) {
        var slot = slotsForDayAndHour.first;
        dayWidgets.add(
          Expanded(
            child: GestureDetector(
              onTap: () => _editOnboardingSlot(slot),
              child: _buildFilledSlotNode(
                slot['subject'],
                slot['room'] ?? 'TBD',
                slot['type'] == 'Lab' ? AppColors.neonCyan : AppColors.primary,
                dayIdx == 5,
              ),
            ),
          ),
        );
      } else {
        dayWidgets.add(
          _buildEmptySlot(dayIdx, timeHourInt, isLast: dayIdx == 5),
        );
      }
    }

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(top: 6, right: 6),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Text(
              timeHour,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...dayWidgets,
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int day, int hour, {bool isLast = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showAddSlotDialog(initialDay: day, initialHour: hour),
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(right: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 10, color: Colors.white10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledSlotNode(
    String title,
    String subtitle,
    Color color,
    bool isLast,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      padding: const EdgeInsets.all(1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
              maxLines: 1,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 6,
                color: color.withValues(alpha: 0.8),
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog({int? initialDay, int? initialHour}) {
    String subject = '';
    String room = 'TBD';
    int credits = 3;
    int selectedDayIdx = initialDay ?? 1;
    TimeOfDay start = TimeOfDay(hour: initialHour ?? 9, minute: 0);
    TimeOfDay end = TimeOfDay(hour: (initialHour ?? 9) + 1, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Add Time Slot',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) => subject = v,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  onChanged: (v) => room = v,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => credits = int.tryParse(v) ?? 3,
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    hintText: '3',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: AppColors.neonCyan),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Day: ',
                      style: TextStyle(color: Colors.white60),
                    ),
                    DropdownButton<int>(
                      value: selectedDayIdx,
                      dropdownColor: AppColors.surface,
                      items: List.generate(5, (i) => i + 1)
                          .map(
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(
                                _days[i - 1],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedDayIdx = v!),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final p = await showTimePicker(
                            context: context,
                            initialTime: start,
                          );
                          if (p != null) setDialogState(() => start = p);
                        },
                        child: Text(
                          start.format(context),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white24,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final p = await showTimePicker(
                            context: context,
                            initialTime: end,
                          );
                          if (p != null) setDialogState(() => end = p);
                        },
                        child: Text(
                          end.format(context),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subject.isNotEmpty) {
                  final newSlots = List<Map<String, dynamic>>.from(widget.slots);
                  newSlots.add({
                    'subject': subject,
                    'credits': credits,
                    'day': selectedDayIdx,
                    'start':
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                    'end':
                        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                    'room': room,
                    'type': 'Lecture',
                  });
                  widget.onSlotsChanged(newSlots);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editOnboardingSlot(Map<String, dynamic> slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove ${slot['subject']}?'),
        content: const Text('Do you want to remove this slot from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newSlots = List<Map<String, dynamic>>.from(widget.slots);
              newSlots.remove(slot);
              widget.onSlotsChanged(newSlots);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
