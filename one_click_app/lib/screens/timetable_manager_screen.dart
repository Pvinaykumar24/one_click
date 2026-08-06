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
  int _selectedDayIndex = DateTime.now().weekday; // 1 = Mon ... 7 = Sun
  bool _isGridView = false;

  final List<String> _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final List<String> _fullDayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  void _showAddEditSlotModal([TimetableSlot? slotToEdit]) {
    final isEditing = slotToEdit != null;
    int selectedDay = slotToEdit?.day ?? _selectedDayIndex;
    final subjectController = TextEditingController(text: slotToEdit?.subject ?? '');
    final roomController = TextEditingController(text: slotToEdit?.room ?? '');
    final startController = TextEditingController(text: slotToEdit?.start ?? '09:00');
    final endController = TextEditingController(text: slotToEdit?.end ?? '10:00');
    final creditsController = TextEditingController(text: (slotToEdit?.credits ?? 3).toString());
    String selectedType = slotToEdit?.type ?? 'Lecture';

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
                        Text(
                          isEditing ? 'Edit Class Slot' : 'Add Custom Class Slot',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Day Selector
                    const Text('DAY OF WEEK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: _inputDecoration('Select Day'),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: List.generate(7, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${_fullDayNames[i]} (${_dayNames[i]})'),
                      )),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Subject Name
                    const Text('SUBJECT / COURSE NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subjectController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('e.g. Data Structures & Algorithms'),
                    ),
                    const SizedBox(height: 12),

                    // Room & Credits
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ROOM / VENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: roomController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('e.g. Lab 204'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CREDITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: creditsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('3'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Start & End Times
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('START TIME (HH:MM)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: startController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('09:00'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('END TIME (HH:MM)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: endController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('10:00'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Class Type
                    const Text('CLASS TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: _inputDecoration('Select Type'),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: ['Lecture', 'Lab', 'Tutorial', 'Seminar', 'Exam']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit & Delete Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final subject = subjectController.text.trim();
                              if (subject.isEmpty) return;

                              final notifier = ref.read(timetableProvider.notifier);
                              if (isEditing) {
                                await notifier.deleteSlot(slotToEdit.id);
                              }

                              await notifier.addSlot({
                                'day': selectedDay,
                                'subject': subject,
                                'room': roomController.text.trim(),
                                'start': startController.text.trim(),
                                'end': endController.text.trim(),
                                'credits': int.tryParse(creditsController.text) ?? 3,
                                'type': selectedType,
                              });

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(
                              isEditing ? 'Save Changes' : 'Add Slot',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error.withValues(alpha: 0.2),
                              padding: const EdgeInsets.all(14),
                            ),
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () async {
                              await ref.read(timetableProvider.notifier).deleteSlot(slotToEdit.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ],
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDaySelectorRow(),
            Expanded(
              child: timetableState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error loading timetable: $e', style: const TextStyle(color: AppColors.error))),
                data: (slots) {
                  if (slots.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _isGridView ? _buildGridView(slots) : _buildAgendaView(slots);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSlotModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timetable Manager',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '7-Day Custom Class Schedule',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view, color: AppColors.primary),
                tooltip: _isGridView ? 'Agenda View' : 'Grid View',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectorRow() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final dayNum = index + 1;
          final isSelected = dayNum == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = dayNum),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF1E293B)),
              ),
              alignment: Alignment.center,
              child: Text(
                _dayNames[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No Classes Scheduled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "+ Add Slot" below to create custom classes for any day of the week (Monday through Sunday)!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _seedDefaultSampleTimetable,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Load Sample Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDefaultSampleTimetable() async {
    final defaultSlots = [
      {'day': 1, 'start': '09:00', 'end': '10:00', 'subject': 'Data Structures', 'room': 'CS-101', 'type': 'Lecture', 'credits': 3},
      {'day': 1, 'start': '10:00', 'end': '11:00', 'subject': 'Operating Systems', 'room': 'CS-102', 'type': 'Lecture', 'credits': 3},
      {'day': 2, 'start': '11:00', 'end': '13:00', 'subject': 'Algorithms Lab', 'room': 'Lab-3', 'type': 'Lab', 'credits': 2},
      {'day': 3, 'start': '09:00', 'end': '10:00', 'subject': 'Database Systems', 'room': 'CS-103', 'type': 'Lecture', 'credits': 3},
      {'day': 4, 'start': '14:00', 'end': '16:00', 'subject': 'Computer Networks Lab', 'room': 'Lab-1', 'type': 'Lab', 'credits': 2},
      {'day': 5, 'start': '10:00', 'end': '11:00', 'subject': 'Software Engineering', 'room': 'CS-104', 'type': 'Lecture', 'credits': 3},
      {'day': 6, 'start': '10:00', 'end': '12:00', 'subject': 'Weekend AI Seminar', 'room': 'Auditorium', 'type': 'Seminar', 'credits': 1},
    ];
    await ref.read(timetableProvider.notifier).addSlots(defaultSlots);
  }

  Widget _buildAgendaView(List<TimetableSlot> allSlots) {
    final daySlots = allSlots.where((s) => s.day == _selectedDayIndex).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (daySlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No classes on ${_fullDayNames[_selectedDayIndex - 1]}',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: daySlots.length,
      itemBuilder: (context, index) {
        final slot = daySlots[index];
        final isLab = slot.type == 'Lab';
        final color = isLab ? AppColors.neonCyan : AppColors.primary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isLab ? Icons.computer : Icons.book, color: color),
            ),
            title: Text(
              slot.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${slot.start} - ${slot.end} • ${slot.room} • ${slot.credits} Credits',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                slot.type,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            onTap: () => _showAddEditSlotModal(slot),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<TimetableSlot> allSlots) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(7, (dayIdx) {
          final dayNum = dayIdx + 1;
          final slotsForDay = allSlots.where((s) => s.day == dayNum).toList()
            ..sort((a, b) => a.start.compareTo(b.start));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: ExpansionTile(
              initiallyExpanded: dayNum == _selectedDayIndex,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: dayNum == _selectedDayIndex ? AppColors.primary : const Color(0xFF1E293B),
                child: Text(
                  _dayNames[dayIdx][0],
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              title: Text(
                _fullDayNames[dayIdx],
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
              ),
              subtitle: Text(
                '${slotsForDay.length} classes scheduled',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              children: slotsForDay.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No classes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      )
                    ]
                  : slotsForDay.map((slot) {
                      return ListTile(
                        dense: true,
                        title: Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${slot.start} - ${slot.end} (${slot.room})', style: const TextStyle(color: Colors.white70)),
                        trailing: Icon(Icons.edit, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                        onTap: () => _showAddEditSlotModal(slot),
                      );
                    }).toList(),
            ),
          );
        }),
      ),
    );
  }
}
