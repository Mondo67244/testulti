import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/equipment_service.dart';
import '../../models/equipment.dart';
import 'equipment_details.dart';
import '../../constants/app_constants.dart';

class EquipmentList extends StatefulWidget {
  const EquipmentList({Key? key}) : super(key: key);

  @override
  State<EquipmentList> createState() => _EquipmentListState();
}

class _EquipmentListState extends State<EquipmentList>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentStateFilter = 'all'; // 'all', 'functional', 'defective'
  late TabController _tabController;

  // Constantes pour la mise en page responsive
  final double wideLayoutBreakpoint = 700.0;
  final double maxContentWidth = 800.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: AppConstants.equipmentCategories.length + 1,
        vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Widget _buildFilterButton(String filter, String label) {
    bool isSelected = _currentStateFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentStateFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  List<Equipment> _filterEquipments(List<Equipment> equipments) {
    return equipments.where((equipment) {
      final matchesCategory = _tabController.index == 0 ||
          equipment.category == AppConstants.equipmentCategories[_tabController.index - 1];
      
      final matchesState = _currentStateFilter == 'all' ||
          (_currentStateFilter == 'functional' && equipment.state == 'Bon état') ||
          (_currentStateFilter == 'defective' && equipment.state == 'En panne');

      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          equipment.id.toLowerCase().contains(searchLower) ||
          equipment.name.toLowerCase().contains(searchLower) ||
          equipment.category.toLowerCase().contains(searchLower) ||
          equipment.location.toLowerCase().contains(searchLower);

      return matchesCategory && matchesState && matchesSearch;
    }).toList();
  }

  String _getFilterText() {
    if (_currentStateFilter == 'functional') {
      return 'en bon état';
    } else if (_currentStateFilter == 'defective') {
      return 'en panne';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentService =
        Provider.of<EquipmentService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideLayout = constraints.maxWidth >= wideLayoutBreakpoint;
            final contentPadding = isWideLayout ? 24.0 : 12.0;
            
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWideLayout ? maxContentWidth : double.infinity,
                ),
                child: Column(
        children: [
          // Barre de catégories avec TabBar
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
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 2,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 12),
              labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
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

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un équipement...',
                hintStyle: TextStyle(fontSize: 15),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
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
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              style: TextStyle(fontSize: 15),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Liste des équipements
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: equipmentService.getEquipments(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final equipments = snapshot.data!;

                // Appliquer les filtres
                final filteredEquipments = _filterEquipments(equipments);

                if (filteredEquipments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun équipement ${_getFilterText().toLowerCase()} trouvé',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return isWideLayout
                  ? GridView.builder(
                      padding: EdgeInsets.all(contentPadding),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 450,
                        mainAxisExtent: 180,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredEquipments.length,
                      itemBuilder: (context, index) {
                        final equipment = filteredEquipments[index];
                        return _buildEquipmentCard(equipment, context);
                      },
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(contentPadding),
                      itemCount: filteredEquipments.length,
                      itemBuilder: (context, index) {
                        final equipment = filteredEquipments[index];
                        return _buildEquipmentCard(equipment, context);
                      },
                    );
                },
              ),
                ),
              
              ],
              )
            )
            );
          },
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment, BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetails(equipment: equipment),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(equipment.category),
          child: Text(
            equipment.name.isNotEmpty
                ? equipment.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                equipment.type + ' ' + equipment.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '#${equipment.id}',
              style: const TextStyle(
                color: Color.fromARGB(255, 255, 6, 6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category, size: 14, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  equipment.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  equipment.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                equipment.state,
                style: TextStyle(
                  fontSize: 11,
                  color: _getStateColor(equipment.state),
                ),
              ),
              backgroundColor: _getStateColor(equipment.state).withOpacity(0.1),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -2),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'Ordinateur': Colors.blue,
      'Serveur': Colors.purple,
      'Périphérique': Colors.green,
      'Réseau': Colors.orange,
      'Mobile': Colors.red,
      'Autre': Colors.grey,
    };

    return categoryColors[category] ?? Colors.grey;
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'Bon état':
        return Colors.green;
      case 'En maintenance':
        return Colors.orange;
      case 'En panne':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
