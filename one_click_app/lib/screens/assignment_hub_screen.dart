import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/assignment_service.dart';
import '../services/timetable_service.dart';

class AssignmentHubScreen extends ConsumerStatefulWidget {
  const AssignmentHubScreen({super.key});

  @override
  ConsumerState<AssignmentHubScreen> createState() => _AssignmentHubScreenState();
}

class _AssignmentHubScreenState extends ConsumerState<AssignmentHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider).valueOrNull ?? AssignmentState(assignments: []);
    
    final pending =
        assignmentState.assignments.where((a) => a.status == 'pending').toList();
    final completed =
        assignmentState.assignments.where((a) => a.status == 'completed').toList();
    final missing = assignmentState.assignments
        .where((a) => a.status == 'missing')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Tasks & Assignments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (assignmentState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: AppColors.primary),
              onPressed: () => ref.read(assignmentProvider.notifier).syncWithClassroom(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Missing'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList(pending),
          _buildAssignmentList(completed),
          _buildAssignmentList(missing),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No Tasks Found', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Tap "+ Add Task" to create one', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(Assignment a) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1E2638), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0F131C),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  color: const Color(0xFF161C28),
                  onSelected: (status) {
                    if (status == 'delete') {
                      ref.read(assignmentProvider.notifier).deleteAssignment(a.id);
                    } else {
                      ref.read(assignmentProvider.notifier).updateAssignmentStatus(a.id, status);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Text('Mark Pending', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'completed', child: Text('Mark Completed', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'missing', child: Text('Mark Missing', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.course.isNotEmpty ? a.course : 'General', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Due ${a.dueDate.toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                a.description,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            _buildStatusBadge(a.status),
          ],
        ),
      );

  Widget _buildStatusBadge(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(s).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          s.toUpperCase(),
          style: TextStyle(
            color: _getStatusColor(s),
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'missing':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final customCourseController = TextEditingController();
    
    final timetableSlots = ref.read(timetableProvider.notifier).slots;
    final enrolledCourses = timetableSlots.map((s) => s.subject).toSet().toList()..sort();
    
    String selectedCourse = enrolledCourses.isNotEmpty ? enrolledCourses.first : 'General';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F131C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Task / Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                if (enrolledCourses.isNotEmpty) ...[
                  const Text('Select Course', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourse,
                    dropdownColor: const Color(0xFF161C28),
                    style: const TextStyle(color: Colors.white),
                    items: enrolledCourses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCourse = val);
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ] else ...[
                  TextField(
                    controller: customCourseController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  label: Text(
                    'Due Date: ${selectedDate.toString().split(' ')[0]}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final courseName = enrolledCourses.isNotEmpty ? selectedCourse : customCourseController.text.trim();
                final assignment = Assignment(
                  id: '',
                  title: titleController.text.trim(),
                  course: courseName.isNotEmpty ? courseName : 'General',
                  dueDate: selectedDate,
                  status: 'pending',
                  description: descriptionController.text.trim(),
                );
                ref.read(assignmentProvider.notifier).addAssignment(assignment);
                Navigator.pop(context);
              },
              child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}