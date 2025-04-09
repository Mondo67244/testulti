import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/equipment_service.dart';
import '../../models/equipment.dart';
import '../../constants/app_constants.dart';
import '../../screens/admin/equipment_form.dart';
import '../../screens/admin/equipment_state_dialog.dart';
import '../../services/employee_service.dart';
import '../../services/auth_service.dart';
import '../../services/maintenance_task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/employee.dart';
import '../../models/maintenance_task.dart';

class EquipmentList extends StatefulWidget {
  const EquipmentList({Key? key}) : super(key: key);

  @override
  State<EquipmentList> createState() => _EquipmentListState();
}

class _EquipmentListState extends State<EquipmentList>
    with SingleTickerProviderStateMixin {
  String _currentStateFilter = 'all'; // 'all', 'functional', 'defective'
  late TabController _tabController;

  // AJOUT: Définir un breakpoint pour le changement de layout
  final double tabletBreakpoint = 600.0;

  @override
  void initState() {
    super.initState();
    // Initialiser le TabController avec le nombre de catégories
    _tabController = TabController(
        length: AppConstants.equipmentCategories.length + 1, // +1 pour "Toutes"
        vsync: this);

    // Écouter les changements d'onglet pour mettre à jour l'état
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final equipmentService =
          Provider.of<EquipmentService>(context, listen: false);
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 240, 232, 255),
        body: Column(
          children: [
            // Barre de catégories avec TabBar
            Container(
              // ... (code de la TabBar inchangé) ...
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
                isScrollable: true,
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
                  const Tab(text: 'Tout'),
                  ...AppConstants.equipmentCategories
                      .map((category) => Tab(text: category))
                      .toList(),
                ],
              ),
            ),

            // Barre de filtres d'état
            Padding(
              // ... (code des filtres inchangé, pourrait utiliser Wrap si besoin sur très petit écran) ...
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                // Pourrait être remplacé par Wrap(alignment: WrapAlignment.center, spacing: 8) si nécessaire
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterButton('all', 'Tous'),
                  const SizedBox(width: 8),
                  _buildFilterButton('functional', 'Bon état'),
                  const SizedBox(width: 8),
                  _buildFilterButton('defective', 'En panne'),
                ],
              ),
            ),

            // Liste des équipements (MODIFICATION: Utilisation de LayoutBuilder)
            Expanded(
              child: StreamBuilder<List<Equipment>>(
                stream: equipmentService.getEquipments(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // ... (gestion de l'erreur inchangée) ...
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

                  final allEquipments = snapshot.data!;
                  final filteredEquipments = _filterEquipments(allEquipments);

                  if (filteredEquipments.isEmpty) {
                    // ... (gestion de la liste vide inchangée) ...
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun équipement ${_getFilterText().toLowerCase()} trouvé',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // AJOUT: Utilisation de LayoutBuilder pour choisir entre ListView et GridView
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Si la largeur disponible est inférieure au breakpoint, afficher ListView
                      if (constraints.maxWidth < tabletBreakpoint) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: filteredEquipments.length,
                          itemBuilder: (context, index) {
                            final equipment = filteredEquipments[index];
                            // La carte reste la même
                            return _buildEquipmentCard(equipment);
                          },
                        );
                      }
                      // Sinon (écran large), afficher GridView
                      else {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical:
                                  12), // Un peu plus de padding pour la grille
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                450, // Largeur max souhaitée pour chaque carte
                            childAspectRatio:
                                1.6, // Ratio Largeur/Hauteur (à ajuster selon le contenu)
                            crossAxisSpacing:
                                12, // Espace horizontal entre les cartes
                            mainAxisSpacing:
                                12, // Espace vertical entre les cartes
                          ),
                          itemCount: filteredEquipments.length,
                          itemBuilder: (context, index) {
                            final equipment = filteredEquipments[index];
                            // La carte reste la même
                            return _buildEquipmentCard(equipment);
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          // ... (code du FAB et des dialogs inchangé) ...
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Ajouter un équipement'),
                  content: const Text('Choisissez le mode d\'ajout'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Ferme le dialogue
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EquipmentForm()),
                        );
                      },
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Ajout manuel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Ferme
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String selectedType = 'Bureau'; // Type par défaut
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text(
                                      'Choisir le type de fournisseur'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButton<String>(
                                        value: selectedType,
                                        items: [
                                          'Bureau',
                                          'Réseau',
                                          'Échange',
                                          'Sécurité'
                                        ].map((String type) {
                                          return DropdownMenuItem<String>(
                                            value: type,
                                            child: Text(type),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              selectedType = newValue;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Afficher la liste des fournisseurs du type sélectionné
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                  'Fournisseurs - $selectedType'),
                                              content: SizedBox(
                                                width: double.maxFinite,
                                                child: StreamBuilder<
                                                    QuerySnapshot>(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .where('role',
                                                          isEqualTo:
                                                              'Fournisseur')
                                                      .where('category',
                                                          isEqualTo:
                                                              selectedType)
                                                      .snapshots(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }
                                                    if (snapshot.hasError) {
                                                      return const Text(
                                                          'Erreur de chargement');
                                                    }
                                                    final fournisseurs =
                                                        snapshot.data?.docs ??
                                                            [];
                                                    if (fournisseurs.isEmpty) {
                                                      return const Text(
                                                          'Aucun fournisseur trouvé');
                                                    }
                                                    return ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          fournisseurs.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final fournisseur =
                                                            fournisseurs[index]
                                                                    .data()
                                                                as Map<String,
                                                                    dynamic>;
                                                        return ListTile(
                                                          title: Text(
                                                              fournisseur[
                                                                      'name'] ??
                                                                  'Sans nom'),
                                                          subtitle: Text(
                                                              fournisseur[
                                                                      'email'] ??
                                                                  ''),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                            // Afficher les équipements du stock du fournisseur
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                      'Stock - ${fournisseur['name']}'),
                                                                  content:
                                                                      SizedBox(
                                                                    width: double
                                                                        .maxFinite,
                                                                    height: 400,
                                                                    child: StreamBuilder<
                                                                        QuerySnapshot>(
                                                                      stream: FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              'stock')
                                                                          .where(
                                                                              'supplierId',
                                                                              isEqualTo: fournisseur['uid'])
                                                                          .snapshots(),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        if (snapshot.connectionState ==
                                                                            ConnectionState.waiting) {
                                                                          return const Center(
                                                                              child: CircularProgressIndicator());
                                                                        }
                                                                        if (snapshot
                                                                            .hasError) {
                                                                          return const Text(
                                                                              'Erreur de chargement du stock');
                                                                        }
                                                                        final equipments =
                                                                            snapshot.data?.docs ??
                                                                                [];
                                                                        if (equipments
                                                                            .isEmpty) {
                                                                          return const Center(
                                                                            child:
                                                                                Text('Aucun équipement en stock'),
                                                                          );
                                                                        }
                                                                        return ListView
                                                                            .builder(
                                                                          itemCount:
                                                                              equipments.length,
                                                                          itemBuilder:
                                                                              (context, index) {
                                                                            final equipment =
                                                                                equipments[index].data() as Map<String, dynamic>;
                                                                            final equipmentId =
                                                                                equipments[index].id; // Get document ID
                                                                            return Card(
                                                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                                                              child: ListTile(
                                                                                title: Text(equipment['name'] ?? 'Sans nom'),
                                                                                subtitle: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text('Type: ${equipment['type'] ?? 'Non spécifié'}'),
                                                                                    Text('Modèle: ${equipment['model'] ?? 'Non spécifié'}'),
                                                                                    Text('N° Série: ${equipment['serialNumber'] ?? 'Non spécifié'}'),
                                                                                  ],
                                                                                ),
                                                                                onTap: () async {
                                                                                  // Copier les données de l'équipement
                                                                                  final equipmentData = equipment;
                                                                                  final stockId = equipmentId; // Use the fetched ID

                                                                                  // Préparer les données pour le formulaire
                                                                                  final formData = {
                                                                                    'name': equipment['name'],
                                                                                    'description': equipment['description'],
                                                                                    'serialNumber': equipment['serialNumber'],
                                                                                    'type': equipment['type'],
                                                                                    'manufacturer': equipment['manufacturer'],
                                                                                    'model': equipment['model'],
                                                                                    'category': equipment['category'] ?? selectedType,
                                                                                    'state': 'Bon état',
                                                                                    'supplier': fournisseur['name'],
                                                                                    'department': fournisseur['department'],
                                                                                    'stockId': stockId, // Ajouter l'ID du stock pour référence
                                                                                    'equipmentData': equipmentData // Ajouter les données complètes
                                                                                  };

                                                                                  Navigator.pop(context); // Fermer la boîte de dialogue du stock

                                                                                  // Ouvrir le formulaire avec les données préremplies
                                                                                  final result = await Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                      builder: (context) => EquipmentForm(
                                                                                        initialData: formData,
                                                                                        isFromSupplierStock: true,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                      child: const Text(
                                                                          'Fermer'),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Fermer'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child:
                                          const Text('Voir les fournisseurs'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.inventory, size: 20),
                      label: const Text('Via fournisseur'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.add, size: 22),
          tooltip: 'Ajouter un équipement',
          elevation: 2,
          mini: false,
        ),
      );
    } catch (e) {
      // ... (gestion de l'erreur inchangée) ...
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de configuration: $e'),
          ],
        ),
      );
    }
  }

  // --- Fonctions Helper --- (Inchangées)

  Widget _buildFilterButton(String filter, String label) {
    // ... (code inchangé) ...
    final isSelected = _currentStateFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _currentStateFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<Equipment> _filterEquipments(List<Equipment> equipments) {
    // ... (code inchangé) ...
    // Filtrer d'abord par catégorie
    List<Equipment> categoryFiltered;

    if (_tabController.index == 0) {
      // "Toutes" les catégories
      categoryFiltered = equipments;
    } else {
      // Catégorie spécifique
      String selectedCategory =
          AppConstants.equipmentCategories[_tabController.index - 1];
      categoryFiltered =
          equipments.where((e) => e.category == selectedCategory).toList();
    }

    // Ensuite filtrer par état
    switch (_currentStateFilter) {
      case 'functional':
        return categoryFiltered.where((e) => e.state == 'Bon état').toList();
      case 'defective':
        return categoryFiltered.where((e) => e.state == 'En panne').toList();
      case 'all':
      default:
        return categoryFiltered;
    }
  }

  String _getFilterText() {
    // ... (code inchangé) ...
    String categoryText = '';
    if (_tabController.index > 0) {
      categoryText =
          'de catégorie ${AppConstants.equipmentCategories[_tabController.index - 1]} ';
    }

    String stateText = '';
    switch (_currentStateFilter) {
      case 'functional':
        stateText = 'en bon état';
        break;
      case 'defective':
        stateText = 'en panne';
        break;
      default:
        break;
    }

    return '$categoryText$stateText';
  }

  Future<void> _confirmDelete(BuildContext context, Equipment equipment,
      EquipmentService service) async {
    // ... (code inchangé) ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'équipement "${equipment.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.deleteEquipment(equipment.id, 'Admin');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Équipement "${equipment.name}" supprimé'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showStateChangeDialog(
      BuildContext context, Equipment equipment, EquipmentService service) {
    // ... (code inchangé) ...
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EquipmentStateDialog(
          equipment: equipment,
          service: service,
        );
      },
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    // La structure interne de la carte est laissée telle quelle pour le moment.
    // Elle semble déjà utiliser Column/Row/Expanded de manière assez flexible.
    // Si des problèmes spécifiques apparaissent (texte qui déborde, etc.) sur
    // certaines tailles, on pourra ajuster ici (ex: utiliser Wrap pour les badges).
    // ... (code de _buildEquipmentCard inchangé) ...
    final stateColor = _getStateColor(equipment.state);
    final statusColor = _getStatusColor(equipment.status);

    return Card(
      // MODIFICATION: Suppression de la marge horizontale fixe pour laisser la grille gérer l'espacement
      margin: const EdgeInsets.symmetric(
          vertical: 4), // Garde seulement la marge verticale
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et bouton de paramètres
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // MODIFICATION: Utiliser Flexible ou Expanded pour le titre pour éviter l'overflow
                Flexible(
                  // ou Expanded si vous voulez qu'il prenne toute la place dispo
                  child: Text(
                    equipment.type + ' ' + equipment.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines:
                        1, // Garder une seule ligne pour le titre dans la carte
                    overflow: TextOverflow.ellipsis, // Tronquer si trop long
                  ),
                ),
                // Bouton de paramètres
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: Colors.grey.shade600),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    _handleMenuAction(value, equipment);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 18),
                          SizedBox(width: 8),
                          Text('Assigner', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'change_state',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 18),
                          SizedBox(width: 8),
                          Text('Changer l\'état',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Description
            if (equipment.description.isNotEmpty) ...[
              Text(
                equipment.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines:
                    2, // Limiter la description à 2 lignes pour la cohérence de la carte
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // Informations et badges d'état/statut
            // La Row existante avec Expanded devrait bien s'adapter,
            // mais on pourrait utiliser Wrap si les badges deviennent un problème
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne d'informations principales
                Expanded(
                  flex:
                      3, // Garder le flex pour donner plus de place aux détails
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Catégorie (Utiliser Flexible/Expanded pour la valeur si elle peut être longue)
                      Row(
                        children: [
                          Icon(Icons.category,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Catégorie: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            // Pour que le nom de la catégorie puisse passer à la ligne si besoin
                            child: Text(
                              equipment.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Ou laisser wrap par défaut
                            ),
                          ),
                        ],
                      ),

                      // Emplacement
                      if (equipment.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Emplacement: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Flexible(
                              // Pour que l'emplacement puisse wrapper
                              child: Text(
                                equipment.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      //Identifiant de l'équipement
                      if (equipment.id.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.numbers_outlined,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Identifiant: ",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                equipment.id,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 250, 25, 25),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ])
                      ],
                    ],
                  ),
                ),

                // Colonne d'état et statut (alignée à droite)
                // Utiliser Wrap pourrait être une option ici si l'espace est très limité
                // Wrap(direction: Axis.vertical, alignment: WrapAlignment.end, spacing: 4, children: [...])
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // État
                    _buildStatusBadge(
                        label: 'État:',
                        value: equipment.state,
                        color: stateColor),

                    // Statut (si présent)
                    if (equipment.status.isNotEmpty) ...[
                      const SizedBox(
                          height: 4), // Espace réduit entre les badges
                      _buildStatusBadge(
                          label: 'Statut:',
                          value: _getStatusLabel(equipment.status),
                          color: statusColor),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // AJOUT: Helper widget pour les badges de statut (pour réutiliser et simplifier)
  Widget _buildStatusBadge(
      {required String label, required String value, required Color color}) {
    return Row(
      mainAxisSize:
          MainAxisSize.min, // Pour que la Row prenne la taille minimale
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis, // Assurer que le badge ne déborde pas
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Equipment equipment) {
    // ... (code inchangé) ...
    final equipmentService =
        Provider.of<EquipmentService>(context, listen: false);

    switch (action) {
      case 'assign':
        _showAssignDialog(context, equipment, equipmentService);
        break;
      case 'change_state':
        _showStateChangeDialog(context, equipment, equipmentService);
        break;
      case 'delete':
        _confirmDelete(context, equipment, equipmentService);
        break;
    }
  }

  void _showAssignDialog(
      BuildContext context, Equipment equipment, EquipmentService service) {
    // ... (code inchangé) ...
    String? selectedEmployeeId;
    String taskTitle = 'Maintenance de ${equipment.name}';
    String taskDescription =
        'Maintenance requise pour l\'équipement ${equipment.name} (${equipment.serialNumber})';
    String taskType = AppConstants.maintenanceTypes.keys.first;
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assigner l\'équipement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Équipement: ${equipment.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Sélectionner un employé:'),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Employee>>(
                      stream:
                          Provider.of<EmployeeService>(context, listen: false)
                              .getEmployees(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Aucun employé disponible');
                        }

                        // Filtrer les employés par rôle (technicien)
                        final technicians = snapshot.data!
                            .where((employee) =>
                                employee.role == AppConstants.roleTechnician)
                            .toList();

                        if (technicians.isEmpty) {
                          return const Text('Aucun technicien disponible');
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedEmployeeId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          hint: const Text('Sélectionner un technicien'),
                          isExpanded: true,
                          items: technicians.map((employee) {
                            return DropdownMenuItem<String>(
                              value: employee.id,
                              child: Text(
                                  '${employee.name} (${employee.function})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEmployeeId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Détails de la tâche:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: taskTitle,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        taskTitle = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: taskDescription,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        taskDescription = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: taskType,
                      decoration: const InputDecoration(
                        labelText: 'Type de maintenance',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: AppConstants.maintenanceTypes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          taskType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            dueDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: selectedEmployeeId == null
                      ? null
                      : () async {
                          // Récupérer l'utilisateur connecté
                          final authService =
                              Provider.of<AuthService>(context, listen: false);
                          final currentUser =
                              await authService.getCurrentUser();

                          // Créer une tâche de maintenance
                          final taskService =
                              Provider.of<MaintenanceTaskService>(context,
                                  listen: false);
                          final taskId = FirebaseFirestore.instance
                              .collection(
                                  AppConstants.maintenanceTasksCollection)
                              .doc()
                              .id;

                          final task = MaintenanceTask(
                            id: taskId,
                            title: taskTitle,
                            description: taskDescription,
                            equipmentId: equipment.id,
                            assignedTo: selectedEmployeeId!,
                            status: AppConstants
                                .taskStatuses.keys.first, // 'pending'
                            type: taskType,
                            dueDate: dueDate,
                            createdAt: DateTime.now(),
                          );

                          // Mettre à jour le statut de l'équipement
                          await service.updateEquipmentStatus(
                              equipment.id,
                              AppConstants
                                  .equipmentStatuses[0], // 'En maintenance'
                              currentUser?.name ?? 'Unknown User');

                          // Ajouter la tâche
                          await taskService.addTask(
                              task, currentUser?.name ?? 'Unknown User');

                          // Fermer le dialogue
                          Navigator.of(context).pop();

                          // Afficher un message de confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Équipement assigné et tâche de maintenance créée'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: const Text('Assigner'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStateColor(String state) {
    // ... (code inchangé) ...
    switch (state) {
      case 'Bon état':
        return Colors.green;
      case 'En panne':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    // ... (code inchangé) ...
    switch (status) {
      case 'En maintenance':
        return Colors.orange;
      case 'En Remplacement':
        return Colors.blue;
      case 'En retrait':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    // ... (code inchangé) ...
    return status;
  }
}
