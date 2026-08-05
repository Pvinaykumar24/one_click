import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/timetable_service.dart';
import '../models/timetable_slot.dart';

class TimetableManagerScreen extends ConsumerStatefulWidget {
  const TimetableManagerScreen({super.key});

  @override
  ConsumerState<TimetableManagerScreen> createState() => _TimetableManagerScreenState();
}

class _TimetableManagerScreenState extends ConsumerState<TimetableManagerScreen> {
  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

  TimetableSlot? selectedSlot;
  bool isEditing = false;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();

  void _onSlotTap(TimetableSlot slot) {
    setState(() {
      selectedSlot = slot;
      isEditing = true;
      _subjectController.text = slot.subject;
      _roomController.text = slot.room;
      _startController.text = slot.start;
      _endController.text = slot.end;
      _creditsController.text = slot.credits.toString();
    });
  }

  void _updateSlot() {
    if (selectedSlot != null) {
      String id = selectedSlot!.id;
      final timetableNotifier = ref.read(timetableProvider.notifier);
      timetableNotifier.deleteSlot(id).then((_) {
        timetableNotifier.addSlot({
          'day': selectedSlot!.day,
          'subject': _subjectController.text,
          'room': _roomController.text,
          'start': _startController.text,
          'end': _endController.text,
          'credits': int.tryParse(_creditsController.text) ?? 3,
          'type': selectedSlot!.type,
        });
      });
      setState(() {
        isEditing = false;
        selectedSlot = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable updated successfully')),
      );
    }
  }

  void _deleteSlot() {
    if (selectedSlot != null) {
      ref.read(timetableProvider.notifier).deleteSlot(selectedSlot!.id);
      setState(() {
        isEditing = false;
        selectedSlot = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Slot removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: timetableState.when(
          data: (slots) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: slots.isEmpty
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildEmptyState(),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSyncCard(),
                              _buildTimetableGrid(),
                              if (isEditing) _buildEditorForm(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSlotDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No classes added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add your first slot using the button below to start building your schedule.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSlotDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add First Class',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSlotDialog() {
    int selectedDay = 2; // Default Tuesday
    String subject = '';
    String room = '';
    String type = 'Lecture';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    int credits = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Add Time Slot',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Day',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  DropdownButton<int>(
                    value: selectedDay,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                      DropdownMenuItem(value: 2, child: Text('Tuesday')),
                      DropdownMenuItem(value: 3, child: Text('Wednesday')),
                      DropdownMenuItem(value: 4, child: Text('Thursday')),
                      DropdownMenuItem(value: 5, child: Text('Friday')),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedDay = val!),
                  ),
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    onChanged: (val) => subject = val,
                  ),
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    onChanged: (val) => room = val,
                  ),
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    onChanged: (val) => credits = int.tryParse(val) ?? 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Type: ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      DropdownButton<String>(
                        value: type,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: ['Lecture', 'Lab', 'Tutorial']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) => setDialogState(() => type = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setDialogState(() => startTime = picked);
                            }
                          },
                          child: Text(
                            'Start: ${startTime.format(context)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setDialogState(() => endTime = picked);
                            }
                          },
                          child: Text(
                            'End: ${endTime.format(context)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (subject.isNotEmpty && room.isNotEmpty) {
                    String startStr =
                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    String endStr =
                        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    ref.read(timetableProvider.notifier).addSlot({
                      'day': selectedDay,
                      'start': startStr,
                      'end': endStr,
                      'subject': subject,
                      'room': room,
                      'credits': credits,
                      'type': type,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$subject slot added successfully'),
                      ),
                    );
                  }
                },
                child: const Text('Add Slot'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Timetable',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dynamic Sync Enabled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Classes will sync with real-time timetable.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: true,
              onChanged: (val) {},
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    // Generate unique time slots to render in rows
    Set<String> uniqueStarts = {};
    for (var slot in ref.read(timetableProvider.notifier).slots) {
      uniqueStarts.add(
        '${slot.start.split(':')[0]}:00',
      ); // Normalize to top of hour roughly
    }
    List<String> sortedTimes = [
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
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
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  ),
                  ..._days.map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 10,
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

            // Generate rows for each hour
            ...sortedTimes.map((time) {
              if (time == '13:00') {
                return _buildLunchRow();
              }
              return _buildTimeRowDynamic(time);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLunchRow() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: const Text(
              '13:00',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
                  fontSize: 10,
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
      // 1=Mon, 5=Fri
      var slotsForDayAndHour = ref.read(timetableProvider.notifier).slots.where((s) {
        if (s.day != dayIdx) return false;
        int slotStartHour = int.parse(s.start.split(':')[0]);
        int slotEndHour = int.parse(s.end.split(':')[0]);
        // If the slot covers this time block
        return slotStartHour <= timeHourInt && slotEndHour > timeHourInt;
      }).toList();

      if (slotsForDayAndHour.isNotEmpty) {
        var slot = slotsForDayAndHour.first;
        dayWidgets.add(
          Expanded(
            child: GestureDetector(
              onTap: () => _onSlotTap(slot),
              child: _buildFilledSlotNode(
                slot.subject,
                slot.room,
                slot.type == 'Lab' ? AppColors.neonCyan : AppColors.primary,
                dayIdx == 5,
              ),
            ),
          ),
        );
      } else {
        dayWidgets.add(_buildEmptySlot(isLast: dayIdx == 5));
      }
    }

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(top: 8, right: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Text(
              timeHour,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...dayWidgets,
        ],
      ),
    );
  }

  Widget _buildEmptySlot({bool isHovered = false, bool isLast = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(right: BorderSide(color: Color(0xFF1E293B))),
        ),
        alignment: Alignment.center,
        child: isHovered
            ? const Icon(Icons.add, color: AppColors.border, size: 14)
            : null,
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
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 7,
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

  Widget _buildEditorForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.edit, color: AppColors.primary, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Slot Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => isEditing = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField('SUBJECT NAME', _subjectController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('ROOM NUMBER', _roomController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'CREDITS',
                    _creditsController,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('START TIME', _startController),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('END TIME', _endController)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Update Slot',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _deleteSlot,
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.textSecondary,
                    ),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
