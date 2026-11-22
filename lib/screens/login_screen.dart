import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'signup_screen.dart';
import 'dart:async'; // 3.1 Importar el timer
import 'package:firebase_auth/firebase_auth.dart'; //Conectando el botón con firebase

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSignInInProgress});

final ValueChanged<bool>? onSignInInProgress;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  //Estado local para la opción "Remember me"
  bool _rememberMe = false;

  // Bandera (flag) Anti-Spam para bloquear interacción rápida
  bool _isLoading = false;

  // 1.1 Crear el cerebro de la animación
  StateMachineController? _controller;

  // SMI: State Machine Input / Entrada de máquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // 4.1 Controllers que manipulan lo que el usuario escribe (corregidos con guion bajo)
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // 4.2 Errores para mostrarlos en la UI
  String? emailError;
  String? passError;

//Reviso el formato de los campos antes de enviar los datos a Firebase
  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return re.hasMatch(pass);
  }

  // 4.4 Dar acción al botón
  Future<void> _recuperarContrasena() async {
    if (_isLoading) return;

    final formulario = GlobalKey<FormState>();
    var correo = _emailCtrl.text.trim();

    // Abro una ventana para que el usuario confirme o cambie su correo
    final confirmado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Form(
          key: formulario,
          child: TextFormField(
            initialValue: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            onChanged: (value) => correo = value.trim(),
            validator: (value) => isValidEmail((value ?? '').trim())
                ? null
                : 'Escribe un correo válido.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              //Reviso que el correo tenga un formato válido antes de continuar
              if (formulario.currentState!.validate()) {
                Navigator.of(dialogContext).pop(correo);
              }
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );

    if (!mounted || confirmado == null || _isLoading) return;
    setState(() => _isLoading = true);

    const confirmacion = 'Si hay una cuenta con ese correo, recibirás un '
        'enlace. Revisa tu bandeja de entrada y spam.';
    var mensaje = confirmacion;
    try {
      // Le pido a Firebase que envíe al correo un enlace para cambiar la contraseña
      await FirebaseAuth.instance.sendPasswordResetEmail(email: confirmado);
    } on FirebaseAuthException catch (error) {
      mensaje = switch (error.code) {
        'user-not-found' => confirmacion,
        'network-request-failed' => 'Revisa tu conexión e inténtalo de nuevo.',
        'too-many-requests' => 'Demasiadas solicitudes. Inténtalo más tarde.',
        _ => 'No se pudo solicitar el enlace. Inténtalo de nuevo.',
      };
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    //Muestro el aviso de la solicitud o el mensaje de error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

 
  Future<void> _onLogin() async {
    // Evitar varios clics mientras se procesa el inicio de sesión
    if (_isLoading) return;

    // Obtener los datos escritos por el usuario
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // 4.6 Validar el formato de los campos
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    // 4.7 Mostrar los errores en pantalla
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // 4.8 Cerrar el teclado y actualizar la animación
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // 4.9 Si el formato es inválido, activar fallo y detenerse
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    // 5.4 Activar el indicador de carga
    setState(() {
      _isLoading = true;
    });

    // Mantener visible el login mientras se procesa
    widget.onSignInInProgress?.call(true);

    try {
      // 5.5 Esperar para que se vea el indicador de carga
      await Future.delayed(const Duration(seconds: 2));

      // Autenticar al usuario con Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      // Firebase aceptó las credenciales: celebrar con el osito
_trigSuccess?.fire();

// Dar tiempo para que se reproduzca la animación
await Future.delayed(const Duration(seconds: 2));

    } on FirebaseAuthException {
      if (!mounted) return;

      // Firebase rechazó las credenciales
      _trigFail?.fire();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar sesión.'),
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Permitir que AuthGate muestre la pantalla correspondiente
        widget.onSignInInProgress?.call(false);
      }
    }
  }


  // 2.2 Listeners (escuchadores de foco)
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        // Al tomar foco el email, el oso mira el texto y baja las manos
        _isChecking?.change(true);
        _isHandsUp?.change(false);
      } else {
        // Al perder el foco, quita la mirada activa
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      // Manos arriba si la contraseña tiene el foco y está oculta
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscure);
      } else {
        _isHandsUp?.change(false);
      }
    });
  }

  // 2.4 Liberar espacio en memoria
  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _typingDebounce?.cancel(); // 3.9 Eliminar el timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
          
                    // 1.2 Vincular animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
          
                      // 1.3 Verificar que inició bien
                      if (_controller == null) return;
          
                      // Agrega el controlador al escenario / tablero
                      artboard.addController(_controller!);
          
                      // Vinculamos variables de Rive
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
          
                // Espacio entre animación y campos
                const SizedBox(height: 10),
          
                // Campo de texto para Email
                TextField(
                  // 4.10 Enlazar controller
                  controller: _emailCtrl,
                  
                  // 2.3 Asignar foco al campo de texto
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      // Activar modo mirar el texto
                      _isChecking!.change(true);
          
                      // 3.6 Calcular posición de la mirada según longitud del texto (rango 0 a 100)
                      final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                      _numLook?.value = look;
          
                      // 3.7 Debounce: si vuelve a teclear, reinicia el temporizador
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        if (!mounted) return;
                        // Transcurridos 3 seg sin teclear, deshabilita la mirada activa
                        _isChecking?.change(false);
                      });
                    }
          
                    if (_isHandsUp != null) {
                      // Asegurar manos abajo en el email
                      _isHandsUp!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
          
                // Espacio entre Email y Contraseña
                const SizedBox(height: 10),
          
                // Campo de texto para contraseña
                TextField(
                  // 4.10 Enlazar controller
                  controller: _passCtrl,
                  
                  // 2.3 Asignar foco al campo de texto
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      // Taparse los ojos si la contraseña está oculta
                      _isHandsUp!.change(_obscure);
                    }
          
                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
          
                          // Si muestra la contraseña, baja las manos; si la oculta, se tapa los ojos
                          if (_isHandsUp != null) {
                            _isHandsUp!.change(_obscure);
                          }
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ), 
                const SizedBox(height: 10),
          
                // Fila con "Remember me" y "Forgot password?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null // Se inhabilita si la animación está en curso
                              : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    Flexible(
                      child: TextButton(
                        //Abro la recuperación y desactivo el boton mientras se procesa la solicitud
                        onPressed: _isLoading ? null : _recuperarContrasena,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
          
                // 4.13 Boton de login (Bloqueado temporalmente durante _isLoading)
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  disabledColor: Colors.pinkAccent.withOpacity(0.6),
                  shape: const RoundedRectangleBorder(),
                  onPressed: _isLoading ? null : _onLogin, // Se deshabilita si _isLoading == true
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () {
                              Navigator.of(context).push(
                          MaterialPageRoute<void>(
                        builder: (_) => const SignUpScreen(),
                       ),
                       );
                      },
                   child: const Text(
                   'Sign up',
                     style: TextStyle(
                    color: Colors.black,
                      decoration: TextDecoration.underline,
                       fontWeight: FontWeight.bold,
                    ),
                   ),
                   ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}