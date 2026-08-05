import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/institution.dart';
import '../../../services/institution_service.dart';
import 'base_step.dart';

class SemesterStep extends ConsumerStatefulWidget {
  final String initialCollege;
  final String initialDegreeType;
  final String initialSemester;
  final String initialDepartment;
  final ValueChanged<String> onCollegeChanged;
  final ValueChanged<String> onDegreeTypeChanged;
  final ValueChanged<String> onSemesterChanged;
  final ValueChanged<String> onDepartmentChanged;
  final VoidCallback onNext;

  const SemesterStep({
    super.key,
    required this.initialCollege,
    required this.initialDegreeType,
    required this.initialSemester,
    required this.initialDepartment,
    required this.onCollegeChanged,
    required this.onDegreeTypeChanged,
    required this.onSemesterChanged,
    required this.onDepartmentChanged,
    required this.onNext,
  });

  @override
  ConsumerState<SemesterStep> createState() => _SemesterStepState();
}

class _SemesterStepState extends ConsumerState<SemesterStep> {
  late final TextEditingController _collegeController;
  late String _degreeType;
  late String _semester;
  late String _department;

  @override
  void initState() {
    super.initState();
    _collegeController = TextEditingController(text: widget.initialCollege);
    _degreeType = widget.initialDegreeType;
    _semester = widget.initialSemester;
    _department = widget.initialDepartment;
  }

  @override
  void dispose() {
    _collegeController.dispose();
    super.dispose();
  }

  int _getMaxSems() {
    switch (_degreeType) {
      case 'M.Tech':
        return 4;
      case 'Dual Degree':
        return 10;
      default:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final institution = ref.watch(institutionProvider).valueOrNull;
    final degrees = (institution?.degreeTypes.isNotEmpty == true) ? institution!.degreeTypes : kFallbackDegreeTypes;
    final departments = (institution?.departments.isNotEmpty == true) ? institution!.departments : kFallbackDepartments;
    final degreeItems = degrees.contains(_degreeType) ? degrees : [...degrees, _degreeType];
    final departmentItems = departments.contains(_department) ? departments : [...departments, _department];

    return BaseStep(
      title: 'About You',
      subtitle: 'Tell us about your current academic standing.',
      onNext: widget.onNext,
      child: Column(
        children: [
          TextField(
            controller: _collegeController,
            onChanged: widget.onCollegeChanged,
            decoration: InputDecoration(
              hintText: 'College/University Name',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _degreeType,
            decoration: InputDecoration(
              hintText: 'Degree Programme',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: degreeItems.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _degreeType = v;
                  int max = _getMaxSems();
                  if (int.parse(_semester) > max) {
                    _semester = max.toString();
                    widget.onSemesterChanged(_semester);
                  }
                });
                widget.onDegreeTypeChanged(v);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _semester,
            decoration: InputDecoration(
              hintText: 'Current Semester',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: List.generate(_getMaxSems(), (i) => (i + 1).toString())
                .map(
                  (s) => DropdownMenuItem(value: s, child: Text('Semester $s')),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _semester = v);
                widget.onSemesterChanged(v);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _department,
            decoration: InputDecoration(
              hintText: 'Department',
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: departmentItems.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _department = v);
                widget.onDepartmentChanged(v);
              }
            },
          ),
        ],
      ),
    );
  }
}
