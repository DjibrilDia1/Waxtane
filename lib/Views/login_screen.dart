import 'package:flutter/material.dart';
import '../Services/auth_services.dart';
import '../Views/user_list_screen.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Connexion avec Firebase Auth via AuthService
      String res = await _auth.loginUser(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (res == "success") {
        if (!mounted) return;

        // Redirection vers la liste des utilisateurs
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const UsersListScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          String errorMsg = res;
          // Traduire les messages d'erreur Firebase
          if (res.contains('invalid-email')) {
            errorMsg = 'Email invalide.';
          } else if (res.contains('user-not-found')) {
            errorMsg = 'Utilisateur introuvable.';
          } else if (res.contains('wrong-password')) {
            errorMsg = 'Mot de passe incorrect.';
          } else if (res.contains('user-disabled')) {
            errorMsg = 'Compte désactivé.';
          } else if (res.contains('invalid-credential')) {
            errorMsg = 'Email ou mot de passe incorrect.';
          } else if (res.contains('Rentrer tous les champs')) {
            errorMsg = 'Veuillez remplir tous les champs.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: size.width * 0.35,
                  height: size.width * 0.35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AB78D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF3AB78D),
                    size: 72,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bienvenue',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3AB78D),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connectez-vous pour continuer',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "L'email est requis";
                    }
                    if (!value.contains('@')) {
                      return 'Entrez un email valide';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration(
                    hint: 'Email',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                  decoration: _fieldDecoration(
                    hint: 'Mot de passe',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AB78D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte ?'),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: Color(0xFF3AB78D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}