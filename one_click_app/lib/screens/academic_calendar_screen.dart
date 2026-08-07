import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/events_service.dart';
import '../services/admin_service.dart';

import '../core/widgets/grid_background.dart';

class AcademicCalendarScreen extends ConsumerStatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  ConsumerState<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends ConsumerState<AcademicCalendarScreen> {
  String _filter = 'All'; // 'All', 'exam', 'holiday', 'academic'

  @override
  Widget build(BuildContext context) {
    final eventsStateValue = ref.watch(eventsProvider);
    final events = eventsStateValue.valueOrNull ?? [];
    final isLoading = eventsStateValue.isLoading;
    final isAdmin = ref.watch(adminProvider).valueOrNull ?? false;

    // Apply filter
    List<AcademicEvent> filteredEvents = events;
    if (_filter != 'All') {
      filteredEvents = filteredEvents.where((e) => e.type == _filter.toLowerCase()).toList();
    }

    return NeoMotionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilters(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : filteredEvents.isEmpty
                        ? const Center(child: Text('No events found', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
                              bool showMonthHeader = index == 0 || 
                                  event.date.month != filteredEvents[index-1].date.month ||
                                  event.date.year != filteredEvents[index-1].date.year;
                              
                              return _buildEventCard(event, showMonthHeader, isAdmin);
                            },
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: isAdmin 
          ? FloatingActionButton(
              onPressed: () => _addEventDialog(),
              backgroundColor: AppColors.neoYellow,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text('Academic Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(width: 40), 
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Exam', 'Holiday', 'Academic'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _filter = filter);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(AcademicEvent event, bool showMonthHeader, bool isAdmin) {
    bool isPast = event.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMonthHeader)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
            child: Text(
              _getMonthYear(event.date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        Opacity(
          opacity: isPast ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
              border: Border.all(color: const Color(0xFF1E293B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: event.color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(_getShortMonth(event.date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: event.color)),
                      Text('${event.date.day}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: event.color)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          decoration: isPast ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(event.icon, size: 14, color: event.color),
                          const SizedBox(width: 4),
                          Text(
                            event.type.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: event.color, letterSpacing: 1),
                          ),
                          if (isPast) ...[
                            const SizedBox(width: 8),
                            const Text('• COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _confirmDelete(event),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(AcademicEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${event.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(eventsProvider.notifier).deleteEvent(event.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _addEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'academic';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add New Event', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Title', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                DropdownButton<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF1E293B),
                  items: ['academic', 'holiday', 'exam'].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final newEvent = AcademicEvent(
                  id: '',
                  title: titleController.text,
                  description: descController.text,
                  date: selectedDate,
                  type: selectedType,
                  icon: selectedType == 'exam' ? Icons.assignment : (selectedType == 'holiday' ? Icons.celebration : Icons.school),
                  color: selectedType == 'exam' ? AppColors.error : (selectedType == 'holiday' ? AppColors.neonPink : AppColors.warning),
                );
                await ref.read(eventsProvider.notifier).addEvent(newEvent);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[date.month - 1];
  }

  String _getShortMonth(DateTime date) {
    const shortMonths = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return shortMonths[date.month - 1];
  }

  String _getMonthYear(DateTime date) {
    return '${_getMonth(date)} ${date.year}';
  }
}
