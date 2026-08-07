import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/grid_background.dart';
import '../services/assignment_service.dart';
import '../services/timetable_service.dart';
import '../services/attendance_service.dart';

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

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    final timetableSlots = ref.read(timetableProvider.notifier).slots;
    final enrolledCourses = timetableSlots.map((s) => s.subject).toSet().toList()..sort();
    final customSubjects = ref.read(customAttendanceSubjectsProvider);
    final allSubjects = {...enrolledCourses, ...customSubjects}.toList()..sort();
    
    String selectedCourse = allSubjects.isNotEmpty ? allSubjects.first : 'General';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black, width: 2.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_task, color: Colors.black),
                  SizedBox(width: 10),
                  Text('Add Custom Task', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g. Lab Report 3'),
                    ),
                    const SizedBox(height: 12),
                    if (allSubjects.isNotEmpty) ...[
                      const Text('Course:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourse,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        items: allSubjects.map<DropdownMenuItem<String>>((String s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCourse = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Due Date:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month, size: 16, color: Colors.black),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
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
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoYellow),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final task = Assignment(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      course: selectedCourse,
                      dueDate: selectedDate,
                      status: 'pending',
                      description: descController.text.trim(),
                    );

                    await ref.read(assignmentProvider.notifier).addAssignment(task);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Add Task', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(assignmentProvider).valueOrNull ?? AssignmentState(assignments: []);
    
    final pending = assignmentState.assignments.where((a) => a.status == 'pending').toList();
    final completed = assignmentState.assignments.where((a) => a.status == 'completed').toList();
    final missing = assignmentState.assignments.where((a) => a.status == 'missing').toList();

    return NeoMotionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
          title: const Text('Tasks & Assignments', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          actions: [
            if (assignmentState.isSyncing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.black),
                onPressed: () => ref.read(assignmentProvider.notifier).syncWithClassroom(),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Completed (${completed.length})'),
              Tab(text: 'Missing (${missing.length})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: AppColors.neoYellow,
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAssignmentList(pending),
            _buildAssignmentList(completed),
            _buildAssignmentList(missing),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentList(List<Assignment> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.task_alt, size: 48, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text(
              'No assignments in this list 🎉',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final item = assignments[index];
        final isCompleted = item.status == 'completed';
        final isMissing = item.status == 'missing';
        final cardBg = isCompleted ? AppColors.neoLime : isMissing ? AppColors.neoPink : Colors.white;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      item.course,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (val) async {
                      if (val == 'delete') {
                        await ref.read(assignmentProvider.notifier).deleteAssignment(item.id);
                      } else {
                        await ref.read(assignmentProvider.notifier).updateAssignmentStatus(item.id, val);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                      const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'missing', child: Text('Mark Missing')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isMissing ? Colors.white : Colors.black,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMissing ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMissing ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (item.classroomId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neoYellow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: const Text('GCR Synced', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}