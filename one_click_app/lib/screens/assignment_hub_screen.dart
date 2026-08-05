import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/assignment_service.dart';

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
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          if (assignmentState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref.read(assignmentProvider.notifier).syncWithClassroom(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Missing'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
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
      return const Center(
        child: Text('No assignments'),
      );
    }
    return ListView.builder(
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
          border: Border.all(color: Colors.white24, width: 1),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1E293B),
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
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  onSelected: (status) {
                    if (status == 'delete') {
                      ref.read(assignmentProvider.notifier).deleteAssignment(a.id);
                    } else {
                      ref.read(assignmentProvider.notifier).updateAssignmentStatus(a.id, status);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                    const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                    const PopupMenuItem(value: 'missing', child: Text('Mark Missing')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${a.course} • Due ${a.dueDate.toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                a.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            _buildStatusBadge(a.status),
          ],
        ),
      );

  Widget _buildStatusBadge(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(s).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          s,
          style: TextStyle(
            color: _getStatusColor(s),
            fontWeight: FontWeight.bold,
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
    final courseController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextButton(
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
                  child: Text(
                      'Due Date: ${selectedDate.toString().split(' ')[0]}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final assignment = Assignment(
                  id: '',
                  title: titleController.text,
                  course: courseController.text,
                  dueDate: selectedDate,
                  status: 'pending',
                  description: descriptionController.text,
                );
                ref.read(assignmentProvider.notifier).addAssignment(assignment);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}