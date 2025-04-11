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

// AJOUT: SingleTickerProviderStateMixin for TabController
class _TaskListState extends State<TaskList> with SingleTickerProviderStateMixin {
  // MODIFICATION: Remove custom tab state, use TabController
  late TabController _tabController;

  // AJOUT: Define status keys matching AppConstants and titles/icons
  final List<String> _statuses = [
    'all', // Special case for all tasks
    'pending',
    'in_progress',
    'completed',
    'rejected'
  ];

  final Map<String, String> _statusTitles = {
    'all': 'Toutes',
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminées',
    'rejected': 'Rejetées'
  };

  final Map<String, IconData> _statusIcons = {
    'all': Icons.list_alt_outlined, // Changed icon slightly
    'pending': Icons.pending_actions_outlined,
    'in_progress': Icons.construction_outlined, // Changed icon
    'completed': Icons.check_circle_outline,
    'rejected': Icons.cancel_outlined
  };

   // AJOUT: Breakpoint for grid layout
   final double tabletBreakpoint = 600.0;


  @override
  void initState() {
    super.initState();
    // Initialize TabController
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    // Dispose TabController
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
       backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes Tâches'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Allow scrolling if tabs don't fit
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statuses.map((status) {
            return Tab(
              icon: Icon(_statusIcons[status]),
              text: _statusTitles[status],
            );
          }).toList(),
        ),
      ),
      // MODIFICATION: Use TabBarView instead of IndexedStack
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          // Call the appropriate list builder based on status
          if (status == 'all') {
            return _buildAllTasksList(taskService, authService);
          } else {
            return _buildTaskList(taskService, authService, status);
          }
        }).toList(),
      ),
    );
  }

   // --- List Building Logic ---

  // Common list builder function (could be further refactored later)
  Widget _buildListLayout({
    required BuildContext context,
    required List<MaintenanceTask> tasks,
    required String statusForEmptyMessage, // Pass status for empty message context
  }) {
     if (tasks.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               _getEmptyIcon(statusForEmptyMessage), // Use helper for icon
               size: 64,
               color: Colors.grey,
             ),
             const SizedBox(height: 16),
             Text(
               _getEmptyMessage(statusForEmptyMessage), // Use helper for text
               style: const TextStyle(
                 fontSize: 18,
                 color: Colors.grey,
               ),
               textAlign: TextAlign.center,
             ),
              if (statusForEmptyMessage == 'all') // Additional context for 'all' tab
                 const Padding(
                   padding: EdgeInsets.only(top: 16.0),
                   child: Text(
                     "Les tâches que l'on vous assignera apparaîtront ici.",
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey,
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ),
           ],
         ),
       );
     }

     // AJOUT: Use LayoutBuilder for responsive list/grid
     return LayoutBuilder(
       builder: (context, constraints) {
         // Narrow screen -> ListView
         if (constraints.maxWidth < tabletBreakpoint) {
           return ListView.builder(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjusted padding
             itemCount: tasks.length,
             itemBuilder: (context, index) {
               final task = tasks[index];
               return _buildTaskCard(context, task);
             },
           );
         }
         // Wide screen -> GridView
         else {
           return GridView.builder(
              padding: const EdgeInsets.all(16), // Grid padding
             gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
               maxCrossAxisExtent: 450, // Max width per card
               childAspectRatio: 1.8,   // <<< ADJUST THIS RATIO L/H >>>
               crossAxisSpacing: 16,
               mainAxisSpacing: 16,
             ),
             itemCount: tasks.length,
             itemBuilder: (context, index) {
               final task = tasks[index];
               return _buildTaskCard(context, task);
             },
           );
         }
       },
     );
   }

  // Builder for "All Tasks" tab
  Widget _buildAllTasksList(
      MaintenanceTaskService taskService, AuthService authService) {
    return FutureBuilder<Employee?>(
      future: authService.getCurrentEmployee(),
      builder: (context, userSnapshot) {
         // --- User Loading/Error Handling (keep similar) ---
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError || userSnapshot.data == null) {
          return Center(child: Text('Erreur chargement utilisateur: ${userSnapshot.error ?? 'Utilisateur non trouvé'}'));
        }
        final employee = userSnapshot.data!;
        // --- End User Handling ---

        return StreamBuilder<List<MaintenanceTask>>(
          stream: taskService.getTasksByEmployee(employee.id),
          builder: (context, snapshot) {
             // --- Task Loading/Error Handling (keep similar) ---
             if (snapshot.hasError) {
               return Center(child: Text('Erreur chargement tâches: ${snapshot.error}'));
             }
             if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) { // Show indicator only if no data yet
                 return const Center(child: CircularProgressIndicator());
             }
             // --- End Task Handling ---

             final tasks = snapshot.data ?? [];
             // Use the common list builder
             return _buildListLayout(context: context, tasks: tasks, statusForEmptyMessage: 'all');
          },
        );
      },
    );
  }

  // Builder for specific status tabs
  Widget _buildTaskList(MaintenanceTaskService taskService,
      AuthService authService, String status) {
    return FutureBuilder<Employee?>(
      future: authService.getCurrentEmployee(),
      builder: (context, userSnapshot) {
         // --- User Loading/Error Handling (keep similar) ---
         if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
         if (userSnapshot.hasError || userSnapshot.data == null) {
          return Center(child: Text('Erreur chargement utilisateur: ${userSnapshot.error ?? 'Utilisateur non trouvé'}'));
        }
        final employee = userSnapshot.data!;
        // --- End User Handling ---

        return StreamBuilder<List<MaintenanceTask>>(
          // Fetch tasks filtered by status and employee
          stream: taskService.getTasksByStatusAndEmployee(status, employee.id),
          builder: (context, snapshot) {
            // --- Task Loading/Error Handling (keep similar) ---
             if (snapshot.hasError) {
               return Center(child: Text('Erreur chargement tâches: ${snapshot.error}'));
             }
             if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                 return const Center(child: CircularProgressIndicator());
             }
            // --- End Task Handling ---

            final tasks = snapshot.data ?? [];
             // Use the common list builder
            return _buildListLayout(context: context, tasks: tasks, statusForEmptyMessage: status);
          },
        );
      },
    );
  }


  // --- Task Card Widget ---

    Widget _buildTaskCard(BuildContext context, MaintenanceTask task) {
    final statusColor = AppConstants.taskStatusColors[task.status] ?? Colors.grey;
    // Format status text (moved here for clarity)
    final statusText = AppConstants.taskStatuses[task.status] ?? task.status.replaceAll('_', ' ').capitalize();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                     flex: 3,
                     child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                   const SizedBox(width: 8),
                   Flexible(
                      flex: 1, // Moins de flex pour le badge
                      child: Container(
                        // ... décoration du badge ...
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(
                             color: statusColor.withOpacity(0.3),
                             width: 1,
                           ),
                         ),
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Échéance: ${_formatDate(task.dueDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildActionButtons(context, task),
            ],
          ),
        ),
      ),
    );
  }
   // Helper to build action buttons based on status
   Widget _buildActionButtons(BuildContext context, MaintenanceTask task) {
     // Use a Wrap widget for better adaptability on very narrow screens
     // Though Row with MainAxisAlignment.spaceEvenly often works well too.
     // Let's try Wrap first.
     List<Widget> buttons = [];

     if (task.status == 'pending') {
       buttons = [
         ElevatedButton.icon(
           onPressed: () => _startTask(task),
           icon: const Icon(Icons.play_arrow_outlined, size: 18), // Outlined
           label: const Text('Accepter'),
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.blueAccent, // Slightly different blue
             foregroundColor: Colors.white,
             textStyle: const TextStyle(fontSize: 13),
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjust padding
           ),
         ),
         OutlinedButton.icon(
           onPressed: () => _rejectTask(task),
           icon: const Icon(Icons.close_outlined, size: 18), // Outlined
           label: const Text('Refuser'),
           style: OutlinedButton.styleFrom(
             foregroundColor: Colors.redAccent, // Slightly different red
             side: const BorderSide(color: Colors.redAccent),
              textStyle: const TextStyle(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           ),
         ),
       ];
     } else if (task.status == 'in_progress') {
       buttons = [
         ElevatedButton.icon(
           onPressed: () => _completeTask(task),
           icon: const Icon(Icons.check_outlined, size: 18), // Outlined
           label: const Text('Terminer'),
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.green,
             foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           ),
         ),
       ];
     }

     if (buttons.isEmpty) {
       return const SizedBox.shrink(); // No actions for this status
     }

     // Use Wrap for buttons
     return Wrap(
       spacing: 12.0, // Horizontal space between buttons
       runSpacing: 8.0, // Vertical space if buttons wrap
       alignment: WrapAlignment.center, // Center buttons if they wrap
       children: buttons,
     );

     /* Alternative using Row (might overflow on very narrow screens)
     if (buttons.isEmpty) {
        return const SizedBox.shrink();
     }
     return Row(
        mainAxisAlignment: buttons.length > 1 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: buttons.length > 1
           ? buttons.map((b) => Flexible(child: b)).toList() // Use Flexible to prevent overflow if buttons are wide
           : buttons,
     );
     */
   }


  // --- Helper Functions ---

  String _formatDate(DateTime? date) { // Make date nullable
     if (date == null) return 'N/A';
    try {
       return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    } catch (e) {
       return 'Date invalide';
    }
  }

  // Action handlers (keep similar, maybe add error handling/feedback)
  Future<void> _startTask(MaintenanceTask task) async {
    // ... (keep existing logic, consider adding try/catch and ScaffoldMessenger) ...
     final taskService = Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee(); // Consider handling error here
    if (employee != null && mounted) { // Add mounted check
        try {
            await taskService.changeTaskStatus(task.id, 'in_progress', employee.id);
             if (mounted) { // Check again after await
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tâche démarrée.'), behavior: SnackBarBehavior.floating),
                 );
             }
        } catch (e) {
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                 );
             }
        }
    }
  }

  Future<void> _rejectTask(MaintenanceTask task) async {
    // ... (keep existing logic, consider adding try/catch and ScaffoldMessenger) ...
     final taskService = Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee();
    if (employee != null && mounted) {
        try {
             await taskService.changeTaskStatus(task.id, 'rejected', employee.id);
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tâche rejetée.'), behavior: SnackBarBehavior.floating),
                 );
             }
        } catch (e) {
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                 );
             }
        }
    }
  }

  Future<void> _completeTask(MaintenanceTask task) async {
    // ... (keep existing logic, consider adding try/catch and ScaffoldMessenger) ...
     final taskService = Provider.of<MaintenanceTaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final employee = await authService.getCurrentEmployee();
    if (employee != null && mounted) {
         try {
             await taskService.changeTaskStatus(task.id, 'completed', employee.id);
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tâche terminée.'), behavior: SnackBarBehavior.floating),
                 );
             }
         } catch (e) {
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                 );
             }
         }
    }
  }

  // Helpers for empty list messages (keep similar)
  IconData _getEmptyIcon(String status) {
    return _statusIcons[status] ?? Icons.task_alt_outlined; // Fallback icon
  }

  String _getEmptyMessage(String status) {
     switch (status) {
      case 'all': return "Vous n'avez aucune tâche assignée"; // Specific message for 'all'
      case 'pending': return 'Aucune tâche en attente';
      case 'in_progress': return 'Aucune tâche en cours';
      case 'completed': return 'Aucune tâche terminée';
      case 'rejected': return 'Aucune tâche rejetée';
      default: return 'Aucune tâche';
    }
  }
}

// Helper extension for capitalizing strings (optional, but nice for status text)
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) {
        return "";
      }
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}