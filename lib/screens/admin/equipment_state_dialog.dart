import 'package:flutter/material.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../constants/app_constants.dart';

class EquipmentStateDialog extends StatefulWidget {
  final Equipment equipment;
  final EquipmentService service;

  const EquipmentStateDialog({
    Key? key,
    required this.equipment,
    required this.service,
  }) : super(key: key);

  @override
  State<EquipmentStateDialog> createState() => _EquipmentStateDialogState();
}

class _EquipmentStateDialogState extends State<EquipmentStateDialog> {
  late String selectedState;
  late String selectedStatus;
  late bool showStatusSelection;

  @override
  void initState() {
    super.initState();
    selectedState = widget.equipment.state;
    selectedStatus = widget.equipment.status;
    showStatusSelection = selectedState == 'En panne';
  }

  Color _getStateColor(String state) {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer l\'état'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection de l'état
          const Text('État de l\'équipement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...AppConstants.equipmentStates.map((state) {
            final isCurrentState = selectedState == state;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              leading: Radio<String>(
                value: state,
                groupValue: selectedState,
                activeColor: _getStateColor(state),
                onChanged: (value) {
                  setState(() {
                    selectedState = value!;
                    showStatusSelection = selectedState == 'En panne';
                    
                    // Si on passe à "Bon état", réinitialiser le statut
                    if (selectedState == 'Bon état') {
                      selectedStatus = '';
                    }
                  });
                },
              ),
              title: Text(
                state,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrentState ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          
          // Sélection du statut (uniquement si en panne)
          if (showStatusSelection) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Statut de l\'équipement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...AppConstants.equipmentStatuses.map((status) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                leading: Radio<String>(
                  value: status,
                  groupValue: selectedStatus,
                  activeColor: _getStatusColor(status),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                title: Text(status, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Fermer le dialogue
            Navigator.of(context).pop();
            
            // Mettre à jour l'état
            if (selectedState != widget.equipment.state) {
              await widget.service.updateEquipmentState(widget.equipment.id, selectedState, 'Admin');
            }
            
            // Mettre à jour le statut si nécessaire
            if (selectedStatus != widget.equipment.status) {
              await widget.service.updateEquipmentStatus(widget.equipment.id, selectedStatus, 'Admin');
            }
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Équipement mis à jour'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
