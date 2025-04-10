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
  late String _selectedLocation;
  String? _selectedEtat = AppConstants.etat.first;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.equipment.location;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrer les détails de l\'équiment ${widget.equipment.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
            // Dropdown for type of issue
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type de Panne',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.report_problem),
              ),
              items: <String>[
                'Matérielle',
                'Logicielle',
              ].map((String value) {
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
                labelText: 'Type d\'Action',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pan_tool),
              ),
              items: <String>[
                'Maintenance logicielle',
                'Maintenance matérielle',
                'Retrait définitif',
                'Maintenance logicielle',
                'Inspection générale',
              ].map((String value) {
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

            // Champ d'emplacement non modifiable
            TextFormField(
              enabled: false,
              initialValue: _selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Emplacement actuel de l\'équipement*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ), 
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
      ),
      )
      );
  }
}
