import 'package:flutter/material.dart';
import 'package:gestion_parc_informatique/screens/admin/activity_list.dart';
import 'package:gestion_parc_informatique/screens/admin/reports_list.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import 'equipment_list.dart';
import 'employee_list.dart';
import 'task_list.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const EquipmentList(),
    const EmployeeList(),
    const TaskList(),
    const ActivityList(),
    const ReportsListScreen(),
  ];

  final List<String> _titles = [
    'Équipements',
    'Employés',
    'Tâches',
    'Activités',
    'Rapports',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
      return const SizedBox.shrink();
    }

    return Scaffold(
      key: _scaffoldKey,
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
                  Text('Gérer vos appareils avec aise',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.computer),
              title: const Text('Équipements'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Employés'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Tâches'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Activités'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Rapports'),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Fournisseurs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.routeFournisseurs);
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
      backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color.fromARGB(221, 255, 255, 255)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeAllUserInfos);
              }),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.routeFournisseurs);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmation'),
                  content:
                      const Text('Voulez-vous vraiment vous déconnecter ?'),
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
                await Provider.of<AuthService>(context, listen: false)
                    .signOut(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          iconSize: 20,
          elevation: 4,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.computer),
              label: 'Équipements',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Employés',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Tâches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Activités',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Rapports',
            ),
          ],
        ),
      ),
    );
  }
}
