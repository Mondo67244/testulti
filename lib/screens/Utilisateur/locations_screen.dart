import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart'; // Ensure this path is correct

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

// Kept Equipment class for type safety and clarity
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

  // Factory constructor to create Equipment from Firestore data
  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Equipment(
      id: doc.id, // Use document ID
      name: data['name'] ?? 'Inconnu',
      category: data['category'] ?? 'Inconnue',
      location: data['location'] ?? 'Inconnu',
      state: data['state'] ?? 'Inconnu',
      type: data['type'] ?? 'Inconnu',
    );
  }
}


class _LocationsScreenState extends State<LocationsScreen> {
  String _selectedLocation = AppConstants.location.first;

  // AJOUT: Breakpoint et largeur max pour le contenu principal
  final double tabletBreakpoint = 600.0;
  final double maxContentWidth = 700.0; // Max width for dropdown and list content

  // Helper pour couleur état (inchangé)
  Color _getStateColor(String state) {
    return state == 'Bon état' ? Colors.green : Colors.red;
  }

  // Helper pour nom utilisateur (inchangé)
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
         final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
         // Check if data exists and 'name' field is present
         if (userData.exists && userData.data()!.containsKey('name')) {
            return userData['name'] ?? 'Anonyme';
         } else {
             print("User document found, but 'name' field is missing or null.");
             return 'Utilisateur Inconnu'; // Default if name is missing
         }
      } catch (e) {
          print("Error fetching user data: $e");
          return 'Erreur Utilisateur'; // Indicate an error occurred
      }
    }
    return 'Non Connecté'; // Default if no user
  }


  // Dialog (inchangé pour le moment, mais pourrait être rendu responsive aussi)
  void _showReportDialog(BuildContext context, Equipment equipment) {
     final descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Faire un signalement sur l\'équipement ${equipment.type} ${equipment.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView( // Ensure content is scrollable if needed
             child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Align left
              children: <Widget>[
                Row( // Garder Row pour l'état pour la couleur
                   children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                     const Text(
                       'État Actuel: ',
                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                     ),
                     Text(
                       equipment.state,
                       style: TextStyle(
                         fontSize: 14,
                         fontWeight: FontWeight.bold,
                         color: _getStateColor(equipment.state),
                       ),
                     ),
                   ],
                ),
                const SizedBox(height: 16),
                 TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description du problème *', // Indiquer requis si applicable
                     hintText: 'Décrivez la panne ou le problème observé...',
                     alignLabelWithHint: true,
                  ),
                   maxLines: 4, // Allow more lines
                   textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: <Widget>[
             TextButton( // Annuler à gauche
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon( // Bouton principal avec icône
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Envoyer'),
              style: ElevatedButton.styleFrom(
                 backgroundColor: Theme.of(context).primaryColor,
                 foregroundColor: Colors.white, // Texte blanc pour contraste
              ),
              onPressed: () async {
                final userName = await _getUserName();
                 final description = descriptionController.text.trim();

                 if (description.isEmpty) {
                    // Optionnel: Afficher un message si description vide
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Veuillez décrire le problème.'), backgroundColor: Colors.orange),
                    );
                    return; // Ne pas envoyer si vide
                 }

                try {
                   // Utiliser un batch pour les écritures atomiques
                   WriteBatch batch = FirebaseFirestore.instance.batch();
                   DocumentReference reportRef = FirebaseFirestore.instance.collection('reports').doc();
                   DocumentReference activityRef = FirebaseFirestore.instance.collection('activities').doc();

                   // Report Data
                   batch.set(reportRef, {
                     'reportedBy': userName,
                     'reportedByRole': 'Utilisateur', // Ou récupérer le rôle dynamiquement si nécessaire
                     'location': equipment.location,
                     'equipmentName': equipment.name,
                     'equipmentId': equipment.id,
                     'timestamp': FieldValue.serverTimestamp(),
                     'description': description,
                     'type': equipment.type, // Type d'équipement
                     'equipmentStateAtReport': equipment.state, // État au moment du rapport
                     'status': 'pending', // Statut initial du rapport
                   });

                   // Activity Data
                    batch.set(activityRef, {
                      'activityType': 'reportCreated', // Utiliser des clés cohérentes
                      'category': 'report',
                      'description': 'Signalement créé pour "${equipment.type} ${equipment.name}"', // Description plus claire
                      'details': {
                        'reportId': reportRef.id, // Lier à l'ID du rapport
                        'description': description,
                        'equipmentId': equipment.id,
                        'equipmentName': equipment.name,
                        'location': equipment.location
                      },
                      'timestamp': FieldValue.serverTimestamp(),
                      'performedBy': userName,
                      // 'id': activityRef.id, // Firestore génère l'ID, pas besoin de le mettre ici
                      'targetId': equipment.id, // ID de la cible de l'action
                      'targetName': equipment.name // Nom de la cible
                    });

                   await batch.commit(); // Commit batch

                   if (mounted) {
                      Navigator.of(context).pop(); // Fermer dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Signalement envoyé avec succès!'), backgroundColor: Colors.green),
                      );
                   }
                 } catch (e) {
                     print("Erreur lors de l'envoi du signalement: $e");
                     if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Erreur: Impossible d\'envoyer le signalement. $e'), backgroundColor: Colors.red),
                         );
                     }
                 }
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
          // MODIFICATION: Centrer et contraindre le Dropdown
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined), // Icône dropdown
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Où êtes-vous ?',
                    border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15), // Ajuster padding interne
                  ),
                  items: AppConstants.location.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                     if (value != null) { // Vérifier nullité
                        setState(() {
                          _selectedLocation = value;
                        });
                     }
                  },
                ),
              ),
            ),
          ),
          // MODIFICATION: Utiliser LayoutBuilder pour la liste
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
                final equipmentDocs = snapshot.data?.docs ?? [];

                if (equipmentDocs.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            const Icon(Icons.location_off_outlined, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Aucun équipement trouvé\nà cet emplacement: "$_selectedLocation"', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                         ],
                      ));
                }

                // Utilisation de LayoutBuilder
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Mode Liste pour écrans étroits
                    if (constraints.maxWidth < tabletBreakpoint) {
                      return ListView.builder(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: equipmentDocs.length,
                        itemBuilder: (context, index) {
                          final equipment = Equipment.fromFirestore(equipmentDocs[index]);
                          return EquipmentCard(
                             key: ValueKey(equipment.id), // Add key for better performance
                             equipment: equipment,
                             onTap: () => _showReportDialog(context, equipment),
                           );
                        },
                      );
                    }
                    // Mode Grille pour écrans larges
                    else {
                      return GridView.builder(
                         padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                           maxCrossAxisExtent: 450, // Largeur réduite pour les grands écrans
                           mainAxisExtent: 170, // Hauteur fixe pour contenir tout le contenu
                           crossAxisSpacing: 16,
                           mainAxisSpacing: 16,
                        ),
                        itemCount: equipmentDocs.length,
                        itemBuilder: (context, index) {
                          final equipment = Equipment.fromFirestore(equipmentDocs[index]);
                          return EquipmentCard(
                            key: ValueKey(equipment.id), // Add key
                            equipment: equipment,
                            onTap: () => _showReportDialog(context, equipment),
                          );
                        },
                      );
                    }
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

   // Helper pour construire une ligne de détail (déplacé ici pour être utilisé aussi dans le dialog)
   Widget _buildDetailRow(IconData icon, String label, String value, {TextStyle? valueStyle}) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 3.0),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Icon(icon, size: 16, color: Colors.grey.shade700),
           const SizedBox(width: 6),
           Text(
             '$label: ',
             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
           ),
           Flexible( // Important
             child: Text(
               value.isNotEmpty ? value : '-',
               style: valueStyle ?? const TextStyle(fontSize: 12, color: Colors.black87),
             ),
           ),
         ],
       ),
     );
   }
}

