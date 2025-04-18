import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierOrdersList extends StatelessWidget {
  const SupplierOrdersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 240, 232, 255),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Commandes livrées'),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('commandelivr')
                .where('fournisseurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy('dateReception', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final equipments = snapshot.data!.docs;

              if (equipments.isEmpty) {
                return const Center(
                  child: Text('Aucune commande livrée'),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  const tabletBreakpoint = 600;

                  if (constraints.maxWidth < tabletBreakpoint) {
                    return ListView.builder(
                      itemCount: equipments.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final equipment =
                            equipments[index].data() as Map<String, dynamic>;
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(
                              equipment['name']?.toString() ?? 'Sans nom',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.space_dashboard_outlined),
                                    const SizedBox(width: 2),
                                    const Text('Type d\'appareil : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      equipment['type'].toString(),
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 126, 5, 239),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.numbers),
                                    const SizedBox(width: 2),
                                    const Text('Modèle : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(equipment['model']?.toString() ??
                                        'Non spécifié'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.bubble_chart_outlined),
                                    const SizedBox(width: 2),
                                    const Text('Marque : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        equipment['manufacturer']?.toString() ??
                                            'Non spécifié'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.qr_code),
                                    const SizedBox(width: 2),
                                    const Text('N° Série : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        equipment['serialNumber']?.toString() ??
                                            'Non spécifié'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 150,
                      ),
                      padding: const EdgeInsets.all(10),
                      itemCount: equipments.length,
                      itemBuilder: (context, index) {
                        final equipment =
                            equipments[index].data() as Map<String, dynamic>;
                        return Card(
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        equipment['name']?.toString() ?? 'Sans nom',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Type: ${equipment['type']?.toString() ?? 'Non spécifié'}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 126, 5, 239),
                                  ),
                                ),
                                Text(
                                  'Modèle: ${equipment['model']?.toString() ?? 'Non spécifié'}',
                                ),
                                Text(
                                  'Marque: ${equipment['manufacturer']?.toString() ?? 'Non spécifié'}',
                                ),
                                Text(
                                  'N° Série: ${equipment['serialNumber']?.toString() ?? 'Non spécifié'}',
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
            }));
  }
}