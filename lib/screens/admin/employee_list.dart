import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/employee_service.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';
import 'employee_form.dart';


class EmployeeList extends StatefulWidget {
  const EmployeeList({Key? key}) : super(key: key);

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentRoleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildRoleFilterButton(String role, String label) {
    final isSelected = _currentRoleFilter == role;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentRoleFilter = role;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? _getRoleColor(role) : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

  @override
  Widget build(BuildContext context) {
    final employeeService =
        Provider.of<EmployeeService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Vérifier si l'utilisateur est connecté
    if (authService.currentUser == null) {
      return const Center(
          child:
              Text('Veuillez vous connecter pour voir la liste des employés.'));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un employé...',
                hintStyle: const TextStyle(fontSize: 15),
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
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              style: const TextStyle(fontSize: 15),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Barre de filtres de rôle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRoleFilterButton('all', 'Tous'),
                  const SizedBox(width: 8),
                  _buildRoleFilterButton('admin', 'Admininstrateurs'),
                  const SizedBox(width: 8),
                  _buildRoleFilterButton('maintenancier', 'Maintenanciers'),
                  const SizedBox(width: 8),
                  _buildRoleFilterButton('fournisseur', 'Fournisseurs'),
                  const SizedBox(width: 8),
                  _buildRoleFilterButton('utilisateur', 'Utilisateurs'),
                ],
              ),
            ),
          ),

          // Liste des employés
          Expanded(
            child: StreamBuilder<List<Employee>>(
              stream: employeeService.getEmployees(),
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

                final employees = snapshot.data!;

                // Filtrer les employés selon la recherche
                final filteredEmployees = _searchQuery.isEmpty && _currentRoleFilter == 'all'
                    ? employees
                    : employees
                        .where((employee) =>
                            (_currentRoleFilter == 'all' ||
                                employee.role.toLowerCase() == _currentRoleFilter) &&
                            (_searchQuery.isEmpty ||
                                employee.name
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                employee.function
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                employee.department
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                employee.id
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                employee.role
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase())))
                        .toList();

                if (filteredEmployees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search,
                            size: 30, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun employé trouvé'
                              : 'Aucun employé ne correspond à "$_searchQuery"',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Afficher deux employés par ligne
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return _buildEmployeeCard(employee);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmployeeForm(),
            ),
          );
        },
        tooltip: 'Ajouter un employé',
        elevation: 2,
        mini: false,
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }


  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color.fromARGB(201, 30, 136, 229); // Bleu royal
      case 'maintenancier':
        return const Color.fromARGB(210, 239, 108, 0); // Orange vif
      case 'fournisseur':
        return const Color.fromARGB(213, 57, 72, 171); // Bleu indigo
      // Bleu gris
      case 'utilisateur':
        return const Color.fromARGB(212, 242, 17, 17); // Marron
      default:
        return const Color(0xFF757575); // Gris neutre
    }
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showEmployeeDetails(employee),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _getRoleColor(employee.role).withOpacity(0.9),
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                employee.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D3142),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                employee.function,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '   ID :   ',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    employee.id,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 253, 18, 18),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(employee.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getRoleLabel(employee.role),
                  style: TextStyle(
                    color: _getRoleColor(employee.role),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Employee employee, EmployeeService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'employé "${employee.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.deleteEmployee(employee.id, employee.name, 'Admin');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employé "${employee.name}" supprimé'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'maintenancier':
        return 'Maintenancier';
      case 'fournisseur':
        return 'Fournisseur';  
      case 'utilisateur':
        return 'Utilisateur';
      default:
        return role;
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.email, 'Email', employee.email),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.work, 'Fonction', employee.function),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.business, 'Département', employee.department),
            const SizedBox(height: 8),
            _buildDetailRow(
                Icons.verified_user, 'Rôle', _getRoleLabel(employee.role)),
            const SizedBox(height: 8),
            _buildDetailRow(
                Icons.location_on, 'Emplacement', employee.location),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, employee,
                  Provider.of<EmployeeService>(context, listen: false));
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