// --- Equipment Card Widget ---
class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap; // Ajouter un callback pour le tap

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onTap, // Requis
  }) : super(key: key);

   // Helper interne pour la couleur (copié de _LocationsScreenState)
   Color _getStateColor(String state) {
     return state == 'Bon état' ? Colors.green : Colors.red;
   }
   // Helper interne pour l'icône (peut être basé sur type ou category)
   IconData _getEquipmentIcon(String type) {
      switch(type.toLowerCase()){
          case 'ordinateur': return Icons.computer_outlined;
          case 'laptop': return Icons.laptop_chromebook_outlined;
          case 'imprimante': return Icons.print_outlined;
          case 'écran': return Icons.desktop_windows_outlined;
          case 'serveur': return Icons.dns_outlined;
          case 'routeur': return Icons.router_outlined;
          case 'switch': return Icons.settings_ethernet_outlined;
          case 'modem' : return Icons.router_outlined;
          default: return Icons.devices_other_outlined;
      }
   }


  @override
  Widget build(BuildContext context) {
    return Card(
      // margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Margin géré par list/grid
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Assure que l'InkWell est clippé
      child: InkWell( // Rendre toute la carte cliquable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding réduit légèrement
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligner en haut
            children: [
              // Icône améliorée
              CircleAvatar( // Utiliser CircleAvatar pour un look plus sympa
                 radius: 24,
                 backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                 child: Icon(
                    _getEquipmentIcon(equipment.type),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                 ),
              ),
              const SizedBox(width: 12),
              // Colonne de détails (prend le reste de l'espace)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne Titre + État
                     Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Expanded( // Titre prend l'espace disponible
                              child: Text(
                                '${equipment.type} ${equipment.name}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                 maxLines: 2, // Permet 2 lignes pour le titre
                                 overflow: TextOverflow.ellipsis,
                              ),
                           ),
                           const SizedBox(width: 8),
                            // Badge d'état (plus petit)
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: _getStateColor(equipment.state).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                     border: Border.all(color: _getStateColor(equipment.state).withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                    equipment.state,
                                    style: TextStyle(
                                    color: _getStateColor(equipment.state),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10, // Texte plus petit
                                    ),
                                ),
                            ),
                        ],
                     ),
                    const SizedBox(height: 8),
                    // Utiliser le helper pour les autres détails
                    _buildDetailRow(context, Icons.qr_code_rounded, 'ID', equipment.id, valueStyle: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 249, 18, 18), fontWeight: FontWeight.bold)), // ID plus petit et couleur différente?
                    _buildDetailRow(context, Icons.category_outlined, 'Catégorie', equipment.category),
                    _buildDetailRow(context, Icons.location_on_outlined, 'Emplacement', equipment.location),

                    // Emplacement est déjà connu via le filtre, mais on peut le laisser pour confirmation
                    // _buildDetailRow(context, Icons.location_on_outlined, 'Emplacement', equipment.location),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   // Helper interne à la carte pour construire les lignes de détail
   Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {TextStyle? valueStyle}) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 4.0), // Espace sous chaque ligne
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.center, // Centrer verticalement dans la Row
         children: [
           Icon(icon, size: 18, color: Colors.black87), // Icône plus petite
           const SizedBox(width: 5),
           Text(
             '$label: ',
             style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold), // Label plus petit
           ),
           Flexible( // Important
             child: Text(
               value.isNotEmpty ? value : '-',
               style: valueStyle ?? TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color), // Style valeur plus petit
               overflow: TextOverflow.ellipsis, // Tronquer si trop long
             ),
           ),
         ],
       ),
     );
   }
}