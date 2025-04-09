import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pour formater la date

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key}); // Added Key

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

// Removed the separate Equipment class as it wasn't used directly here.

class _ReportsListScreenState extends State<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AJOUT: Breakpoint pour le layout Grid
  final double tabletBreakpoint = 600.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        // automaticallyImplyLeading: false, // Keep default back arrow if nested
        title: const Text('Rapports récents'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(146, 250, 248, 248),
          tabs: const [
            Tab(text: 'Maintenanciers'),
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Fournisseurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportList('Maintenancier'),
          _buildReportList('Utilisateur'),
          _buildReportList('Fournisseur'),
        ],
      ),
    );
  }

  // Widget principal pour construire la liste (ListView ou GridView)
  Widget _buildReportList(String role) {
    // print('Filtrage des rapports pour le rôle: $role'); // Keep for debugging if needed
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('reportedByRole', isEqualTo: role)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // print('Erreur lors de la récupération des rapports: ${snapshot.error}');
          return const Center(child: Text('Une erreur est survenue'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // print('En attente des données...');
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          // print('Aucun rapport trouvé pour le rôle: $role');
          return Center(
              child: Text('Aucun rapport de "$role" disponible.')); // More specific message
        }

        // print('${documents.length} rapports trouvés pour le rôle: $role');

        // AJOUT: Utilisation de LayoutBuilder pour choisir le layout
        return LayoutBuilder(
          builder: (context, constraints) {
            // Si écran étroit -> ListView
            if (constraints.maxWidth < tabletBreakpoint) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final data = documents[index].data() as Map<String, dynamic>;
                  return _buildCardForItem(role, data); // Appel fonction générique
                },
              );
            }
            // Si écran large -> GridView
            else {
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final data = documents[index].data() as Map<String, dynamic>;
                  return _buildCardForItem(role, data);
                },
              );
            }
          },
        );
      },
    );
  }

  // Fonction générique pour choisir quelle carte construire
  Widget _buildCardForItem(String role, Map<String, dynamic> data) {
     // Vérification des données et valeurs par défaut (placées ici pour être accessibles par toutes les card builders)
    String equipmentName = data['equipmentName'] ?? 'Équipement inconnu';
    String reportedBy = data['reportedBy'] ?? 'Utilisateur inconnu';
    String location = data['location'] ?? 'Non spécifié'; // Ajustement
    String equipmentId = data['equipmentId'] ?? 'ID inconnu';
    String issueType = data['issueType'] ?? 'Non spécifié'; // Ajustement
    String actionType = data['actionType'] ?? 'Non spécifié'; // Ajustement
    String type = data['type'] ?? 'Type inconnu'; // Type d'équipement
    String description = data['description'] ?? 'Aucune description'; // Ajustement
    String dateFormatted = 'Date inconnue';

    if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
      try {
         dateFormatted = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(data['timestamp'].toDate());
      } catch(e) {
         print("Erreur formatage date: $e");
         dateFormatted = "Date invalide";
      }
    }

    // Appel du builder spécifique basé sur le rôle
    switch (role) {
      case 'Maintenancier':
        return _buildMaintenancierReportCard(equipmentName, reportedBy, location, equipmentId, issueType, actionType, type, description, dateFormatted);
      case 'Utilisateur':
        return _buildUtilisateurReportCard(equipmentName, reportedBy, location, equipmentId, description, dateFormatted);
      case 'Fournisseur':
        return _buildFournisseurReportCard(equipmentName, reportedBy, description, dateFormatted);
      default:
        return const SizedBox.shrink(); // Ne rien afficher si rôle inconnu
    }
  }

  // --- Builders Spécifiques pour chaque type de carte ---

  Widget _buildMaintenancierReportCard(String equipmentName, String reportedBy, String location, String equipmentId, String issueType, String actionType, String type, String description, String dateFormatted) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.person_outline, 'Créé par', reportedBy, valueStyle: const TextStyle(color: Color.fromARGB(189, 104, 58, 183), fontWeight: FontWeight.bold)),
                _buildDetailRow(Icons.qr_code_rounded, 'ID Équipement', equipmentId, valueStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                _buildDetailRow(Icons.handyman_outlined, 'Type d\'action', actionType),
                _buildDetailRow(Icons.warning_amber_outlined, 'Type panne', issueType),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.featured_play_list_outlined, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    '" $description "',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(height: 10),
                _buildDetailRow(Icons.calendar_month_outlined, 'Date', dateFormatted),
                _buildDetailRow(Icons.location_on_outlined, 'Emplacement', location),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilisateurReportCard(String equipmentName, String reportedBy, String location, String equipmentId, String description, String dateFormatted) {
      return Card(
         elevation: 2,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxHeight: 300),
           child: SingleChildScrollView(
             child: Padding(
               padding: const EdgeInsets.all(12.0),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     equipmentName,
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 8),
                   _buildDetailRow(Icons.person_outline, 'Créé par', reportedBy, valueStyle: const TextStyle(color: Color.fromARGB(189, 104, 58, 183), fontWeight: FontWeight.bold)),
                   _buildDetailRow(Icons.qr_code_rounded, 'ID Équipement', equipmentId, valueStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 5),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Icon(Icons.featured_play_list_outlined, size: 16, color: Colors.grey.shade700),
                       const SizedBox(width: 6),
                       const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Padding(
                     padding: const EdgeInsets.only(left: 22.0),
                     child: Text(
                       description,
                       style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                       maxLines: 5,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   const SizedBox(height: 10),
                   const Divider(height: 15),
                   _buildDetailRow(Icons.calendar_month_outlined, 'Date d\'envoi', dateFormatted),
                   _buildDetailRow(Icons.location_on_outlined, 'Emplacement', location),
                 ],
               ),
             ),
           ),
         ),
      );
   }

   Widget _buildFournisseurReportCard(String equipmentName, String reportedBy, String description, String dateFormatted) {
      return Card(
         elevation: 2,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
         child: ConstrainedBox(
           constraints: const BoxConstraints(maxHeight: 250),
           child: SingleChildScrollView(
             child: Padding(
               padding: const EdgeInsets.all(12.0),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     equipmentName,
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 8),
                   _buildDetailRow(Icons.person_outline, 'Créé par', reportedBy, valueStyle: const TextStyle(color: Color.fromARGB(189, 104, 58, 183), fontWeight: FontWeight.bold)),
                   const SizedBox(height: 5),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Icon(Icons.featured_play_list_outlined, size: 16, color: Colors.grey.shade700),
                       const SizedBox(width: 6),
                       const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Padding(
                     padding: const EdgeInsets.only(left: 22.0),
                     child: Text(
                       description,
                       style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                       maxLines: 5,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Divider(height: 15),
                   _buildDetailRow(Icons.calendar_month_outlined, 'Date', dateFormatted),
                 ],
               ),
             ),
           ),
         ),
      );
   }


  // --- Helper Widget ---

  // Helper pour afficher une ligne de détail (Icon - Label - Value)
  Widget _buildDetailRow(IconData icon, String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Espacement vertical
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligner en haut si valeur multi-lignes
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700), // Taille icône
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Flexible( // Important pour que la valeur puisse wrapper
            child: Text(
              value.isNotEmpty ? value : '-', // Afficher '-' si vide
              style: valueStyle ?? const TextStyle(fontSize: 12, color: Colors.black87),
              // softWrap: true, // Par défaut pour Text
            ),
          ),
        ],
      ),
    );
  }
}