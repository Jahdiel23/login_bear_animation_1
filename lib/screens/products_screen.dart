import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<dynamic>> _productsFuture;

  // Dirección del backend desde el emulador Android
  final String apiUrl = 'http://10.0.2.2:8081/products';

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Error al obtener productos: ${response.statusCode}',
      );
    }
  }

  void _retry() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No se pudieron cargar los productos.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text('No hay productos disponibles.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index] as Map<String, dynamic>;

            final category = product['category']?['category']
                ?? 'Sin categoría';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(product['name'] ?? 'Sin nombre'),
                subtitle: Text(
                  'Categoría: $category\n'
                  'Precio: \$${product['price']}\n'
                  'Existencias: ${product['stock']}',
                ),
                isThreeLine: true,
                trailing: Text('#${product['productId']}'),
              ),
            );
          },
        );
      },
    );
  }
}
