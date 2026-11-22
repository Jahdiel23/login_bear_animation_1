import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'products_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                // Cerrar sesión en Firebase
                await FirebaseAuth.instance.signOut();
              } on FirebaseAuthException {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo cerrar sesión.'),
                  ),
                );
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Hola, ${user?.email ?? ''} 🐻',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: ProductsScreen(),
          ),
        ],
      ),
    );
  }
}
