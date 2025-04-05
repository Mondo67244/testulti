import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pour formater la date


class ReportsListScreen extends StatefulWidget {
  @override
  _ReportsListScreenState createState() => _ReportsListScreenState();
}

class Equipment {
  String name;
  String category;
  String location;
  String state;
  String id;
  String type;

  Equipment({
    required this.name,
    required this.category,
    required this.location,
    required this.id,
    required this.type,
    required this.state,
  });
}


class _ReportsListScreenState extends State<ReportsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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

  Widget _buildReportList(String role) {
    print('Filtrage des rapports pour le rôle: $role');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('reportedByRole', isEqualTo: role)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(
              'Erreur lors de la récupération des rapports: ${snapshot.error}');
          return const Center(child: Text('Une erreur est survenue'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('En attente des données...');
          return const Center(child: CircularProgressIndicator());
        }

        // Vérifier si la liste de rapports est vide
        if (snapshot.data?.docs.isEmpty ?? true) {
          print('Aucun rapport trouvé pour le rôle: $role');
          return const Center(child: Text('Aucun rapport disponible.'));
        }

        print(
            '${snapshot.data!.docs.length} rapports trouvés pour le rôle: $role');

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;

            // Vérification des données et valeurs par défaut
            String equipmentName =
                data['equipmentName'] ?? 'Équipement inconnu';
            String reportedBy = data['reportedBy'] ?? 'Utilisateur inconnu';
            String location = data['location'] ?? 'Utilisateur inconnu';
            String equipmentId = data['equipmentId'] ?? 'ID inconnu';
            String issueType = data['issueType'] ?? 'Type inconnu';
            String actionType = data['actionType'] ?? 'Action inconnue';
            String type = data['type'] ?? ' inconnue';
            String description =
                data['description'] ?? 'Aucune description disponible';
            String dateFormatted = 'Date inconnue';

            // Convertir le timestamp en date lisible
            if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
              dateFormatted = DateFormat('dd/MM/yyyy HH:mm')
                  .format(data['timestamp'].toDate());
            }

            if (role == 'Maintenancier') {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(
                    type + ' ' + equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const Text(
                            ' Créé par : ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(reportedBy,
                              style: const TextStyle(
                                  color: Color.fromARGB(189, 104, 58, 183),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_rounded),
                          const Text(' ID Équipement : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            equipmentId,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.handyman),
                          const Text('Type d\'action : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text(' => '),
                          Text(actionType,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.warning),
                          const Text(' Type panne : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text(' => '),
                          Text(
                            issueType,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.featured_play_list_outlined),
                          Text(' Description : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                          margin:const EdgeInsets.all(10),
                          width: 400,
                          child: Text(
                            '\"$description\"',
                            maxLines: 9,
                          )),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          const Text(' Date : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(dateFormatted),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const Text(' Emplacement : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(location),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              //role utilisateur
            } else if (role == 'Fournisseur') {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(
                    equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const Text(
                            ' Créé par : ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(reportedBy,
                              style: const TextStyle(
                                  color: Color.fromARGB(189, 104, 58, 183),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.featured_play_list_outlined),
                          Text(' Description : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                          margin: const EdgeInsets.all(10),
                          width: 400,
                          child: Text(
                            '\"$description\"',
                            maxLines: 9,
                          )),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          const Text(' Date : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(dateFormatted),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              //role fournisseur
            } else if (role == 'Utilisateur') {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(
                     equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const Text(
                            ' Créé par : ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(reportedBy,
                              style: const TextStyle(
                                  color: Color.fromARGB(189, 104, 58, 183),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_rounded),
                          const Text(' ID Équipement : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            equipmentId,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.featured_play_list_outlined),
                          Text(' Description : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                          margin: EdgeInsets.all(10),
                          width: 400,
                          child: Text(
                            '"$description"',
                            maxLines: 9,
                          )),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          const Text(' Date d\'envoi : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(dateFormatted),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const Text(' Emplacement : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(location),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }).toList(),
        );
      },
    );
  }
}
