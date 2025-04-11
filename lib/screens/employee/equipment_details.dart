import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../../screens/employee/report_issue.dart';

class EquipmentDetails extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetails({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<EquipmentDetails> createState() => _EquipmentDetailsState();
}

class _EquipmentDetailsState extends State<EquipmentDetails> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.equipment.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportIssuePage(equipment: widget.equipment),
            ),
          );
        },
        icon: const Icon(Icons.report_problem),
        label: const Text('Signaler un problème'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // État de l'équipement
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.equipment.state == 'Bon état' 
                                  ? Icons.check_circle 
                                  : Icons.warning,
                                color: widget.equipment.state == 'Bon état'
                                  ? Colors.green
                                  : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Text(
                                    'État: ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.equipment.state,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: widget.equipment.state == 'Bon état'
                                       ? Colors.green
                                        : Colors.red,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        
                        ],
                      ),
                    ),
                  ),
                  
                  // Informations de base
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Informations de base',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Numéro de série : ', widget.equipment.serialNumber),
                          _buildInfoRow('Catégorie : ', widget.equipment.category),
                          _buildInfoRow('Localisation : ', widget.equipment.location),
                        ],
                      ),
                    ),
                  ),

                  // Détails techniques
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Détails techniques',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Fabricant : ', widget.equipment.manufacturer),
                          _buildInfoRow('Modèle :', widget.equipment.model),
                          _buildInfoRow('Fournisseur : ', widget.equipment.supplier),
                        ],
                      ),
                    ),
                  ),

                  // Informations de maintenance
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Date d\'achat et d\'installation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Date d\'achat : ', _formatDate(widget.equipment.purchaseDate)),
                          _buildInfoRow('Date d\'installation : ', _formatDate(widget.equipment.installationDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          thickness: 1,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final IconData icon;
    switch (label) {
      case 'Nom : ':
        icon = Icons.badge;
        break;
      case 'Numéro de série : ':
        icon = Icons.numbers;
        break;
      case 'Catégorie : ':
        icon = Icons.category;
        break;
      case 'Localisation : ':
        icon = Icons.location_on;
        break;
      case 'État : ':
        icon = Icons.assessment;
        break;
      case 'Statut : ':
        icon = Icons.info;
        break;
      case 'Fabricant : ':
        icon = Icons.factory;
        break;
      case 'Modèle : ':
        icon = Icons.model_training;
        break;
      case 'Fournisseur : ':
        icon = Icons.local_shipping;
        break;
      case 'Département responsable : ':
        icon = Icons.business;
        break;
      case 'Date d\'achat : ':
        icon = Icons.shopping_cart;
        break;
      case 'Date d\'installation : ':
        icon = Icons.install_desktop;
        break;
      default:
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return ' ${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut(context);
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
