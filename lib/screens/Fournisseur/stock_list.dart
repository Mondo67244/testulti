import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockList extends StatelessWidget {
  const StockList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stock')
          .where('fournisseurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Ajout de logs pour le débogage
        print('État de la connexion: ${snapshot.connectionState}');
        print('Erreur: ${snapshot.hasError ? snapshot.error : "Aucune"}');
        print('Données: ${snapshot.hasData ? "Présentes" : "Absentes"}');
        
        if (snapshot.hasError) {
          print('Erreur détaillée: ${snapshot.error}');
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final equipments = snapshot.data!.docs;
        print('Nombre d\'équipements trouvés: ${equipments.length}');
        
        if (equipments.isNotEmpty) {
          print('Premier équipement: ${equipments.first.data()}');
        }

        if (equipments.isEmpty) {
          return const Center(
            child: Text('Aucun équipement en stock'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Breakpoint pour tablette
            const tabletBreakpoint = 600;
            
            // Affichage en liste pour petits écrans
            if (constraints.maxWidth < tabletBreakpoint) {
              return ListView.builder(
                itemCount: equipments.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final equipment = equipments[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(equipment['name']?.toString() ?? 'Sans nom', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.space_dashboard_outlined),
                              const SizedBox(width: 2),
                              const Text('Type d\'appareil : ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['type'].toString(),
                                style: const TextStyle(color: Color.fromARGB(255, 126, 5, 239), fontWeight: FontWeight.bold))
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.numbers),
                              const SizedBox(width: 2),
                              const Text('Modèle : ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['model']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.bubble_chart_outlined),
                              const SizedBox(width: 2),
                              const Text('Marque : ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['manufacturer']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.qr_code),
                              const SizedBox(width: 2),
                              const Text('N° Série : ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['serialNumber']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } 
            // Affichage en grille pour grands écrans
            else {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: equipments.length,
                itemBuilder: (context, index) {
                  final equipment = equipments[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(equipment['name']?.toString() ?? 'Sans nom', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.space_dashboard_outlined, size: 16),
                              const SizedBox(width: 4),
                              const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['type'].toString(),
                                style: const TextStyle(color: Color.fromARGB(255, 126, 5, 239)))
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.numbers, size: 16),
                              const SizedBox(width: 4),
                              const Text('Modèle: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['model']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.bubble_chart_outlined, size: 16),
                              const SizedBox(width: 4),
                              const Text('Marque: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['manufacturer']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.qr_code, size: 16),
                              const SizedBox(width: 4),
                              const Text('N° Série: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(equipment['serialNumber']?.toString() ?? 'Non spécifié')
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}