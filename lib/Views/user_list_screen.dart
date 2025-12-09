// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _currentUser = FirebaseAuth.instance.currentUser;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  // Charger le nom de l'utilisateur connecté
  Future<void> _loadCurrentUserName() async {
    try {
      if (_currentUser?.email != null) {
        final encodedEmail = _encodeEmail(_currentUser!.email!);
        final snapshot = await _database.child('users/$encodedEmail').get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _currentUserName = data['username']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      print('Erreur chargement nom: $e');
    }
  }

  String _encodeEmail(String email) {
    return email
        .toLowerCase()
        .replaceAll('.', ',')
        .replaceAll('@', '_at_')
        .replaceAll('#', '_hash_')
        .replaceAll('\$', '_dollar_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: Text(
          'Voulez-vous vraiment vous déconnecter, ${_currentUserName.isNotEmpty ? _currentUserName : "utilisateur"} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3AB78D),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentUserName.isNotEmpty)
              Text(
                'Connecté en tant que $_currentUserName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          // Avatar de l'utilisateur connecté
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton(
              offset: const Offset(0, 50),
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _currentUserName.isNotEmpty 
                      ? _currentUserName[0].toUpperCase()
                      : (_currentUser?.email?[0].toUpperCase() ?? 'U'),
                  style: const TextStyle(
                    color: Color(0xFF3AB78D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUserName.isNotEmpty 
                            ? _currentUserName 
                            : 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: _logout,
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _database.child('users').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          
          if (data == null || data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun utilisateur disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Convertir en liste et filtrer l'utilisateur courant
          final users = data.entries
              .where((entry) {
                final userData = entry.value as Map<dynamic, dynamic>;
                final email = userData['email']?.toString().toLowerCase();
                return email != _currentUser?.email?.toLowerCase();
              })
              .map((entry) {
                final userData = entry.value as Map<dynamic, dynamic>;
                return {
                  'email': userData['email']?.toString() ?? 'Email inconnu',
                  'name': userData['username']?.toString() ?? 'Utilisateur',
                };
              })
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun autre utilisateur',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invitez vos amis à rejoindre !',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Carte d'information
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3AB78D), Color(0xFF2E9E75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3AB78D).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        _currentUserName.isNotEmpty 
                            ? _currentUserName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFF3AB78D),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUserName.isNotEmpty 
                                ? 'Bienvenue, $_currentUserName !' 
                                : 'Bienvenue !',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'En ligne',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Section titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Utilisateurs disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AB78D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${users.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Liste des utilisateurs
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userEmail = user['email'] as String;
                    final userName = user['name'] as String;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF3AB78D),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3AB78D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble,
                          color: Color(0xFF3AB78D),
                          size: 20,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentEmail: _currentUser!.email!,
                              contactEmail: userEmail,
                              contactName: userName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}