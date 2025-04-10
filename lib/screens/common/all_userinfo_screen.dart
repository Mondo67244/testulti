import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_parc_informatique/screens/Utilisateur/complete_profile_screen_user.dart';

class ProfilUtilisateur extends StatelessWidget {
  const ProfilUtilisateur({super.key});

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
        final location = userData['location'] ?? '';
        final role = userData['role'] ?? '';
        final email = userData['email'] ?? '';
        final phoneNumber = userData['phoneNumber'] ?? '';
        final department = userData['department'] ?? '';
        final function = userData['function'] ?? '';

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 240, 232, 255),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Informations sur vous ($name)'),
          ),
          
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400,maxHeight: 400),
                  child: Card(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const SizedBox(width: 30),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Informations personnelles',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E15C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.people_alt_outlined,
                                    color: Colors.black87,
                                    ),
                                const SizedBox(width: 10),
                                const Text('Nom : ',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0)))
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.email_outlined,
                                    color: Colors.black87),
                                const SizedBox(width: 10),
                                const Text('Email Personnel : ',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                Text(email,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0)))
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.phone_outlined,
                                    color: Colors.black87),
                                const SizedBox(width: 10),
                                const Text('Numéro de télephone : ',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                Text(phoneNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0)))
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const SizedBox(width: 30),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Informations professionnelles',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E15C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.business_outlined),
                                const SizedBox(width: 10),
                                const Text("Département :",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text(department,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0)))
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.work_outline),
                                const SizedBox(width: 10),
                                const Text("Fonction :",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text(function,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0)))
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.location_on_outlined),
                                const SizedBox(width: 10),
                                const Text("Emplacement",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text(location,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E15C0))),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                const Icon(Icons.verified_user_outlined),
                                const SizedBox(width: 10),
                                const Text("Role :",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 80, 79, 79),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Text(role,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 214, 13, 46))),
                              ],
                            ),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            focusElevation: 10,
            focusColor: Theme.of(context).primaryColor.withOpacity(0.05),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionScreen(),
                ),
              );
            },
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
}
