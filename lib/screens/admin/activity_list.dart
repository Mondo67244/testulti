// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _selectedFilter = 'all';
  late TabController _tabController;

  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = [
    'all',
    'equipment',
    'employee',
    'task',
    'system',
  ];

  final Map<String, String> _categoryLabels = {
    'all': 'Toutes',
    'equipment': 'Équipements',
    'employee': 'Employés',
    'task': 'Tâches',
    'system': 'Rapports',
  };

  // Breakpoint et largeur max pour le contenu principal
  final double wideLayoutBreakpoint = 700.0;
  final double maxContentWidth = 800.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) { 
        setState(() {
          _selectedFilter = _categories[_tabController.index];
          _loadActivities(Provider.of<ActivityService>(context, listen: false));
        });
      }
    });

    // Charger les activités au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) { // AJOUT: mounted check
           _loadActivities(Provider.of<ActivityService>(context, listen: false));
       }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= wideLayoutBreakpoint;
              // Ajouter du padding horizontal sur les écrans larges
              final double horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 12.0;

              return Padding(
                // Appliquer le padding calculé au container du header
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8), // Padding interne ajusté
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
                                           if (mounted) { // AJOUT: mounted check
                                               setState(() {
                                                _searchController.clear();
                                                _searchQuery = '';
                                                // Recharger potentiellement les activités ou laisser le filtre local faire effet
                                               });
                                           }
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(width: 1, color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                 if (mounted) { // AJOUT: mounted check
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                 }
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
                              _loadActivities(Provider.of<ActivityService>(context, listen: false));
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
                        // MODIFICATION: Rendre les onglets scrollables si l'écran est TRES étroit, sinon fixe
                        isScrollable: constraints.maxWidth < 380, // Ajustez ce seuil si nécessaire
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorWeight: 1,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontSize: 10),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tabs: _categories.map((category) => Tab(text: _categoryLabels[category])).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),


          // Liste des activités
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        // ... (Error message unchanged) ...
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
                                     if (mounted) { // AJOUT: mounted check
                                         setState(() {}); // Force rebuild, which might trigger load if needed elsewhere
                                         _loadActivities(Provider.of<ActivityService>(context, listen: false)); // Explicit reload
                                     }
                                  },
                                ),
                              ],
                            ),
                          )
                        : _buildActivityList(), // Passer au build de la liste
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Filtrer par recherche (code inchangé)
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
                // AJOUT: Vérifier nullité pour targetName
                (activity.targetName != null &&
                    activity.targetName!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase())) ||
                activity.performedBy
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.id // L'ID est souvent moins utile pour la recherche utilisateur mais gardé
                   .toLowerCase()
                   .contains(_searchQuery.toLowerCase()) )
            .toList();


    if (filteredActivities.isEmpty) {
      return Center(
        // ... (Search empty state unchanged) ...
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey), // Icône différente
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Aucune activité à afficher' // Message légèrement différent si pas de recherche
                      : 'Aucune activité ne correspond à "$_searchQuery"',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
      );
    }

    // Grouper les activités par date (code inchangé)
    final Map<String, List<Activity>> groupedActivities = {};
    for (var activity in filteredActivities) {
      // AJOUT: Vérification de la validité de timestamp
       if (activity.timestamp == null) {
           print("Activité avec timestamp null ignorée: ${activity.id}");
           continue; // Skip this activity
       }
      final dateKey = DateFormat('dd/MM/yyyy').format(activity.timestamp!); // Utiliser ! après vérification
      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }
      groupedActivities[dateKey]!.add(activity);
    }

    // Trier les dates (code inchangé)
    final sortedDates = groupedActivities.keys.toList()
      ..sort((a, b) {
         try {
            final dateA = DateFormat('dd/MM/yyyy').parse(a);
            final dateB = DateFormat('dd/MM/yyyy').parse(b);
            return dateB.compareTo(dateA); // Plus récent en premier
         } catch (e) {
            print("Erreur de parsing de date pendant le tri: $e");
            return 0; // Garder l'ordre si erreur
         }
      });

    // MODIFICATION: Utiliser LayoutBuilder pour centrer et contraindre la ListView
    return LayoutBuilder(
      builder: (context, constraints) {
         final bool isWide = constraints.maxWidth >= wideLayoutBreakpoint;
         // Calculer le padding horizontal pour centrer le contenu limité en largeur
         final double horizontalPadding = isWide ? (constraints.maxWidth - maxContentWidth) / 2 : 12.0;

        return ListView.builder(
          // Appliquer le padding calculé ici
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final dateKey = sortedDates[dateIndex];
            final activitiesForDate = groupedActivities[dateKey]!;

            // Trier les activités par heure (code inchangé, ajouté ! après vérif timestamp)
             activitiesForDate.sort((a, b) {
                if (a.timestamp == null || b.timestamp == null) return 0;
                return b.timestamp!.compareTo(a.timestamp!);
             });


            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de date (code inchangé)
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
                ...activitiesForDate.map((activity) => _buildActivityCard(activity)),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildActivityCard(Activity activity) {
    if (activity.id.isEmpty) {
      print('Erreur: activity id est vide');
      return const SizedBox.shrink();
    }

    String formattedTime = '--:--';
    try {
      if (activity.timestamp != null) {
        formattedTime = DateFormat('HH:mm').format(activity.timestamp!);
      }
    } catch (e) {
      print('Erreur de formatage de l\'heure: $e');
    }

    ActivityType activityType = ActivityType.systemAction;
    try {
      activityType = stringToActivityType(activity.activityType);
    } catch (e) {
      print('Erreur de conversion du type: $e');
    }

    String category = activity.category.isNotEmpty ? activity.category : 'system';
    Color categoryColor = _getActivityTypeColor(category);
    IconData categoryIcon = _getCategoryIcon(category, activity.activityType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: categoryColor,
                        radius: 12,
                        child: Icon(categoryIcon, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activityType.displayName,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                    if (activity.targetName != null || activity.performedBy.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (activity.targetName != null)
                              _buildInfoChip(
                                Icons.label,
                                'Cible: ${activity.targetName}',
                                Colors.blue.shade100,
                              ),
                            if (activity.performedBy.isNotEmpty)
                              _buildInfoChip(
                                Icons.person,
                                'Par: ${activity.performedBy}',
                                Colors.green.shade100,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

  Widget _buildInfoChip(IconData icon, String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade800),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateKey);
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      if (DateFormat('dd/MM/yyyy').format(now) == dateKey) {
        return 'Aujourd\'hui';
      } else if (DateFormat('dd/MM/yyyy').format(yesterday) == dateKey) {
        return 'Hier';
      } else {
        return dateKey;
      }
    } catch (e) {
      print('Erreur de formatage de date: $e');
      return dateKey;
    }
                    
  }


  Widget _buildDetailsSection(Map<String, dynamic> details) {
     
      if (details.isEmpty) {
            return const SizedBox.shrink(); // Ne rien afficher
        }

        final List<Widget> detailWidgets = [];

        // Traiter les détails en fonction de leur type
        details.forEach((key, value) {
        try {
            // Simplification: Afficher clé/valeur générique pour les non-traités spécifiquement
            String displayKey = key;
            String displayValue = value?.toString() ?? 'N/A';
            IconData iconData = Icons.info_outline;
            bool handled = false;

            if (key == 'oldState' && details.containsKey('newState')) {
            final oldState = details['oldState']?.toString() ?? '';
            final newState = details['newState']?.toString() ?? '';
            iconData = Icons.compare_arrows;
            detailWidgets.add(_buildChangeDetailRow(iconData, "État", oldState, newState));
            handled = true;
            } else if (key == 'oldStatus' && details.containsKey('newStatus')) {
            final oldStatus = details['oldStatus']?.toString() ?? '';
            final newStatus = details['newStatus']?.toString() ?? '';
            iconData = Icons.compare_arrows;
            detailWidgets.add(_buildChangeDetailRow(iconData, "Statut", oldStatus, newStatus));
            handled = true;
            } else if (key == 'oldAssignee' && details.containsKey('newAssignee')) {
            final oldAssignee = details['oldAssignee']?.toString() ?? 'Personne';
            final newAssignee = details['newAssignee']?.toString() ?? 'Personne';
             iconData = Icons.compare_arrows;
             detailWidgets.add(_buildChangeDetailRow(iconData, "Assigné", oldAssignee, newAssignee));
             handled = true;
            } else if (key == 'dueDate') {
                try {
                    final dateStr = value?.toString() ?? '';
                    if (dateStr.isNotEmpty) {
                        // Tenter de parser avec plusieurs formats si nécessaire ou depuis Timestamp
                        DateTime? date;
                        if (value is Timestamp) {
                           date = value.toDate();
                        } else {
                           date = DateTime.tryParse(dateStr);
                        }

                        if (date != null) {
                           final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                           displayKey = 'Échéance';
                           displayValue = formattedDate;
                           iconData = Icons.calendar_today;
                           detailWidgets.add(_buildSimpleDetailRow(iconData, displayKey, displayValue));
                           handled = true;
                        } else {
                           print("Impossible de parser la date: $dateStr");
                        }
                    }
                } catch (e) {
                    print('Erreur lors du formatage de la date ($key): $e');
                }
            } else if (key == 'category') {
               displayKey = "Catégorie";
               iconData = Icons.category;
            } else if (key == 'state') {
               displayKey = "État";
               iconData = Icons.info_outline;
            } else if (key == 'status') {
               displayKey = "Statut";
               iconData = Icons.settings;
            } else if (key == 'error') {
               displayKey = "Erreur système";
               iconData = Icons.error_outline;
               displayValue = value.toString(); // Assurer que l'erreur est affichée
               detailWidgets.add(
                Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                        children: [
                        Icon(iconData, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(
                            '$displayKey: $displayValue',
                            style: const TextStyle(color: Colors.red, fontSize: 11),
                            ),
                        ),
                        ],
                    ),
                    )
               );
               handled = true; 
            }

            // Ajouter la ligne de détail simple si non géré spécifiquement (et pas partie d'une paire)
            if (!handled && key != 'newState' && key != 'newStatus' && key != 'newAssignee') {
                 detailWidgets.add(_buildSimpleDetailRow(iconData, displayKey, displayValue));
            }
        } catch (e) {
            print('Erreur lors du traitement des détails ($key): $e');
             detailWidgets.add(_buildSimpleDetailRow(Icons.warning_amber, "Détail (erreur)", key, color: Colors.orange));
        }
        });

        // Ajouter un séparateur si des détails sont présents
        if(detailWidgets.isNotEmpty){
           detailWidgets.insert(0, Divider(height: 10, thickness: 0.5, color: Colors.grey.shade300));
        }

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detailWidgets,
        );
  }

   // détails simples
  Widget _buildSimpleDetailRow(IconData icon, String key, String value, {Color color = Colors.black54}) {
    return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                    '$key: ',
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500
                    ),
                ),
                // MODIFICATION: Remplacer Expanded par Flexible
                Flexible(
                    child: Text(
                    value,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                    ),
                    // softWrap: true, // Text wrappe par défaut, mais on peut être explicite
                    ),
                ),
            ],
        ),
    );
}

   // AJOUT: Helper pour les détails de changement (avant -> après)
   Widget _buildChangeDetailRow(IconData icon, String label, String oldValue, String newValue) {
    return Padding(
         padding: const EdgeInsets.only(top: 4.0),
         child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                    '$label: ',
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500
                    ),
                ),
                // MODIFICATION: Remplacer Expanded par Flexible
                Flexible(
                    child: RichText(
                    text: TextSpan(
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                        children: [
                        const TextSpan( /* ... oldValue ... */ ),
                         if (oldValue.isNotEmpty || newValue.isNotEmpty)
                             const TextSpan(text: ' → '),
                        const TextSpan( /* ... newValue ... */ ),
                        ],
                    ),
                    // softWrap: true, // RichText wrappe aussi par défaut
                    ),
                ),
              ],
         ),
     );
}




  Color _getActivityTypeColor(String category) {
    switch (category) {
      case 'equipment':
        return Colors.blue;
      case 'employee':
        return Colors.green;
      case 'task':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category, String activityType) {
    // Icônes spécifiques par type d'activité
    switch (activityType) {
      case 'equipmentCreated':
        return Icons.add_circle;
      case 'equipmentUpdated':
        return Icons.edit;
      case 'equipmentDeleted':
        return Icons.delete;
      case 'equipmentStateChanged':
        return Icons.sync;
      case 'equipmentStatusChanged':
        return Icons.update;
      case 'employeeCreated':
        return Icons.person_add;
      case 'employeeUpdated':
        return Icons.manage_accounts;
      case 'employeeDeleted':
        return Icons.person_remove;
      case 'employeeLogin':
        return Icons.login;
      case 'employeeLogout':
        return Icons.logout;
      case 'taskCreated':
        return Icons.add_task;
      case 'taskUpdated':
        return Icons.edit_note;
      case 'taskDeleted':
        return Icons.delete_sweep;
      case 'taskAssigned':
        return Icons.assignment_ind;
      case 'taskStatusChanged':
        return Icons.fact_check;
      case 'reportSubmitted':
        return Icons.post_add;
      case 'reportUpdated':
        return Icons.rate_review;
      case 'reportStatusChanged':
        return Icons.pending_actions;
      default:
        // Icônes par défaut par catégorie
        switch (category) {
          case 'equipment':
            return Icons.computer;
          case 'employee':
            return Icons.person;
          case 'task':
            return Icons.assignment;
          case 'system':
            return Icons.settings;
          default:
            return Icons.info;
        }
    }
  }

  Future<void> _loadActivities(ActivityService activityService) async {
     if (!mounted) return; 

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le filtre sélectionné
      final activities = await activityService.getActivitiesByCategoryFuture(_selectedFilter);

      if (!mounted) return;

      setState(() {
        // Trier immédiatement après le chargement pour assurer l'ordre initial
         _activities = activities..sort((a, b) {
             if (a.timestamp == null || b.timestamp == null) return 0;
             return b.timestamp!.compareTo(a.timestamp!); // Plus récent en premier
         });
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur _loadActivities: $e"); // Log l'erreur
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erreur de chargement.'; // Message plus générique pour l'utilisateur
        _isLoading = false;
        _activities = []; // Vider la liste en cas d'erreur
      });
    }
  }
}


