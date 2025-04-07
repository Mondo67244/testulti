import 'package:flutter/material.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart';
import 'equipment_list.dart';
import 'task_list.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/employee.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const EquipmentList(),
    const TaskList(),
  ];


Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la déconnexion'),
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
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );

  if (confirmed ?? false) {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut(context);
  }
}

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<Employee?>(
      future: authService.getCurrentEmployee(),
      builder: (context, snapshot) {
        // Nom par défaut si l'employé n'est pas encore chargé
        String employeeName = "Employé";
        
        if (snapshot.hasData && snapshot.data != null) {
          employeeName = snapshot.data!.name;
        }
        
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
                    CircleAvatar(
                    radius: 30,
                  ),
                  SizedBox(height: 10),
                      Text('Gérer les équipements',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19)),
                    ],
                  ),
                ),
                ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Mes équipements'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Mes taches'),
              onTap: () {
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
            title: Text("Bienvenue ${employeeName}"),
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color.fromARGB(221, 255, 255, 255)),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.build),
                label: 'Équipements',
              ),
              NavigationDestination(
                icon: Icon(Icons.task),
                label: 'Tâches',
              ),
            ],
          ),
        );
      }
    );
  }
}