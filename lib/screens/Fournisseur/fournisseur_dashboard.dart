import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'commandes_recentes.dart'; // Importer le fichier pour les commandes administratives
import 'commandes_livrées.dart'; // Importer le fichier pour les commandes du fournisseur
import 'equipment_form_fournisseur.dart';
import 'stock_list.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';

class FournisseurDashboard extends StatefulWidget {
  const FournisseurDashboard({Key? key}) : super(key: key);

  @override
  _FournisseurDashboardState createState() => _FournisseurDashboardState();
}

class _FournisseurDashboardState extends State<FournisseurDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminOrdersList(), // Écran pour les commandes passées par l'administrateur
    const SupplierOrdersList(), // Écran pour les commandes livrées
    const StockList(), // Écran pour la liste des stocks
    const EquipmentForm(), // Écran pour ajouter au stock
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<AuthService>(context, listen: false).signOut(context);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!;
          final name = userData['name'] ?? '';

      return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 240, 232, 255),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  CircleAvatar(
                    radius: 30,
                  ),
                  SizedBox(height: 10),
                  Text('Gérer les commandes',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19),),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chrome_reader_mode_outlined),
              title: const Text('Commandes Récentes'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_outlined),
              title: const Text('Commandes Livrées'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: const Text('Equipement en stock'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Ajouter des équipements'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_outlined),
              title: const Text('Mon profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.routeAllUserInfos);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Bienvenue $name'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _signOut, // Appel de la méthode de déconnexion
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chrome_reader_mode_outlined),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Livrées',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory_outlined),
            label: 'En stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business_outlined),
            label: 'Ajouter au stock',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 110, 2, 177),
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: const TextStyle(color: Colors.grey),
        onTap: _onItemTapped,
      ),
    );
  }
);
  }
  }