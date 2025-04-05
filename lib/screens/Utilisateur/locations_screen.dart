import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  _LocationsScreenState createState() => _LocationsScreenState();
}

class Equipment {
  final String name;
  final String category;
  final String location;
  final String state;
  final String id;
  final String type;

  const Equipment({
    required this.name,
    required this.category,
    required this.location,
    required this.id,
    required this.type,
    required this.state,
  });
}

class _LocationsScreenState extends State<LocationsScreen> {
  String _selectedLocation = AppConstants.location.first;

  Color _getStateColor(String state) {
    return state == 'Bon état' ? Colors.green : Colors.red;
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userData['name'] ?? '';
    }
    return '';
  }

  void _showReportDialog(BuildContext context, Equipment equipment) {
    final _descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Faire un signalement sur l\'équipement ${equipment.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: [
                  const Text(
                    'Etat actuel:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' ${equipment.state}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStateColor(equipment.state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description du problème',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 5,
              ),
              onPressed: () async {
                final userName = await _getUserName();
                await FirebaseFirestore.instance.collection('reports').add({
                  'reportedBy': userName,
                  'reportedByRole': 'Utilisateur',
                  'location': equipment.location,
                  'equipmentName': equipment.name,
                  'equipmentId': equipment.id,
                  'timestamp': FieldValue.serverTimestamp(),
                  'description': _descriptionController.text,
                  'type': equipment.type,
                });

                // Ajouter une activité
                await FirebaseFirestore.instance.collection('activities').add({
                  'activityType': 'reportCreated',
                  'category': 'report',
                  'description': 'Nouveau signalement pour ${equipment.name}',
                  'details': {
                    'description': _descriptionController.text,
                    'equipmentId': equipment.id,
                    'equipmentName': equipment.name,
                    'location': equipment.location
                  },
                  'timestamp': FieldValue.serverTimestamp(),
                  'performedBy': userName,
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'targetName': equipment.name
                });
                Navigator.of(context).pop();
              },
              child: const Text('Envoyer le signalement'),
            ),
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Choix de position'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
                icon:const Icon(Icons.edit_location_outlined),
              value: _selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Oú etes vous?',
                border: OutlineInputBorder(),
              ),
              items: AppConstants.location.map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _selectedLocation = value!;
              }),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipment')
                  .where('location', isEqualTo: _selectedLocation)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Aucun équipement à cet emplacement'));
                }

                final equipmentList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: equipmentList.length,
                  itemBuilder: (context, index) {
                    final equipment =
                        equipmentList[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        final equipmentInstance = Equipment(
                          id: equipmentList[index]
                              .id, // Utilise l'id du document firestore de l'équipement
                          name: equipment['name'] ?? '',
                          category: equipment['category'] ?? '',
                          location: equipment['location'] ?? '',
                          state: equipment['state'] ?? '',
                          type: equipment['type'] ?? '',
                        );
                        _showReportDialog(context, equipmentInstance);
                      },
                      child: EquipmentCard(
                        equipment: Equipment(
                          id: equipmentList[index]
                              .id, // Utilise l'id du document firestore de l'équipement
                          name: equipment['name'] ?? '',
                          category: equipment['category'] ?? '',
                          location: equipment['location'] ?? '',
                          state: equipment['state'] ?? '',
                          type: equipment['type'] ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;

  const EquipmentCard({Key? key, required this.equipment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.computer,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.type + ' ' + equipment.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_rounded),
                      const SizedBox(width: 3),
                      Text(
                        'Identifiant: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        equipment.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color.fromARGB(186, 244, 3, 3),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      const Icon(Icons.category, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Catégorie: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        equipment.category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: equipment.state == 'Bon état'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          equipment.state,
                          style: TextStyle(
                            color: equipment.state == 'Bon état'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 4,
                      ),
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Emplacement: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        equipment.location,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ])),
    );
  }
}
