// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/activity_service.dart';
import '../../models/activity.dart';

class ActivityList extends StatefulWidget {
  const ActivityList({Key? key}) : super(key: key);

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter =
      'all'; // 'all', 'equipment', 'employee', 'task', 'report', 'system'
  late TabController _tabController;

  // Liste des activités chargées
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = [
    'all',
    'equipment',
    'employee',
    'task',
    'report',
  ];

  final Map<String, String> _categoryLabels = {
    'all': 'Toutes',
    'equipment': 'Équipements',
    'employee': 'Employés',
    'task': 'Tâches',
    'report': 'Rapports',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _categories[_tabController.index];
          _loadActivities(Provider.of<ActivityService>(context, listen: false));
        });
      }
    });

    // Charger les activités au démarrage
    _loadActivities(Provider.of<ActivityService>(context, listen: false));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Charger les activités au démarrage
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une activité...',
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
                        borderSide:
                            BorderSide(width: 1, color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Rafraîchir',
                  onPressed: () {
                    _loadActivities(
                        Provider.of<ActivityService>(context, listen: false));
                  },
                ),
              ],
            ),
          ),

          // Onglets de catégories
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
              isScrollable: false,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 1,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tabs: _categories
                  .map((category) => Tab(text: _categoryLabels[category]))
                  .toList(),
            ),
          ),

          // Liste des activités
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Erreur: $_errorMessage'),
                          ],
                        ),
                      )
                    : _activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 48, color: Colors.blue),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucune activité trouvée dans la base de données',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Essayez de créer un équipement ou une tâche pour générer des activités',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Rafraîchir'),
                                  onPressed: () {
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          )
                        : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Filtrer par recherche
    final filteredActivities = _searchQuery.isEmpty
        ? _activities
        : _activities
            .where((activity) =>
                activity.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.activityType
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.id
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.performedBy
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (activity.targetName != null &&
                    activity.targetName!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase())))
            .toList();

    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune activité trouvée'
                  : 'Aucune activité ne correspond à "$_searchQuery"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Grouper les activités par date
    final Map<String, List<Activity>> groupedActivities = {};
    for (var activity in filteredActivities) {
      final dateKey = DateFormat('dd/MM/yyyy').format(activity.timestamp);
      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }
      groupedActivities[dateKey]!.add(activity);
    }

    // Trier les dates (plus récentes en premier)
    final sortedDates = groupedActivities.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a);
        final dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final activitiesForDate = groupedActivities[dateKey]!;

        // Trier les activités par heure (plus récentes en premier)
        activitiesForDate.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de date
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateHeader(dateKey),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Activités pour cette date
            ...activitiesForDate
                .map((activity) => _buildActivityCard(activity)),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(Activity activity) {
    // Vérifier si l'activité est valide
    if (activity.id.isEmpty) {
      print('Erreur: activity id est vide');
      return const SizedBox.shrink(); // Ne rien afficher
    }

    // Formater l'heure
    String formattedTime;
    try {
      formattedTime = DateFormat('HH:mm').format(activity.timestamp);
    } catch (e) {
      print('Erreur lors du formatage de l\'heure: $e');
      formattedTime = '--:--';
    }

    // Gérer les erreurs potentielles avec activityType
    ActivityType activityType;
    try {
      activityType = stringToActivityType(activity.activityType);
    } catch (e) {
      print('Erreur lors de la conversion du type d\'activité: $e');
      activityType = ActivityType.systemAction;
    }

    // Vérifier si la catégorie est valide
    String category;
    try {
      category = activity.category;
      if (category.isEmpty) {
        category = 'system'; // Catégorie par défaut
      }
    } catch (e) {
      print('Erreur lors de la récupération de la catégorie: $e');
      category = 'system';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec type d'activité
          Container(
            decoration: BoxDecoration(
              color: _getActivityTypeColor(category).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getActivityTypeColor(category),
                      radius: 12,
                      child: Icon(
                        _getActivityTypeIcon(category),
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activityType.displayName,
                      style: TextStyle(
                        color: _getActivityTypeColor(category),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Contenu de l'activité
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Par: ${activity.performedBy}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Afficher les détails supplémentaires si disponibles
                if (activity.details != null && activity.details!.isNotEmpty)
                  _buildDetailsSection(activity.details!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> details) {
    if (details.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher
    }

    final List<Widget> detailWidgets = [];

    // Traiter les détails en fonction de leur type
    details.forEach((key, value) {
      try {
        if (key == 'oldState' && details.containsKey('newState')) {
          final oldState = details['oldState']?.toString() ?? '';
          final newState = details['newState']?.toString() ?? '';

          detailWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        children: [
                          const TextSpan(text: 'Changement: '),
                          TextSpan(
                            text: oldState,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                            ),
                          ),
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: newState,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (key == 'oldStatus' && details.containsKey('newStatus')) {
          final oldStatus = details['oldStatus']?.toString() ?? '';
          final newStatus = details['newStatus']?.toString() ?? '';

          detailWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        children: [
                          const TextSpan(text: 'Statut: '),
                          TextSpan(
                            text: oldStatus,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                            ),
                          ),
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: newStatus,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (key == 'oldAssignee' && details.containsKey('newAssignee')) {
          final oldAssignee = details['oldAssignee']?.toString() ?? '';
          final newAssignee = details['newAssignee']?.toString() ?? '';

          detailWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        children: [
                          const TextSpan(text: 'Assigné: '),
                          TextSpan(
                            text: oldAssignee,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                            ),
                          ),
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: newAssignee,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (key == 'category' || key == 'state' || key == 'status') {
          final valueStr = value?.toString() ?? '';

          detailWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Icon(
                    key == 'category'
                        ? Icons.category
                        : (key == 'state'
                            ? Icons.info_outline
                            : Icons.settings),
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$key: $valueStr',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (key == 'dueDate') {
          try {
            final dateStr = value?.toString() ?? '';
            if (dateStr.isNotEmpty) {
              final date = DateTime.parse(dateStr);
              final formattedDate = DateFormat('dd/MM/yyyy').format(date);
              detailWidgets.add(
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Échéance: $formattedDate',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          } catch (e) {
            print('Erreur lors du formatage de la date: $e');
            // Ignorer si la date n'est pas valide
          }
        } else if (key == 'error') {
          // Afficher les erreurs de désérialisation
          detailWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Erreur: $value',
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        print('Erreur lors du traitement des détails ($key): $e');
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detailWidgets,
    );
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final date = DateFormat('dd/MM/yyyy').parse(dateKey);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      return dateKey;
    }
  }

  Color _getActivityTypeColor(String category) {
    switch (category) {
      case 'equipment':
        return Colors.blue;
      case 'employee':
        return Colors.green;
      case 'task':
        return Colors.orange;
      case 'report':
        return Colors.purple;
      case 'system':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(String category) {
    switch (category) {
      case 'equipment':
        return Icons.computer;
      case 'employee':
        return Icons.person;
      case 'task':
        return Icons.assignment;
      case 'report':
        return Icons.description;
      case 'system':
        return Icons.settings;
      default:
        return Icons.history;
    }
  }

  // Méthode pour charger les activités
  Future<void> _loadActivities(ActivityService activityService) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activities =
          await activityService.getActivitiesByCategoryFuture(_selectedFilter);

      if (!mounted) return; // Vérifiez si le widget est monté

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Vérifiez si le widget est monté

      setState(() {
        _errorMessage = 'Erreur lors du chargement des activités: $e';
        _isLoading = false;
      });
    }
  }
}
