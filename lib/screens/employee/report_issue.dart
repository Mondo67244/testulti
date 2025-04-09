import 'package:flutter/material.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart';
import '../../models/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIssuePage extends StatefulWidget {
  final Equipment equipment;

  const ReportIssuePage({Key? key, required this.equipment}) : super(key: key);

  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _descriptionController = TextEditingController();
  String? _selectedIssueType;
  String? _selectedActionType;
  String? _selectedLocation = AppConstants.location.first;
  String? _selectedEtat = AppConstants.etat.first;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'en cours':
        return Colors.blue;
      case 'terminé':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Rentrer en arriere
          },
        ),
        title: const Text('Faire un Rapport'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Non-editable field for equipment name
            Text('Entrer les détails de l\'équiment ${widget.equipment.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Dropdown for type of issue
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                icon: Icon(Icons.report_problem),
                labelText: 'Type de Panne',
                border: OutlineInputBorder(),
              ),
              items: <String>['Matérielle', 'Logicielle'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIssueType = value;
                });
              },
              value: _selectedIssueType,
            ),
            const SizedBox(height: 16),

            // Dropdown for action type
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                icon: Icon(Icons.pan_tool),
                labelText: 'Type d’Action',
                border: OutlineInputBorder(),
              ),
              items: <String>['Maintenance', 'Remplacement', 'Retrait']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActionType = value;
                });
              },
              value: _selectedActionType,
            ),
            const SizedBox(height: 16),

            // Dropdown pour la localisation
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(
                  labelText: 'Emplacement*',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.add_business_outlined)),
              items: AppConstants.location.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            //État équipement
            DropdownButtonFormField<String>(
              value: _selectedEtat,
              decoration: const InputDecoration(
                  labelText: 'État d\'avancement du rapport*',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.shield_sharp)),
              items: AppConstants.etat.map((etat) {
                return DropdownMenuItem<String>(
                  value: etat,
                  child: Text(etat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEtat = value;
                });
              },
            ),
            Text('📌 Statut : $_selectedEtat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_selectedEtat ?? '')),
                      ),
            const SizedBox(height: 16),

            // Add a description field
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description du problème',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedIssueType == null || _selectedActionType == null) {
                    // Handle the error case where the issue type or action type is null
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Veuillez sélectionner tous les champs requis.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Utilisateur non connecté.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    if (!userDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Informations de l'utilisateur non trouvées."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final userName =
                        userDoc.data()?['name'] ?? "Utilisateur inconnu";

                    final reportRef = await FirebaseFirestore.instance.collection('reports').add({
                      'equipmentId': widget.equipment.id,
                      'equipmentName': widget.equipment.name,
                      'reportedBy': userName,
                      'reportedByRole': 'Maintenancier',
                      'issueType': _selectedIssueType,
                      'location': _selectedLocation,
                      'actionType': _selectedActionType,
                      'description': _descriptionController.text.trim(),
                      'status': _selectedEtat,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // Ajouter une activité
                    await FirebaseFirestore.instance.collection('activities').add({
                      'activityType': 'reportCreated',
                      'category': 'report',
                      'description': 'Nouveau rapport de maintenance pour l\'équipement " ${widget.equipment.name} "',
                      'details': {
                        'description': _descriptionController.text.trim(),
                        'equipmentId': widget.equipment.id,
                        'equipmentName': widget.equipment.name,
                        'issueType': _selectedIssueType,
                        'actionType': _selectedActionType,
                        'location': _selectedLocation,
                        'status': _selectedEtat,
                        'reportId': reportRef.id
                      },
                      'timestamp': FieldValue.serverTimestamp(),
                      'performedBy': userName,
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'targetName': widget.equipment.name
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rapport envoyé avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Navigate back
                    Navigator.pop(context);
                  } catch (e) {
                    // Handle errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'envoi du rapport: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Envoyer le Rapport'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
