import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/user_model.dart';
import '../models/menu_principal.dart';
import 'creditos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _palabraRecuperacionController =
      TextEditingController();
  bool _sonidoActivado = true;
  bool _mostrarContrasena = false;
  bool _cargando = false;
  bool _registrando = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _palabraRecuperacionController.dispose();
    super.dispose();
  }

  void _playSound() {
    if (_sonidoActivado) {
      _audioPlayer.play(AssetSource('sounds/softpop_sfx.mp3'));
    }
  }

  void _toggleSonido() {
    setState(() {
      _sonidoActivado = !_sonidoActivado;
    });
  }

  void _toggleMostrarContrasena() {
    _playSound();
    setState(() {
      _mostrarContrasena = !_mostrarContrasena;
    });
  }

  Future<void> _iniciarSesion() async {
    _playSound();

    final usuario = _usuarioController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    if (usuario.isEmpty || contrasena.isEmpty) {
      setState(() {
        _errorMensaje = 'Por favor, ingresa usuario y contraseña';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final exito = await UsuarioRepository.loginMaestra(usuario, contrasena);

      if (!mounted) return;
      setState(() {
        _cargando = false;
      });

      if (exito) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuPrincipal()),
        );
      } else {
        setState(() {
          _errorMensaje = 'Usuario o contraseña incorrectos';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMensaje = 'No se pudo guardar la sesión. Intenta nuevamente.';
      });
    }
  }

  Future<void> _registrarMaestra() async {
    _playSound();
    final usuario = _usuarioController.text.trim();
    final contrasena = _contrasenaController.text.trim();
    final palabraRecuperacion = _palabraRecuperacionController.text.trim();

    if (usuario.isEmpty ||
        contrasena.length < 6 ||
        palabraRecuperacion.isEmpty) {
      setState(() {
        _errorMensaje = palabraRecuperacion.isEmpty
            ? 'Ingresa una palabra de recuperación'
            : 'Ingresa un usuario y una contraseña de al menos 6 caracteres';
      });
      return;
    }
    if (UsuarioRepository.existeUsuarioMaestra(usuario)) {
      setState(() {
        _errorMensaje = 'Ese nombre de usuario ya está registrado';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final registrado = await UsuarioRepository.registrarMaestra(
        usuario,
        contrasena,
        palabraRecuperacion,
      );
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
      if (registrado) {
        await _iniciarSesion();
      } else {
        setState(() {
          _errorMensaje = 'No se pudo registrar la cuenta. Intenta nuevamente.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMensaje = 'No se pudo guardar la cuenta. Intenta nuevamente.';
      });
    }
  }

  Future<void> _recuperarCuenta() async {
    _playSound();
    final usuarioController = TextEditingController(
      text: _usuarioController.text.trim(),
    );
    final palabraController = TextEditingController();
    final nuevaContrasenaController = TextEditingController();
    String? errorMensaje;
    bool cargando = false;

    final recuperada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recuperar cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  controller: palabraController,
                  decoration: const InputDecoration(
                    labelText: 'Palabra de recuperación',
                    prefixIcon: Icon(Icons.key),
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
                TextField(
                  controller: nuevaContrasenaController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  obscureText: true,
                ),
                if (errorMensaje != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMensaje!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: cargando
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: cargando
                  ? null
                  : () async {
                      final usuario = usuarioController.text.trim();
                      final palabra = palabraController.text.trim();
                      final nuevaContrasena = nuevaContrasenaController.text
                          .trim();
                      if (usuario.isEmpty ||
                          palabra.isEmpty ||
                          nuevaContrasena.length < 6) {
                        setDialogState(() {
                          errorMensaje =
                              'Completa los datos y usa una contraseña de al menos 6 caracteres.';
                        });
                        return;
                      }

                      setDialogState(() {
                        cargando = true;
                        errorMensaje = null;
                      });
                      try {
                        final exito =
                            await UsuarioRepository.recuperarContrasena(
                              usuario,
                              palabra,
                              nuevaContrasena,
                            );
                        if (!context.mounted) return;
                        if (exito) {
                          Navigator.of(dialogContext).pop(true);
                        } else {
                          setDialogState(() {
                            cargando = false;
                            errorMensaje =
                                'El usuario o la palabra de recuperación no coinciden.';
                          });
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        setDialogState(() {
                          cargando = false;
                          errorMensaje =
                              'No se pudo guardar la nueva contraseña. Intenta nuevamente.';
                        });
                      }
                    },
              child: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Restablecer'),
            ),
          ],
        ),
      ),
    );
    final usuarioRecuperado = usuarioController.text.trim();
    usuarioController.dispose();
    palabraController.dispose();
    nuevaContrasenaController.dispose();

    if (!mounted || recuperada != true) return;
    _usuarioController.text = usuarioRecuperado;
    _contrasenaController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo/Icono
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Color(0xFF0288D1),
                ),
              ),

              const SizedBox(height: 24),

              // Título
              const Text(
                'Aprender es Divertido',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0288D1),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _registrando
                    ? 'Crea una cuenta para maestras'
                    : 'Inicia sesión para continuar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Campo de usuario
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  hintText: 'Ingresa tu usuario',
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF0288D1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0288D1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  errorText:
                      _errorMensaje != null && _usuarioController.text.isEmpty
                      ? _errorMensaje
                      : null,
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),

              const SizedBox(height: 16),

              // Campo de contraseña
              TextField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF0288D1)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarContrasena
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF0288D1),
                    ),
                    onPressed: _toggleMostrarContrasena,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0288D1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  errorText:
                      _errorMensaje != null &&
                          _contrasenaController.text.isEmpty
                      ? _errorMensaje
                      : null,
                ),
                keyboardType: TextInputType.text,
                obscureText: !_mostrarContrasena,
                onSubmitted: (_) =>
                    _registrando ? _registrarMaestra() : _iniciarSesion(),
              ),

              if (_registrando) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _palabraRecuperacionController,
                  decoration: InputDecoration(
                    labelText: 'Palabra de recuperación',
                    hintText: 'Una palabra que recuerdes',
                    helperText:
                        'La necesitarás junto con tu usuario para cambiar la contraseña.',
                    prefixIcon: const Icon(Icons.key, color: Color(0xFF0288D1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0288D1),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textCapitalization: TextCapitalization.none,
                  onSubmitted: (_) => _registrarMaestra(),
                ),
              ],

              // Mensaje de error
              if (_errorMensaje != null &&
                  _errorMensaje!.isNotEmpty &&
                  _usuarioController.text.isNotEmpty &&
                  _contrasenaController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _errorMensaje!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón de iniciar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando
                      ? null
                      : (_registrando ? _registrarMaestra : _iniciarSesion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _registrando ? 'REGISTRAR CUENTA' : 'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              if (!_registrando)
                TextButton(
                  onPressed: _cargando ? null : _recuperarCuenta,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),

              TextButton(
                onPressed: _cargando
                    ? null
                    : () {
                        setState(() {
                          _registrando = !_registrando;
                          _errorMensaje = null;
                        });
                      },
                child: Text(
                  _registrando
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : 'Registrar cuenta de maestra',
                ),
              ),
              if (_registrando)
                const Text(
                  'La cuenta quedará guardada en este dispositivo hasta que se elimine.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 40),

              // Botón de sonido
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    _sonidoActivado ? Icons.volume_up : Icons.volume_off,
                    color: const Color(0xFF0288D1),
                  ),
                  onPressed: _toggleSonido,
                  tooltip: _sonidoActivado
                      ? 'Desactivar sonido'
                      : 'Activar sonido',
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreditosScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7A8588),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Créditos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
