import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                // Se cierra la sesión en Firebase, AuthGate detecta el cambio y muestra el login
                await FirebaseAuth.instance.signOut();
              } on FirebaseAuthException {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo cerrar sesión.')),
                );
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Center(child: Text('Hola, ${user?.email ?? ''} 🐻')),
    );
  }
}