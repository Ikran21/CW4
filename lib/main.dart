// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adoption & Travel Plans',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PlanManagerScreen(),
    );
  }
}

// Priority enum
enum PriorityLevel { low, medium, high }

// Extension to get display name and color for priority
extension PriorityExtension on PriorityLevel {
  String get name {
    switch (this) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case PriorityLevel.low:
        return Colors.green;
      case PriorityLevel.medium:
        return Colors.orange;
      case PriorityLevel.high:
        return Colors.red;
    }
  }
}

// Plan data model
class Plan {
  String id;
  String name;
  String description;
  DateTime date;
  bool isCompleted;
  PriorityLevel priority;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    this.isCompleted = false,
    this.priority = PriorityLevel.medium,
  });
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({Key? key}) : super(key: key);

  @override
  _PlanManagerScreenState createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  // List to store all plans
  List<Plan> plans = [];

  // Controllers for text input
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Calendar format and selected day
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Map to store plans by date
  Map<DateTime, List<Plan>> plansByDate = {};

  // Selected priority level for new/edited plans
  PriorityLevel selectedPriority = PriorityLevel.medium;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Add some sample plans
    _addPlan(
      "Adopt a Dog",
      "Visit the local shelter to meet potential dogs",
      DateTime.now().add(const Duration(days: 2)),
      PriorityLevel.high,
    );
    _addPlan(
      "Visit Beach",
      "Weekend trip to the beach",
      DateTime.now().add(const Duration(days: 5)),
      PriorityLevel.low,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Method to add a new plan
  void _addPlan(
    String name,
    String description,
    DateTime date,
    PriorityLevel priority,
  ) {
    setState(() {
      final newPlan = Plan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        date: date,
        priority: priority,
      );

      plans.add(newPlan);

      // Add plan to date map
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      if (plansByDate[normalizedDate] != null) {
        plansByDate[normalizedDate]!.add(newPlan);
        // Sort by priority
        _sortPlansByPriority(normalizedDate);
      } else {
        plansByDate[normalizedDate] = [newPlan];
      }
    });
  }

  // Sort plans by priority (high to low)
  void _sortPlansByPriority(DateTime date) {
    if (plansByDate[date] != null) {
      plansByDate[date]!.sort((a, b) {
        // Sort by priority first (high to low)
        int priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        // If same priority, sort by completion status
        return a.isCompleted ? 1 : -1;
      });
    }
  }

  // Method to update an existing plan
  void _updatePlan(
    String id,
    String name,
    String description,
    DateTime date,
    PriorityLevel priority,
  ) {
    setState(() {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index != -1) {
        // Remove from old date
        final oldPlan = plans[index];
        final oldDate = DateTime(
          oldPlan.date.year,
          oldPlan.date.month,
          oldPlan.date.day,
        );
        plansByDate[oldDate]?.removeWhere((plan) => plan.id == id);

        // Update plan
        plans[index] = Plan(
          id: id,
          name: name,
          description: description,
          date: date,
          isCompleted: plans[index].isCompleted,
          priority: priority,
        );

        // Add to new date
        final newDate = DateTime(date.year, date.month, date.day);
        if (plansByDate[newDate] != null) {
          plansByDate[newDate]!.add(plans[index]);
          _sortPlansByPriority(newDate);
        } else {
          plansByDate[newDate] = [plans[index]];
        }
      }
    });
  }

  // Method to toggle completion status
  void _togglePlanCompletion(String id) {
    setState(() {
      final index = plans.indexWhere((plan) => plan.id == id);
      if (index != -1) {
        plans[index].isCompleted = !plans[index].isCompleted;

        // Re-sort plans for the date
        final date = DateTime(
          plans[index].date.year,
          plans[index].date.month,
          plans[index].date.day,
        );
        _sortPlansByPriority(date);
      }
    });
  }

  // Method to delete a plan
  void _deletePlan(String id) {
    setState(() {
      final plan = plans.firstWhere((plan) => plan.id == id);
      final date = DateTime(plan.date.year, plan.date.month, plan.date.day);

      // Remove from date map
      plansByDate[date]?.removeWhere((plan) => plan.id == id);

      // Remove from main list
      plans.removeWhere((plan) => plan.id == id);
    });
  }

  // Show dialog to add or edit a plan
  void _showPlanDialog({Plan? plan}) {
    final isEditing = plan != null;

    if (isEditing) {
      nameController.text = plan.name;
      descriptionController.text = plan.description;
      selectedPriority = plan.priority;
    } else {
      nameController.clear();
      descriptionController.clear();
      selectedPriority = PriorityLevel.medium;
    }

    DateTime selectedDate =
        isEditing ? plan.date : _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Edit Plan' : 'Create New Plan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Plan Name'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (pickedDate != null) {
                            selectedDate = pickedDate;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Priority: '),
                      const SizedBox(width: 8),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return DropdownButton<PriorityLevel>(
                            value: selectedPriority,
                            items:
                                PriorityLevel.values.map((priority) {
                                  return DropdownMenuItem<PriorityLevel>(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: priority.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(priority.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedPriority = newValue!;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();

                  if (name.isNotEmpty) {
                    if (isEditing) {
                      _updatePlan(
                        plan.id,
                        name,
                        description,
                        selectedDate,
                        selectedPriority,
                      );
                    } else {
                      _addPlan(
                        name,
                        description,
                        selectedDate,
                        selectedPriority,
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          ),
    );
  }

  // Build the calendar widget
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return plansByDate[normalizedDay] ?? [];
      },
      calendarStyle: const CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Build a single plan item for the list
  Widget _buildPlanItem(Plan plan) {
    return GestureDetector(
      onLongPress: () {
        _showPlanDialog(plan: plan);
      },
      onDoubleTap: () {
        _deletePlan(plan.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${plan.name} deleted')));
      },
      child: Dismissible(
        key: Key(plan.id),
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.check, color: Colors.white),
        ),
        secondaryBackground: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.cancel, color: Colors.white),
        ),
        onDismissed: (direction) {
          _togglePlanCompletion(plan.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                plan.isCompleted
                    ? '${plan.name} marked as incomplete'
                    : '${plan.name} marked as completed',
              ),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  _togglePlanCompletion(plan.id);
                },
              ),
            ),
          );
        },
        confirmDismiss: (direction) async {
          _togglePlanCompletion(plan.id);
          return false;
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: plan.isCompleted ? Colors.green[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: plan.isCompleted ? Colors.green : Colors.blue,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    plan.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: plan.isCompleted ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            plan.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: plan.priority.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: plan.priority.color, width: 1),
                    ),
                    child: Text(
                      plan.priority.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: plan.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (plan.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    plan.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      decoration:
                          plan.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(plan.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the plan list for selected date
  Widget _buildPlanList() {
    final selectedDate = _selectedDay ?? DateTime.now();
    final normalizedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final plansForDay = plansByDate[normalizedDate] ?? [];

    // Sort plans by priority
    _sortPlansByPriority(normalizedDate);

    if (plansForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No plans for ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _showPlanDialog();
              },
              child: const Text('Add a Plan'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: plansForDay.length,
      itemBuilder: (context, index) {
        return _buildPlanItem(plansForDay[index]);
      },
    );
  }

  // DragTarget for dropping plans on calendar
  Widget _buildDragTarget(BuildContext context) {
    return DragTarget<Plan>(
      builder: (context, candidateData, rejectedData) {
        return _buildCalendar();
      },
      onAccept: (plan) {
        _updatePlan(
          plan.id,
          plan.name,
          plan.description,
          _selectedDay ?? DateTime.now(),
          plan.priority,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${plan.name} moved to ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adoption & Travel Plans')),
      body: Column(
        children: [
          _buildDragTarget(context),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Plans for ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _showPlanDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Plan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPlanList(),
            ),
          ),
        ],
      ),
    );
  }
}