// AJOUT: S'assurer que la conversion stringToActivityType et ActivityType.displayName existent
// (Ce code doit exister quelque part dans votre projet, probablement dans activity.dart)
/*
enum ActivityType {
  equipmentCreated('Création équipement'),
  equipmentUpdated('Mise à jour équipement'),
  equipmentDeleted('Suppression équipement'),
  equipmentStateChanged('Changement état équipement'),
  equipmentStatusChanged('Changement statut équipement'),
  taskCreated('Création tâche'),
  taskUpdated('Mise à jour tâche'),
  taskDeleted('Suppression tâche'),
  taskAssigned('Assignation tâche'),
  taskStatusChanged('Changement statut tâche'),
  employeeCreated('Création employé'),
  employeeUpdated('Mise à jour employé'),
  employeeDeleted('Suppression employé'),
  reportGenerated('Génération rapport'), // Exemple
  userLogin('Connexion utilisateur'),
  userLogout('Déconnexion utilisateur'),
  systemAction('Action système'); // Générique

  final String displayName;
  const ActivityType(this.displayName);
}

ActivityType stringToActivityType(String typeString) {
  return ActivityType.values.firstWhere(
    (e) => e.name == typeString, // Utilise .name pour la comparaison avec la chaîne stockée
    orElse: () {
        print("Type d'activité inconnu: '$typeString', fallback sur systemAction");
        return ActivityType.systemAction; // Fallback
    }
  );
}
*/