//cette page fournit les constantes de l'application
import 'package:flutter/material.dart';

class AppConstants {
  // Nom de l'application
  static const String appName = 'Gestion du Parc Informatique';

  // Clé API Firebase Web
  static const String firebaseWebApiKey =
      'AIzaSyCpPPjrNffXTRwEmOf-goojdWi4yJVkXIw';

  // Collections Firestore
  static const String usersCollection = 'users';
  static const String pendingUsersCollection = 'pending_users';
  static const String equipmentCollection = 'equipment';
  static const String reportsCollection = 'reports';
  static const String maintenanceTasksCollection = 'maintenance_tasks';
  static const String actionsCollection = 'maintenance_actions';
  static const String activitiesCollection = 'activities';

  // Rôles utilisateurs
  static const String roleAdmin = 'Admin';
  static const String roleTechnician = 'Maintenancier';
  static const String roleSupplier = 'Fournisseur';
  static const String roleUtilisateur = 'Utilisateur';

  // États des équipements
  static const List<String> equipmentStates = [
    'Bon état',
    'En panne',
  ];

  // Statuts des équipements
  static const List<String> equipmentStatuses = [
    'En maintenance',
    'En Remplacement',
    'En retrait',
  ];

//titres dans les pages:
  ///
  ///Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.05),borderRadius: BorderRadius.circular(8),border: Border.all(color:Theme.of(context).primaryColor.withOpacity(0.1),width: 1,),),child: const Text('Informations techniques',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Color(0xFF4E15C0),),),),
  static const List<String> fabricants = [
    'Lenovo',
    'Toshiba',
    'D-link',
    'Hewlett Packard',
    'Dell',
    'Azus',
    'Siemens',
    'Samsung',
    'Apple',
    'Nvidia',
    'Autre',
  ];

  static const List<String> location = [
    'Accueil',
    'Salle de réunion',
    'Bureau RH',
    'Salle de présentation',
    'Atelier de formation',
    'Zone de production',
    'Zone d\'exposition',
    'Laboratoire recherche',
    'Salle d\'attente',
    'Bureau Juridique',
    'Entrepôt d\'équipements',
    'Magasin de fournitures',
    'Bureau du personnel',
  ];

  //État des rapports
  static const List<String> etat = [
    'En attente',
    'En cours',
    'Terminé',
  ];

  // Catégories d'équipements
  static const List<String> equipmentCategories = [
    'Bureau',
    'Reseau',
    'Échange',
    'Sécurité',
  ];

// Types d'appareils
  static const List<String> materials = [
    'Ordinateur',
    'Modem',
    'Alarme',
    'Souris',
    'Camera',
    'Haut parleur',
    'Écouteurs',
    'Écran',
  ];

  // Statuts des rapports
  static const Map<String, String> reportStatuses = {
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminé',
  };

  // Types de maintenance
  static const Map<String, String> maintenanceTypes = {
    'preventive': 'Préventive',
    'corrective': 'Corrective',
    'upgrade': 'Mise à niveau',
    'installation': 'Installation',
    'replacement': 'Remplacement',
  };

  // Statuts des tâches
  static const Map<String, String> taskStatuses = {
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminé',
    'rejected': 'Rejetée',
  };

  // Couleurs des statuts des tâches
  static final Map<String, Color> taskStatusColors = {
    'pending': Colors.orange,
    'in_progress': Colors.blue,
    'completed': Colors.green,
    'rejected': Colors.red,
    'cancelled': Colors.grey,
  };

  // Catégories d'activités
  static const Map<String, String> activityCategories = {
    'equipment': 'Équipements',
    'employee': 'Employés',
    'task': 'Tâches',
    'report': 'Rapports',
    'system': 'Système',
  };

  // Couleurs des états des équipements
  static final Map<String, Color> equipmentStateColors = {
    'Bon état': Colors.green,
    'En panne': Colors.red,
  };

  // Types d'activités
  static const Map<String, Map<String, String>> activityTypes = {
    'equipment': {
      'equipmentCreated': 'Création d\'équipement',
      'equipmentUpdated': 'Modification d\'équipement',
      'equipmentDeleted': 'Suppression d\'équipement',
      'equipmentStateChanged': 'Changement d\'état d\'équipement',
      'equipmentStatusChanged': 'Changement de statut d\'équipement',
    },
    'employee': {
      'employeeCreated': 'Création d\'employé',
      'employeeUpdated': 'Modification d\'employé',
      'employeeDeleted': 'Suppression d\'employé',
      'employeeLogin': 'Connexion d\'employé',
      'employeeLogout': 'Déconnexion d\'employé',
    },
    'task': {
      'taskCreated': 'Création de tâche',
      'taskUpdated': 'Modification de tâche',
      'taskDeleted': 'Suppression de tâche',
      'taskAssigned': 'Assignation de tâche',
      'taskStatusChanged': 'Changement de statut de tâche',
    },
    'report': {
      'reportSubmitted': 'Soumission de rapport',
      'reportUpdated': 'Modification de rapport',
      'reportStatusChanged': 'Changement de statut de rapport',
    },
    'system': {
      'systemAction': 'Action système',
    },
  };

  // Messages d'erreur
  static const String errorGeneral = 'Une erreur est survenue';
  static const String errorConnection = 'Erreur de connexion';
  static const String errorPermission =
      'Vous n\'avez pas les permissions nécessaires';
  static const String errorNotFound = 'Ressource non trouvée';
  static const String errorAuthentication = 'Erreur d\'authentification';
  static const String errorUserNotFound = 'Utilisateur non trouvé';
  static const String errorEquipmentNotFound = 'Équipement non trouvé';
  static const String errorInvalidData = 'Données invalides';
  static const String errorUnknown = 'Une erreur inconnue est survenue';

  // Messages de succès
  static const String successSave = 'Enregistrement réussi';
  static const String successUpdate = 'Mise à jour réussie';
  static const String successDelete = 'Suppression réussie';

  // Routes nommées
  static const String routeLogin = '/login';
  static const String routeActivityList = '/Activity';
  static const String routeAdminDashboard = '/admin';
  static const String routeEmployeeDashboard = '/employee';
  static const String routeEmployeeList = '/admin/employee-list';
  static const String routeEquipmentForm = '/equipment/form';
  static const String routeReportForm = '/report/form';
  static const String routeActionForm = '/action/form';
  static const String routeEmployeeForm = '/employee/form';
  static const String routeTaskForm = '/task/form';
  static const String routeCompleteProfile = '/complete-profile';
  static const String routeFournisseurDashboard = '/fournisseur';
  static const String routeCommandesLivrees = '/fournisseur/livrées';
  static const String routeCommandes = '/fournisseur/commandes';
  static const String routeStockfournisseur = '/fournisseur/stock';
  static const String routeFormulaireFournisseur = '/fournisseur/formulaire';
  static const String routeUtilisateurDashboard = '/utilisateur';
  static const String routeEquipmentDetails = '/employee/equipment-details';
  static const String routeLocations = '/locations';
  static const String routeFournisseurs = 'admin/fournisseurs';
  static const String routeReportList = '/admin/report-list';
  static const String routeEquipmentList = '/admin/equipment-list';
  static const String routeAllUserInfos = '/user-info';
}
