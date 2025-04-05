import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/maintenance_task_service.dart';
import '../../models/maintenance_task.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';
import '../../constants/app_constants.dart';
import 'package:intl/intl.dart'; // Import the intl package

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'all',
    'pending',
    'in_progress',
    'completed',
    'rejected'
  ];
  final List<String> _tabTitles = [
    'Toutes',
    'En attente',
    'En cours',
    'Terminées',
    'Rejetées'
  ];
  final List<IconData> _tabIcons = [
    Icons.list_alt,
    Icons.pending_actions,
    Icons.work,
    Icons.check_circle,
    Icons.cancel
  ];

  @override
  Widget build(BuildContext context) {
    final taskService =
        Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes Tâches'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tabIcons[index],
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tabTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildAllTasksList(taskService, authService),
                _buildTaskList(taskService, authService, 'pending'),
                _buildTaskList(taskService, authService, 'in_progress'),
                _buildTaskList(taskService, authService, 'completed'),
                _buildTaskList(taskService, authService, 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTasksList(
      MaintenanceTaskService taskService, AuthService authService) {
    return FutureBuilder<Employee?>(
      future: authService.getCurrentEmployee(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${userSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final employee = userSnapshot.data;
        if (employee == null) {
          return const Center(child: Text('Non connecté'));
        }

        return StreamBuilder<List<MaintenanceTask>>(
          stream: taskService.getTasksByEmployee(employee.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];

            if (tasks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Vous n'avez aucune tâche assignée",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Les tâches que vous recevrez apparaîtront ici",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(context, task);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskList(MaintenanceTaskService taskService,
      AuthService authService, String status) {
    return FutureBuilder<Employee?>(
      future: authService.getCurrentEmployee(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${userSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final employee = userSnapshot.data;
        if (employee == null) {
          return const Center(child: Text('Non connecté'));
        }

        return StreamBuilder<List<MaintenanceTask>>(
          stream: taskService.getTasksByStatusAndEmployee(status, employee.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];

            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getEmptyIcon(status),
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(status),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(context, task);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, MaintenanceTask task) {
    final statusColor =
        AppConstants.taskStatusColors[task.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppConstants.taskStatuses[task.status] ?? task.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Échéance: ${_formatDate(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (task.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startTask(task),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _rejectTask(task),
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              )
            else if (task.status == 'in_progress')
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _completeTask(task),
                  icon: const Icon(Icons.check),
                  label: const Text('Terminer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _startTask(MaintenanceTask task) async {
    final taskService =
        Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee();
    if (employee != null) {
      await taskService.changeTaskStatus(task.id, 'in_progress', employee.id);
    }
  }

  Future<void> _rejectTask(MaintenanceTask task) async {
    final taskService =
        Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee();
    if (employee != null) {
      await taskService.changeTaskStatus(task.id, 'rejected', employee.id);
    }
  }

  Future<void> _completeTask(MaintenanceTask task) async {
    final taskService =
        Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee();
    if (employee != null) {
      await taskService.changeTaskStatus(task.id, 'completed', employee.id);
    }
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.task;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Aucune tâche en attente';
      case 'in_progress':
        return 'Aucune tâche en cours';
      case 'completed':
        return 'Aucune tâche terminée';
      case 'rejected':
        return 'Aucune tâche rejetée';
      default:
        return 'Aucune tâche';
    }
  }
}
