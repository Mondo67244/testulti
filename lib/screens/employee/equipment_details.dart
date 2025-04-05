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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations de l'équipement
                  _buildInfoSection(
                    'Informations générales',
                    [
                      _buildInfoRow('Nom', widget.equipment.name),
                      _buildInfoRow(
                          'Numéro de série', widget.equipment.serialNumber),
                      _buildInfoRow('Catégorie', widget.equipment.category),
                      _buildInfoRow('Localisation', widget.equipment.location),
                      _buildInfoRow('État', widget.equipment.state),
                      _buildInfoRow('Statut', widget.equipment.status),
                      _buildInfoRow('Fabricant', widget.equipment.manufacturer),
                      _buildInfoRow('Modèle', widget.equipment.model),
                      _buildInfoRow('Fournisseur', widget.equipment.supplier),
                      _buildInfoRow('Département responsable',
                          widget.equipment.responsibleDepartment),
                      _buildInfoRow('Date d\'achat',
                          _formatDate(widget.equipment.purchaseDate)),
                      _buildInfoRow('Date d\'installation',
                          _formatDate(widget.equipment.installationDate)),
                      if (widget.equipment.lastMaintenanceDate != null)
                        _buildInfoRow('Dernière maintenance',
                            _formatDate(widget.equipment.lastMaintenanceDate!)),
                      if (widget.equipment.nextMaintenanceDate != null)
                        _buildInfoRow('Prochaine maintenance',
                            _formatDate(widget.equipment.nextMaintenanceDate!)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildInfoSection(
                    'Caractéristiques de l\'équipement',
                    [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('Quelques caractéristiques pour l\'équipement'
                            ' ${widget.equipment.description} nous avons :'
                          ,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add the button to navigate to the report issue page
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReportIssuePage(equipment: widget.equipment),
                          ),
                        );
                      },
                      child: const Text('Faire un rapport'),
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
      case 'Nom':
        icon = Icons.badge;
        break;
      case 'Numéro de série':
        icon = Icons.numbers;
        break;
      case 'Catégorie':
        icon = Icons.category;
        break;
      case 'Localisation':
        icon = Icons.location_on;
        break;
      case 'État':
        icon = Icons.assessment;
        break;
      case 'Statut':
        icon = Icons.info;
        break;
      case 'Fabricant':
        icon = Icons.factory;
        break;
      case 'Modèle':
        icon = Icons.model_training;
        break;
      case 'Fournisseur':
        icon = Icons.local_shipping;
        break;
      case 'Département responsable':
        icon = Icons.business;
        break;
      case 'Date d\'achat':
        icon = Icons.shopping_cart;
        break;
      case 'Date d\'installation':
        icon = Icons.install_desktop;
        break;
      case 'Dernière maintenance':
        icon = Icons.build;
        break;
      case 'Prochaine maintenance':
        icon = Icons.schedule;
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
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
    return '${date.day}/${date.month}/${date.year}';
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
          TextButton(
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
