import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isFromSupplierStock;
  const EquipmentForm({Key? key, this.initialData, this.isFromSupplierStock = false}) : super(key: key);

  @override
  State<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _responsibleDepartmentController = TextEditingController();

  String _selectedCategory = AppConstants.equipmentCategories.first;
  String _selectedState = AppConstants.equipmentStates.first;
  String _selectedType = AppConstants.materials.first;
  String? _selectedLocation;

  DateTime _purchaseDate = DateTime.now();
  DateTime _installationDate = DateTime.now();

  bool _isLoading = false;

  Map<String, String> _suppliers = {};
  String? _selectedSupplier;
  String _fabricants = AppConstants.fabricants.first;

  final List<String> _location = [
    'Accueil',
    'Salle de réunion',
    'Salle de présentation',
    'Atelier de formation',
    'Bureau des ressources humaines',
    'Zone de production',
    'Zone d\'exposition',
    'Laboratoire de recherche et de développement',
    'Salle d\'attente',
    'Bureau du service juridique',
    'Entrepôt d\'équipements',
    'Magasin de fournitures',
    'Bureau du personnel',
  ];



  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name']?.toString() ?? '';
      _descriptionController.text = widget.initialData!['description']?.toString() ?? '';
      _serialNumberController.text = widget.initialData!['serialNumber']?.toString() ?? '';
      _modelController.text = widget.initialData!['model']?.toString() ?? '';
      _selectedType = widget.initialData!['type']?.toString() ?? AppConstants.materials.first;
      _fabricants = widget.initialData!['manufacturer']?.toString() ?? AppConstants.fabricants.first;
    }
  }

  Future<void> _fetchSuppliers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Fournisseur')
          .get();
      setState(() {
        _suppliers = Map.fromIterable(
          querySnapshot.docs,
          key: (doc) => doc['name'] as String,
          value: (doc) => doc['department'] as String,
        );
      });
    } catch (e) {
      print('Error fetching suppliers: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _responsibleDepartmentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!widget.isFromSupplierStock) return true;
    
    bool shouldPop = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attention'),
        content: const Text('Voulez-vous vraiment quitter sans enregistrer cet équipement ? Les informations seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    ) ?? false;

    return shouldPop;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Nouvel équipement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    // Informations générales
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'équipement *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        prefixIcon: const Icon(Icons.computer, size: 20),
                        labelStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Numéro de série
                    TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de série *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de série';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConstants.equipmentCategories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Genre
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Genre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.merge_type),
                      ),
                      items: AppConstants.materials
                          .map((material) => DropdownMenuItem(
                                value: material,
                                child: Text(material),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //localisation
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Emplacement',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_pin),
                      ),
                      value: _selectedLocation,
                      hint: const Text('Sélectionnez l\'emplacement'),
                      items: _location
                          .map((location) => DropdownMenuItem(
                                value: location,
                                child: Text(location),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez la localisation de l\'équipement';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // État
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'État *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.health_and_safety),
                      ),
                      items: AppConstants.equipmentStates
                          .map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedState = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Informations techniques
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Informations techniques',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fabriquants
                    DropdownButtonFormField<String>(
                      value: _fabricants,
                      decoration: const InputDecoration(
                        labelText: 'Fabricant *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.maps_home_work_outlined),
                      ),
                      items: AppConstants.fabricants
                          .map((fabricants) => DropdownMenuItem(
                                value: fabricants,
                                child: Text(fabricants),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _fabricants = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Modèle
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Modèle *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.devices),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un modèle';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fournisseur
                    DropdownButtonFormField<String>(
                      value: _selectedSupplier,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _suppliers.keys
                          .map((supplier) => DropdownMenuItem(
                                value: supplier,
                                child: Text(supplier),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupplier = value;
                          if (value != null) {
                            _responsibleDepartmentController.text =
                                _suppliers[value]!;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un fournisseur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Département responsable
                    TextFormField(
                      controller: _responsibleDepartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Département responsable *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      readOnly: _selectedSupplier != null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un département responsable';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dates
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Dates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E15C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date d'achat
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'achat *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_purchaseDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date d'installation
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'installation *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_installationDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton de soumission
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Enregistrer l\'équipement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),));
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPurchaseDate ? _purchaseDate : _installationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _installationDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final equipmentService =
            Provider.of<EquipmentService>(context, listen: false);

        // Récupérer l'ID et les données du stock si disponibles
        final String? stockId = widget.initialData?['stockId'];
        final Map<String, dynamic>? stockEquipmentData = widget.initialData?['equipmentData'];

        // Créer un nouvel équipement
        final equipment = Equipment(
          id: '',
          name: _nameController.text,
          description: _descriptionController.text,
          serialNumber: _serialNumberController.text,
          category: _selectedCategory,
          type: _selectedType,
          location: _selectedLocation ?? '',
          status:'',
          state: _selectedState,
          manufacturer: _fabricants,
          model: _modelController.text,
          supplier: _selectedSupplier ?? '',
          responsibleDepartment: _selectedSupplier ?? '',
          purchaseDate: _purchaseDate,
          installationDate: _installationDate,
          errorHistory: [],
          maintenanceHistory: [],
          specifications: {},
        );

        // Enregistrer l'équipement dans Firestore
        await equipmentService.addEquipment(equipment, 'Admin');

        // Si l'équipement provient du stock, le déplacer vers les commandes livrées
        if (stockId != null && stockEquipmentData != null) {
          // Supprimer l'équipement du stock
          await FirebaseFirestore.instance
              .collection('stock')
              .doc(stockId)
              .delete();

          // Ajouter l'équipement aux commandes livrées
          await FirebaseFirestore.instance
              .collection('commandelivr')
              .add({
                ...stockEquipmentData,
                'dateReception': DateTime.now(),
              });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Équipement créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        print('Erreur lors de la création de l\'équipement: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('Formulaire invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
