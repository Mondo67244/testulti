import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart';
import 'package:gestion_parc_informatique/screens/Utilisateur/locations_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

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

class UtilisateurDashboard extends StatefulWidget {
  final String userId;

  const UtilisateurDashboard({required this.userId, super.key});

  @override
  _UtilisateurDashboardState createState() => _UtilisateurDashboardState();
}

class _UtilisateurDashboardState extends State<UtilisateurDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      MesRapports(userId: widget.userId),
      const LocationsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //Bouton de déconnexion
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 2,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion',style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AuthService>(context, listen: false).signOut(context);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
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
          key: _scaffoldKey,
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
                      CircleAvatar(radius: 30),
                      SizedBox(height: 10),
                      Text('Gérer vos signalements',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19)),
                      ],
                    ),
                  ),
                  ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Mes signalements faits'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Mon emplacement actuel'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mon Profil personnel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.routeAllUserInfos);
              },
            ),
                ],
              ),
            ),
            appBar: AppBar(
              title: Text('Bon retour $name !'),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color.fromARGB(221, 255, 255, 255)),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ],
            ),
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Mes signalements',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Ma zone',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        });
  }
}

class MesRapports extends StatefulWidget {
  final String userId;

  const MesRapports({required this.userId, super.key});

  @override
  _MesRapportsState createState() => _MesRapportsState();
}

class _MesRapportsState extends State<MesRapports> {
  @override
  Widget build(BuildContext context) {
    const role = 'Utilisateur';
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data?.docs.isEmpty ?? true) {
          return const Center(child: Text('Aucun rapport disponible.'));
        }
        
        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;

            String equipmentName =
                data['equipmentName'] ?? 'Équipement inconnu';
            String reportedBy = data['reportedBy'] ?? 'Utilisateur inconnu';
            String location = data['location'] ?? 'Utilisateur inconnu';
            String type = data['type'] ?? ' inconnue';
            String description =
                data['description'] ?? 'Aucune description disponible';
            String dateFormatted = 'Date inconnue';

            if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
              dateFormatted = DateFormat('dd/MM/yyyy HH:mm')
                  .format(data['timestamp'].toDate());
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                title: Column(
                  children: [
                    const Text('Signalement fait sur l\'équipement: ',style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(type+' '+equipmentName,style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.deepPurple)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.computer,color: Colors.black87),
                      const SizedBox(width: 5,),
                      Text('Type d\'appareil: ',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey[600]),),
                      Text(type,style: const TextStyle(fontWeight: FontWeight.bold,color:Color.fromARGB(186, 104, 58, 183))),
                    ]
                      ),
                    Row(children: [
                      const Icon(Icons.location_on,color: Colors.black87),
                      const SizedBox(width: 5,),
                     Text('Lieu d\'envoi: ',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey[600])),
                      Text(location,style: const TextStyle(color: Color.fromARGB(186, 76, 175, 79),fontWeight: FontWeight.bold),)
                    ],)
                      ,
                    Row(children: [
                      const Icon(Icons.calendar_month,color: Colors.black87),
                      const SizedBox(width: 5,),
                      Text('Date d\'envoi: ',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey[600])),
                      Text(dateFormatted)
                    ]),
                    Row(children: [
                      const Icon(Icons.description,color: Colors.black87),
                      const SizedBox(width: 5,),
                      Text('Message Envoyé: ',maxLines: 3,style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey[600])),
                      Text('" $description "')
                    ]),
                    Row(children: [
                      const Icon(Icons.person,color: Colors.black87),
                      const SizedBox(width: 5,),
                      Text('Signalé par : ',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey[600])),
                      Text(reportedBy,style: const TextStyle(fontWeight: FontWeight.bold,color: Color.fromARGB(186, 244, 67, 54)),)
                    ]),
                  ],
                ),
                onTap: () {
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

