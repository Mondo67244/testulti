import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersList extends StatelessWidget {
  const AdminOrdersList({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width >= 600 && screenSize.width >=919;
    final isVerySmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 222, 254),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Historique des commandes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('supplierId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isVerySmallScreen ? 1 : (screenSize.width >=600 && screenSize.width <= 918) ? 2 : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 15,
              childAspectRatio: isSmallScreen ? 1.0 : 1.2,
              mainAxisExtent: 200
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;

              // Données de la commande
              String title = data['title'];
              String description = data['description'];
              String dateFormatted = 'Date inconnue';

              if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                dateFormatted = DateFormat('dd/MM/yyyy HH:mm')
                    .format(data['timestamp'].toDate());
              }

              return InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController responseController =
                          TextEditingController();
                      return AlertDialog(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Répondre à la commande:',
                              style: TextStyle(fontSize: 15),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Écrivez votre réponse:',
                                style: TextStyle(fontSize: 15),
                              ),
                              TextField(
                                controller: responseController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Votre réponse...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (responseController.text.isNotEmpty) {
                                // Créer un nouveau rapport
                                final userName = await _getUserName();
                                final reportRef = await FirebaseFirestore.instance
                                    .collection('reports')
                                    .add({
                                  'equipmentName': title,
                                  'description': responseController.text,
                                  'reportedBy': userName,
                                  'reportedByRole': 'Fournisseur',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                // Ajouter une activité
                                await FirebaseFirestore.instance
                                    .collection('activities')
                                    .add({
                                  'activityType': 'reportCreated',
                                  'category': 'report',
                                  'description':
                                      'Nouvelle réponse à la commande: $title',
                                  'details': {
                                    'description': responseController.text,
                                    'equipmentName': title,
                                    'reportId': reportRef.id
                                  },
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'performedBy': userName,
                                  'id': DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  'targetName': title
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Réponse envoyée avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez entrer un message!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Envoyer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Icon(Icons.description),
                             SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Description:',
                                style:  TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.calendar_month_outlined),
                            const SizedBox(width: 5),
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                  fontSize: isVerySmallScreen ? 12 : 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}