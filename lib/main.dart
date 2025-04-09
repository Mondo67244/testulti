import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_parc_informatique/constants/app_constants.dart';
import 'package:gestion_parc_informatique/screens/Fournisseur/commandes_livr%C3%A9es.dart';
import 'package:gestion_parc_informatique/screens/Fournisseur/commandes_recentes.dart';
import 'package:gestion_parc_informatique/screens/Fournisseur/fournisseur_dashboard.dart';
import 'package:gestion_parc_informatique/screens/Utilisateur/locations_screen.dart';
import 'package:gestion_parc_informatique/screens/admin/employee_list.dart';
import 'package:gestion_parc_informatique/screens/admin/equipment_list.dart';
import 'package:gestion_parc_informatique/screens/admin/fournisseurs_list.dart';
import 'package:gestion_parc_informatique/screens/admin/reports_list.dart';
import 'package:gestion_parc_informatique/screens/common/all_userinfo_screen.dart';
import 'package:provider/provider.dart';
import 'package:gestion_parc_informatique/firebase_options.dart';
import 'package:gestion_parc_informatique/services/auth_service.dart';
import 'package:gestion_parc_informatique/services/equipment_service.dart';
import 'package:gestion_parc_informatique/services/employee_service.dart';
import 'package:gestion_parc_informatique/services/maintenance_task_service.dart';
import 'package:gestion_parc_informatique/services/activity_service.dart';
import 'package:gestion_parc_informatique/services/report_service.dart';
import 'package:gestion_parc_informatique/screens/login_screen.dart';
import 'package:gestion_parc_informatique/screens/admin/admin_dashboard.dart';
import 'package:gestion_parc_informatique/screens/employee/employee_dashboard.dart';
import 'package:gestion_parc_informatique/services/firestore_init_service.dart';
import 'package:gestion_parc_informatique/screens/common/complete_profile_screen.dart';
import 'package:gestion_parc_informatique/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_parc_informatique/screens/Utilisateur/utilisateur_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userData = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    final role = userData['role'] ?? '';
    if (role == AppConstants.roleAdmin) {
      runApp(const MyApp(initialRoute: AppConstants.routeAdminDashboard));
    } else if (role == AppConstants.roleSupplier) {
      runApp(const MyApp(initialRoute: AppConstants.routeFournisseurDashboard));
    } else if (role == AppConstants.roleTechnician) {
      runApp(const MyApp(initialRoute: AppConstants.routeEmployeeDashboard));
    } else if (role == AppConstants.roleUtilisateur) {
      runApp(const MyApp(initialRoute: AppConstants.routeUtilisateurDashboard));
    } else {
      runApp(const MyApp(initialRoute: AppConstants.routeLogin));
    }
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  final String? initialRoute;

  const MyApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<EquipmentService>(create: (_) => EquipmentService()),
        Provider<EmployeeService>(create: (_) => EmployeeService()),
        Provider<MaintenanceTaskService>(
            create: (_) => MaintenanceTaskService()),
        Provider<ActivityService>(create: (_) => ActivityService()),
        Provider<ReportService>(create: (_) => ReportService()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        Provider<FirestoreInitService>(
          create: (_) {
            final service = FirestoreInitService();
            service.initializeCollections();
            return service;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 78, 21, 192),
            primary: const Color.fromARGB(255, 78, 21, 192),
            secondary: const Color.fromARGB(255, 27, 98, 159),
            tertiary: const Color.fromARGB(255, 253, 33, 33),
            surface: Colors.grey.shade50,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color.fromARGB(255, 78, 21, 192),
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 78, 21, 192),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 78, 21, 192), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(color: Colors.grey),
            floatingLabelStyle: const TextStyle(
              color: Color.fromARGB(255, 78, 21, 192),
              fontWeight: FontWeight.bold,
            ),
          ),
          fontFamily: 'Lato',
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontFamily: 'Lato',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 78, 21, 192),
            ),
            titleMedium: TextStyle(
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Lato',
              fontSize: 16,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Lato',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color.fromARGB(255, 78, 21, 192),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          tabBarTheme: const TabBarTheme(
            labelColor: Color.fromARGB(255, 78, 21, 192),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color.fromARGB(255, 78, 21, 192),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        initialRoute: initialRoute ?? '/',
        routes: {
          '/': (context) => const HomeScreen(),
          AppConstants.routeLogin: (context) => const LoginScreen(),
          AppConstants.routeAdminDashboard: (context) => const AdminDashboard(),
          AppConstants.routeEmployeeDashboard: (context) =>
              const EmployeeDashboard(),
          AppConstants.routeEmployeeList: (context) => const EmployeeList(),
          AppConstants.routeCompleteProfile: (context) =>
              ProfileCompletionScreen(),
          AppConstants.routeCommandesLivrees: (context) => const SupplierOrdersList(),
          AppConstants.routeCommandes: (context) => const AdminOrdersList(),
          //AppConstants.routeStockfournisseur: (context) => const,
          //AppConstants.routeFormulaireFournisseur: (context) => const,
          AppConstants.routeReportList: (context) => ReportsListScreen(),
          AppConstants.routeFournisseurDashboard: (context) =>
              const FournisseurDashboard(),
          AppConstants.routeEquipmentList: (context) => const EquipmentList(),
          AppConstants.routeLocations: (context) => LocationsScreen(),
          AppConstants.routeAllUserInfos: (context) =>
              const ProfilUtilisateur(),
          AppConstants.routeUtilisateurDashboard: (context) =>
              UtilisateurDashboard(
                  userId: FirebaseAuth.instance.currentUser!.uid),
          AppConstants.routeFournisseurs: (context) => FournisseursList(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'] ?? '';
            final isProfileComplete = userData['isProfileComplete'] ?? false;

            if ((role == AppConstants.roleTechnician ||
                    role == AppConstants.roleSupplier ||
                    role == AppConstants.roleUtilisateur) &&
                !isProfileComplete) {
              return ProfileCompletionScreen();
            } else if (role == AppConstants.roleAdmin) {
              return const AdminDashboard();
            } else if (role == AppConstants.roleSupplier) {
              return const FournisseurDashboard();
            } else if (role == AppConstants.roleTechnician) {
              return const EmployeeDashboard();
            } else if (role == AppConstants.roleUtilisateur) {
              return UtilisateurDashboard(userId: user.uid);
            }
          }
          return const LoginScreen();
        },
      );
    } else {
      return const LoginScreen();
    }
  }
}
