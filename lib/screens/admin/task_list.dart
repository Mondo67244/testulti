import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/maintenance_task_service.dart';
import '../../models/maintenance_task.dart';
import '../../constants/app_constants.dart';

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Constantes pour la mise en page responsive
  final double wideLayoutBreakpoint = 700.0;
  final double maxContentWidth = 800.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.taskStatuses.length + 1, // +1 pour "Tous"
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskService =
        Provider.of<MaintenanceTaskService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= wideLayoutBreakpoint;
            final double horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 12.0;
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
        children: [
          // MODIFICATION: Utiliser LayoutBuilder pour le padding/contrainte du header
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= wideLayoutBreakpoint;
              final double horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 12.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                      child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une tâche...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

                    // Onglets de filtrage par statut
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
              controller: _tabController,
              isScrollable: constraints.maxWidth < 380,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 2,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tabs: [
                const Tab(text: 'Toutes'),
                ...AppConstants.taskStatuses.values
                    .map((status) => Tab(text: status))
                    .toList(),
              ],
            ),
          ),

                  ],
                ),
              );
            },
          ),

          // Liste des tâches
          Expanded(
            child: StreamBuilder<List<MaintenanceTask>>(
              stream: taskService.getTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTasks = snapshot.data!;

                // Filtrer par statut
                final List<MaintenanceTask> statusFilteredTasks;
                if (_tabController.index == 0) {
                  // "Toutes" les tâches
                  statusFilteredTasks = allTasks;
                } else {
                  // Filtrer par le statut sélectionné
                  final selectedStatus = AppConstants.taskStatuses.keys
                      .elementAt(_tabController.index - 1);
                  statusFilteredTasks = allTasks
                      .where((task) => task.status == selectedStatus)
                      .toList();
                }

                // Filtrer par recherche
                final filteredTasks = _searchQuery.isEmpty
                    ? statusFilteredTasks
                    : statusFilteredTasks
                        .where((task) =>
                            task.title
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            task.description
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            task.equipmentId
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            task.assignedTo
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_late_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucune tâche trouvée'
                              : 'Aucune tâche ne correspond à "$_searchQuery"',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // MODIFICATION: Utiliser LayoutBuilder pour centrer et contraindre la ListView
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth >= wideLayoutBreakpoint;
                    final double horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 12.0;

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            );
  },),
      )],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(MaintenanceTask task) {
    final statusColor =
        AppConstants.taskStatusColors[task.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      fontSize: 15,
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
                    borderRadius: BorderRadius.circular(8),
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
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer la tâche'),
                        content: const Text(
                            'Êtes-vous sûr de vouloir supprimer cette tâche ?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 213, 47, 47),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Supprimer',
                                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final taskService =
                          Provider.of<MaintenanceTaskService>(context,
                              listen: false);
                      await taskService.deleteTask(task.id, 'Admin');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Échéance: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Assigné à: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  task.assignedTo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 213, 47, 47),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
