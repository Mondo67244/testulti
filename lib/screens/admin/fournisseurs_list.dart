import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_parc_informatique/screens/admin/admin_dashboard.dart';

class FournisseursList extends StatefulWidget {
  const FournisseursList({super.key});

  @override
  _FournisseursListState createState() => _FournisseursListState();
}

class _FournisseursListState extends State<FournisseursList> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late TabController _tabController;
  final List<String> categories = const ['Sécurité', 'Bureau', 'Échange', 'Réseau'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminDashboard()),
                        ),
        ),
        title: const Text('Liste des Fournisseurs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((category) => Tab(text: category)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Fournisseur')
                .where('category', isEqualTo: category)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Erreur de chargement des fournisseurs.'));
              }

              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('Aucun fournisseur trouvé.'));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth <= 918;
                  final crossAxisCount = isSmallScreen ? 1 : (isMediumScreen ? 2 : 3);
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: isSmallScreen ? 2.5 : (isMediumScreen ? 2.0 : 1.8),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 150,
                    ),
                    itemCount: users.length,
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                    itemBuilder: (context, index) {
                      DocumentSnapshot userDoc = users[index];
                  Map<String, dynamic> user = userDoc.data() as Map<String, dynamic>;

                      return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Commander un produit'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'Titre de la commande'),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(labelText: 'Description de la commande'),
                                  maxLines: 3,
                                  maxLength: 125,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Annuler'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: const Text('Commander'),
                                onPressed: () {
                                  // Envoyer les données de commande à admin_orders_list.dart
                                  final title = _titleController.text;
                                  final equipmentName = title;
                                  final description = _descriptionController.text;
                                  FirebaseFirestore.instance.collection('commandes').add({
                                    'title': equipmentName,
                                    'description': description,
                                    'supplierId': userDoc.id,
                                    'timestamp': DateTime.now(),
                                  }).then((_) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Commande envoyée avec succès'),
                                    backgroundColor: Colors.green,
                                    ),
                                  );
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                user['name'] ?? 'Nom inconnu',
                                style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _infoRow(Icons.email, 'Email', user['email']),
                          _infoRow(Icons.work, 'Fonction', user['function']),
                          _infoRow(Icons.business, 'Département', user['department']),
                          _infoRow(Icons.phone, 'Téléphone', user['phoneNumber']),
                        ],
                      ),
                    ),
                  ),
                  );
                    },
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }

  /// Fonction pour afficher une ligne d'information avec une icône
  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ${value ?? 'Non renseigné'}'),
      ],
    );
  }
}