import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //Uso esta llave para validar todos los campos del formulario
  final _formKey = GlobalKey<FormState>();
  //Los controladores me permiten leer el correo  y la contraseña escritos
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();

  bool _registrando = false;

  Future<void> _crearCuenta() async {
    // Valido los campos antes de enviar los datos a Firebase.
    if (_registrando || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    //Desactivo el botón mientras se crea la cuenta para evitar envios dobles.
    setState(() => _registrando = true);

    try {
      // Firebase crea la cuenta e inicia sesión automáticamente.
      //Envio el correo y la contraseña a firebase para crear la cuenta
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _claveController.text,
      );

      if (!mounted) return;

      // Cierro el registro para mostrar Inicio, gestionado por AuthGate.
      //Cierro el formulaio para que se vea inicio, que authgate muestra al detectar la sesión.
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

//Muestro un mensaje según el error que devuelve Firebase
      final mensaje = switch (error.code) {
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'weak-password' => 'Elige una contraseña más segura.',
        'invalid-email' => 'Escribe un correo válido.',
        'network-request-failed' => 'Revisa tu conexión e inténtalo de nuevo.',
        _ => 'No se pudo crear la cuenta. Inténtalo de nuevo.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  @override
  //Libero los controladores cuando se cierra la pantalla
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _correoController,
                enabled: !_registrando,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator: (value) {
                  final correo = (value ?? '').trim();
                  if (correo.isEmpty) return 'Escribe tu correo.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(correo)) {
                    return 'Escribe un correo válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _claveController,
                enabled: !_registrando,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) {
                  final clave = value ?? '';
                  final formato = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).{8,}$',
                  );
                  if (!formato.hasMatch(clave)) {
                    return 'Usa 8 caracteres o más, con mayúscula, '
                        'minúscula, número y símbolo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _registrando ? null : _crearCuenta,
                child: Text(_registrando ? 'Creando cuenta…' : 'Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}